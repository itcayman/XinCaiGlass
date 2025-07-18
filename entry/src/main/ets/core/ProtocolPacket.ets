import buffer from '@ohos.buffer';
import { Logger } from '../utils/Logger';
import { SecondTransferBLEData as SecondBLEData } from '../viewmodel/SecondTransferBLEData';
import { TransferBLEData } from '../viewmodel/TransferBLEData';

const TAG = '[Packet]'
// 协议常量定义
const PROTOCOL_HEADER = 0x01;
const FIXED_TLV_TYPE = 0x80;
const SECOND_TLV_TYPE_COMMON = 0x01; //第二层通用tlv_type

/**********
 * 协议结构：
 * [0] header 0x01
 * [1] cmd 0x04
 * [2] tlv_type 0x80（暂时没用到）
 * [3-4] tlv_len（小端）
 * [5] tlv_value (数据包再包一层用于区分同一业务场景的不同功能)：
 *      [0] tlv_type 0x01（区分子功能）
 *      [1-2] tlv_len（小端）
 *      [3+] tlv_value
 **********/
class ProtocolPacket {
  public static createPacket(data: TransferBLEData) {
    if (typeof data.tlvValue === 'string') {
      if (data.longText) {
        return ProtocolPacket.createLongTextPacket(data.cmd, data.tlvValue);
      }
      return ProtocolPacket.createTextPacket(data.cmd, data.tlvValue);
    } else if (!data.wrapperData) {
      return ProtocolPacket.createNoWrapperPacket(data.cmd, FIXED_TLV_TYPE, data.tlvValue);
    } else {
      const tlvPacket = ProtocolPacket.createTLVPacket(data.tlvValue, data.tlvType);
      return ProtocolPacket.createWrapperPacket(data.cmd, tlvPacket);
    }
  }

  public static createLongTextPacket(cmd: number, text: string): Array<Uint8Array> {
    const chunks: Array<Uint8Array> = new Array();
    const textData = new Uint8Array(buffer.from(text, 'utf-8').buffer);
    Logger.debug(TAG, `文本字节长度: ${textData.byteLength}`);
    if (textData.byteLength <= 200) {
      const messageBytes = ProtocolPacket.concatUint8Arrays([new Uint8Array([0x5a, 0x6b]), textData]);
      let result = ProtocolPacket.createWrapperPacket(cmd, ProtocolPacket.createTLVPacket(messageBytes));
      result.forEach((item) => {
        chunks.push(item);
      })
      return chunks;
    }
    const maxChunkSize = 200;
    const leaderPacketHeader = new Uint8Array([0x5A, 0x5A]);
    const terminalPacketHeader = new Uint8Array([0x6B, 0x6B]);
    const segmentPacketHeader = new Uint8Array([0x7C, 0x7C]);
    let offset = 0;
    while (offset < textData.byteLength) {
      let end = Math.min(offset + maxChunkSize, textData.byteLength);
      chunks.push(textData.slice(offset, end));
      offset = end;
    }
    for(let i = 0;i< chunks.length;i++) {
      let payload: ArrayBuffer;
      let chunk = chunks[i];
      if (i == 0) {
        payload = ProtocolPacket.createTLVPacket(ProtocolPacket.concatUint8Arrays([leaderPacketHeader, chunk]));
      } else if (i == chunks.length - 1) {
        payload = ProtocolPacket.createTLVPacket(ProtocolPacket.concatUint8Arrays([terminalPacketHeader, chunk]));
      } else {
        payload = ProtocolPacket.createTLVPacket(ProtocolPacket.concatUint8Arrays([segmentPacketHeader, chunk]));
      }
      chunks[i] = ProtocolPacket.createWrapperPacket(cmd, payload)[0];
    }
    // chunks.map((chunk, index) => {
    //   let payload: ArrayBuffer;
    //   if (index == 0) {
    //     payload = ProtocolPacket.createTLVPacket(ProtocolPacket.concatUint8Arrays([leaderPacketHeader, chunk]));
    //   } else if (index == chunks.length - 1) {
    //     payload = ProtocolPacket.createTLVPacket(ProtocolPacket.concatUint8Arrays([terminalPacketHeader, chunk]));
    //   } else {
    //     payload = ProtocolPacket.createTLVPacket(ProtocolPacket.concatUint8Arrays([segmentPacketHeader, chunk]));
    //   }
    //   ProtocolPacket.createWrapperPacket(cmd, payload)[0];
    // });
    return chunks;
  }

  private static createNoWrapperPacket(cmd: number, tlvType: number = FIXED_TLV_TYPE,
    tlvValue: Uint8Array): Array<Uint8Array> {
    const tlvLen = buffer.alloc(2);
    tlvLen.writeInt16LE(tlvValue?.length, 0);
    // 创建第二层数据包
    const packet = buffer.concat([
      buffer.from([PROTOCOL_HEADER]),
      buffer.from([cmd]),
      buffer.from([tlvType]),
      tlvLen,
      buffer.from(tlvValue)
    ]);
    return [new Uint8Array(packet.buffer)];
  }

