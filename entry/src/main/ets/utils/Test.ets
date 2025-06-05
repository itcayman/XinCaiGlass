import { buffer } from "@kit.ArkTS";
import ProtocolPacket from "../core/ProtocolPacket";
import { TransferBLEData as TransferBLEData } from "../viewmodel/TransferBLEData";

export class Test {
  static test(){
    // 示例1：封装字符串数据包
    let stringData = "Hello, HarmonyOS!";
    let data = new TransferBLEData(0x20, ProtocolPacket.stringToBuffer(stringData), '');
    let packet = ProtocolPacket.createPacket(data);
    console.log('@tc', "封包结果(字符串):", ProtocolPacket.toHexString(packet));

    // 示例2：封装二进制数据包
    const binaryData = new Uint8Array(buffer.from(stringData, 'utf8').buffer);
    const binaryBLEData = new TransferBLEData(0x50, binaryData, '')
    const binaryPacket = ProtocolPacket.createPacket(binaryBLEData);
    console.log('@tc', "封包结果(二进制):", ProtocolPacket.toHexString(binaryPacket));

    // 示例3：解析数据包
    const receivedPacket = new Uint8Array([
      0x01,       // Header
      0x20,       // CMD
      0x80,       // TLV Type
      0x00, 0x10, // Length (16)
      // 16字节数据 (Hello, HarmonyOS!的UTF-8编码)
      0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x2C, 0x20, 0x48,
      0x61, 0x72, 0x6D, 0x6F, 0x6E, 0x79, 0x4F, 0x53
    ]);

    const result = ProtocolPacket.decode(receivedPacket);
    if (result.error == undefined || result.error == null) {
      console.log('@tc', `解析成功: CMD=0x${result.cmd?.toString(16)}`);

      if(typeof result.tlvValue !== 'string') {
        // 将二进制数据转换为字符串
        const decodedString = ProtocolPacket.bufferToString(result.tlvValue);
        console.log('@tc',"TLV值:", decodedString);
      }
    } else {
      console.error('@tc', "解析失败:", result.error);
    }

    // 示例4：处理错误数据包
    const invalidPacket = new Uint8Array([0x02, 0x20, 0x80, 0x00, 0x05]);
    const errorResult = ProtocolPacket.decode(invalidPacket);
    if (errorResult.error != undefined && errorResult.error != null) {
      console.error("错误处理:", errorResult.error);
    }
    //01 05 80 00 05 01 02 00 33 00 Harmony
    //01 05 80 05 00 01 02 00 33 00 Android
  }


  // test1() {
  //   let test1: TeleprompterEntity = new TeleprompterEntity(10, "测试10", "测试内容10", systemDateTime.getTime());
  //   this.teleprompterTable?.insert(test1, (id: number) => {
  //     Logger.info(TAG, "insert success id = " + id)
  //   });
  // }
  //
  // test2() {
  //   this.teleprompterTable?.query(1, (result: Array<TeleprompterEntity>) => {
  //     Logger.info(TAG, "persons = " + JSON.stringify(result))
  //   }, false);
  // }
}