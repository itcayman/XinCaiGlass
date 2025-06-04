import ProtocolPacket, { ENTER_TELEPROMPTER_VALUE } from "./ProtocolPacket";

export class Test {
  static test(){
    // 示例1：封装字符串数据包
    let stringData = "Hello, HarmonyOS!";
    let packet = ProtocolPacket.encode({
      cmd: 0x20, tlvValue: ProtocolPacket.stringToBuffer(stringData),
      valid: false
    });
    console.log('@tc', "封包结果(字符串):", ProtocolPacket.toHexString(packet));

    // 示例2：封装二进制数据包
    const binaryData = new Uint8Array(ENTER_TELEPROMPTER_VALUE);
    const binaryPacket = ProtocolPacket.encode({cmd:0x50, tlvValue:binaryData, valid:false});
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
    if (result.valid) {
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
    if (!errorResult.valid) {
      console.error("错误处理:", errorResult.error);
    }
    //01 05 80 00 05 01 02 00 33 00 Harmony
    //01 05 80 05 00 01 02 00 33 00 Android
  }

}