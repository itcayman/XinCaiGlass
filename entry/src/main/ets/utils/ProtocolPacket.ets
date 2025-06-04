import buffer from '@ohos.buffer';
import { GlassPacket } from '../viewmodel/GlassPacket';

export const COMMAND_SWITCH_PAGE = 0x05; //打开界面

export const ENTER_HOME_VALUE: Uint8Array = new Uint8Array([0x01, 0x02, 0x00, 0x32, 0x00]) // 打开首页

export const ENTER_TELEPROMPTER_VALUE: Uint8Array = new Uint8Array([0x01, 0x02, 0x00, 0x33, 0x00]) // 打开提词

export const COMMAND_TELEPROMPT = 0x04; //手机端发送题词

// 协议常量定义
const PROTOCOL_HEADER = 0x01;
const FIXED_TLV_TYPE = 0x80;
const TELEPROMPTER_TEXT_HEADER = 0x01; //题词内容固定的text header

class ProtocolPacket {
  // 封装数据包
  static encode(data: GlassPacket): Uint8Array {
    // 计算TLV长度（2字节）
    let tlvLen = 0;

    // 处理字符串类型
    let tlvValue: Uint8Array;
    if (typeof data.tlvValue === 'string') {
      tlvValue = new Uint8Array(ProtocolPacket.assembleTextPacket(data.tlvValue).buffer);
      tlvLen = tlvValue.byteLength;
    } else {
      tlvValue = data?.tlvValue;
      tlvLen = data?.tlvValue.length;
    }

    const lenBuffer = buffer.alloc(2);
    lenBuffer.writeInt16LE(tlvLen, 0);
    console.log('[JVC]', 'tlLen:' + tlvLen)

    // 创建完整数据包
    const packet = buffer.concat([
      buffer.from([PROTOCOL_HEADER]),
      buffer.from([data.cmd]),
      buffer.from([FIXED_TLV_TYPE]),
      lenBuffer,
      buffer.from(tlvValue)
    ]);

    return new Uint8Array(packet.buffer);
  }

  /**********
   * 新协议结构：
   * [0] BLE头 0x01
   * [1] 指令 0x04
   * [2] TLV头 0x80
   * [3-4] TLV数据长度（小端）
   * [5+] 嵌套的文本TLV块：
   *      [0] 文本头 0x01
   *      [1-2] 文本长度（小端）
   *      [3+] 实际UTF-8文本数据
   **********/
  private static assembleTextPacket(text: string): buffer.Buffer {
    let tlvValue = new Uint8Array(buffer.from(text, 'utf-8').buffer);
    // 计算TLV长度（2字节）
    const tlvLen = tlvValue?.length;
    const lenBuffer = buffer.alloc(2);
    lenBuffer.writeInt16LE(tlvLen, 0);
    // 创建完整数据包
    const packet = buffer.concat([
      buffer.from([TELEPROMPTER_TEXT_HEADER]),
      lenBuffer,
      buffer.from(tlvValue)
    ]);
    return packet;
  }

  // 解析数据包
  static decode(data: Uint8Array): GlassPacket {
    // 最小长度检查 (header + cmd + tlv_type + tlv_len)
    if (data.length < 5) {
      return {
        valid: false,
        cmd: -1,
        tlvValue: new Uint8Array(),
        error: `数据包长度不足，至少需要5字节，实际收到${data.length}字节`
      };
    }

    // 检查Header
    if (data[0] !== PROTOCOL_HEADER) {
      return {
        valid: false,
        cmd: -1,
        tlvValue: new Uint8Array(),
        error: `Header无效，期望值0x${PROTOCOL_HEADER.toString(16).padStart(2, '0')}，实际值0x${data[0].toString(16)
          .padStart(2, '0')}`
      };
    }

    // 检查TLV类型
    if (data[2] !== FIXED_TLV_TYPE) {
      return {
        valid: false,
        cmd: -1,
        tlvValue: new Uint8Array(),
        error: `TLV类型无效，期望值0x${FIXED_TLV_TYPE.toString(16).padStart(2, '0')}，实际值0x${data[2].toString(16)
          .padStart(2, '0')}`
      };
    }

    // 读取TLV长度 (大端序)
    const lenBuffer = data.slice(3, 5);
    const tlvLen = (lenBuffer[0] << 8) | lenBuffer[1];

    // 检查数据包完整性
    if (data.length < 5 + tlvLen) {
      return {
        valid: false,
        cmd: -1,
        tlvValue: new Uint8Array(),
        error: `数据包不完整，期望长度${5 + tlvLen}字节，实际长度${data.length}字节`
      };
    }

    // 提取命令和值
    const cmd = data[1];
    const tlvValue = data.slice(5, 5 + tlvLen);

    return {
      valid: true,
      cmd: cmd,
      tlvValue: tlvValue
    };
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
}

export default ProtocolPacket;