  private static createWrapperPacket(cmd: number, tlvValue: Uint8Array | ArrayBuffer): Array<Uint8Array> {
    const tlvLen = buffer.alloc(2);
    tlvLen.writeInt16LE(tlvValue.byteLength, 0);
    // 创建完整数据包
    const packet = buffer.concat([
      buffer.from([PROTOCOL_HEADER]),
      buffer.from([cmd]),
      buffer.from([FIXED_TLV_TYPE]),
      tlvLen,
      buffer.from(tlvValue)
    ]);
    return [new Uint8Array(packet.buffer)];
  }

  private static createTextPacket(cmd: number, text: string): Array<Uint8Array> {
    let tlvValue = new Uint8Array(buffer.from(text, 'utf-8').buffer);
    const tlvLen = buffer.alloc(2);
    tlvLen.writeInt16LE(tlvValue?.length, 0);
    // 创建第二层数据包
    const packet = buffer.concat([
      buffer.from([SECOND_TLV_TYPE_COMMON]),
      tlvLen,
      buffer.from(tlvValue)
    ]);
    return ProtocolPacket.createWrapperPacket(cmd, packet.buffer);
  }

  private static createTLVPacket(tlvValue: Uint8Array,
    tlvType: number = SECOND_TLV_TYPE_COMMON): ArrayBuffer {
    const tlvLen = buffer.alloc(2);
    tlvLen.writeInt16LE(tlvValue?.length, 0);
    // 创建第二层数据包
    const packet = buffer.concat([
      buffer.from([tlvType]),
      tlvLen,
      buffer.from(tlvValue)
    ]);
    return packet.buffer;
  }

  // 解析数据包
  static decode(data: Uint8Array): TransferBLEData {
    // 最小长度检查 (header + cmd + tlv_type + tlv_len)
    if (data.length < 5) {
      return new TransferBLEData(-1, '', `数据包长度不足，至少需要5字节，实际收到$\{data.length}字节`);
    }

    // 检查Header
    if (data[0] !== PROTOCOL_HEADER) {
      return new TransferBLEData(-1, '',
        `Header无效，期望值0x${PROTOCOL_HEADER.toString(16).padStart(2, '0')}，实际值0x${data[0].toString(16)
          .padStart(2, '0')}`);
    }

    // 检查TLV类型
    if (data[2] !== FIXED_TLV_TYPE) {
      return new TransferBLEData(-1, '',
        `TLV类型无效，期望值0x${FIXED_TLV_TYPE.toString(16).padStart(2, '0')}，实际值0x${data[2].toString(16)
          .padStart(2, '0')}`);
    }

    // 读取TLV长度 (大端序)
    const lenBuffer = buffer.alloc(2).fill(data.slice(3, 5));
    const tlvLen = lenBuffer.readInt16LE();

    // 检查数据包完整性
    if (data.length < 5 + tlvLen) {
      return new TransferBLEData(-1, '', `数据包不完整，期望长度${5 + tlvLen}字节，实际长度${data.length}字节`);
    }

    // 提取命令和值
    const cmd = data[1];
    const tlvValue = data.slice(5, 5 + tlvLen);
    let result = new TransferBLEData(cmd, tlvValue, '', false);
    return result;
  }

  static decodeTlvValue(data: Uint8Array): SecondBLEData {
    let tlvType = data[0];
    // 读取TLV长度 (大端序)
    const lenBuffer = buffer.alloc(2).fill(data.slice(1, 3));
    const tlvLen = lenBuffer.readInt16LE();
    const tlvValue = data.slice(3, 3 + tlvLen);
    return new SecondBLEData(tlvType, tlvValue);
  }

  // 辅助方法：将Uint8Array转换为字符串
  static bufferToString(data: Uint8Array): string {
    return buffer.from(data).toString('utf-8');
  }

  // 辅助方法：将字符串转换为Uint8Array
  static stringToBuffer(str: string): Uint8Array {
    return new Uint8Array(buffer.from(str, 'utf-8').buffer);
  }

  // 辅助方法：打印数据包十六进制
  static toHexString(data: Uint8Array): string {
    return Array.from(data)
      .map(byte => byte.toString(16).padStart(2, '0'))
      .join(' ');
  }

  private static concatUint8Arrays(arrays: Array<Uint8Array>): Uint8Array {
    // 计算总长度
    let totalLength = 0;
    for (let i = 0; i < arrays.length; i++) {
      totalLength += arrays[i].length;
    }
    // 创建结果数组
    const result = new Uint8Array(totalLength);
    let offset = 0;
    // 复制每个数组的内容
    for (let i = 0; i < arrays.length; i++) {
      const array = arrays[i];
      for (let j = 0; j < array.length; j++) {
        result[offset + j] = array[j];
      }
      offset += array.length;
    }
    return result;
  }
}

export default ProtocolPacket;