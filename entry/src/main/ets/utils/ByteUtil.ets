export class ByteUtil {
  static readonly TAG: string = 'ByteUtil';

  /**
   * 获取位
   * @param value
   * @param index
   * @returns
   */
  static getBit(value: number, index: number): number {
    return (value >> index) & 0x01;
  }

  /**
   * Byte[] 与 int 互转
   * =============================================================================================
   */

  /**
   * 将int转为高字节在前，低字节在后的byte数组（大端）
   *
   * @param n int
   * @return byte[]
   */
  static intToByteBig(n: number): Uint8Array {
    let b = new Uint8Array(4);
    b[3] = (n & 0xff);
    b[2] = (n >> 8 & 0xff);
    b[1] = (n >> 16 & 0xff);
    b[0] = (n >> 24 & 0xff);
    return b;
  }

  /**
   * 将int转为低字节在前，高字节在后的byte数组（小端）
   *
   * @param n int
   * @return byte[]
   */
  static intToByteLittle(n: number): Uint8Array {
    let b = new Uint8Array(4);
    b[0] = (n & 0xff);
    b[1] = (n >> 8 & 0xff);
    b[2] = (n >> 16 & 0xff);
    b[3] = (n >> 24 & 0xff);
    return b;
  }

  /**
   * byte数组到int的转换(小端)
   *
   * @param bytes
   * @return
   */
  static bytes2IntLittle(bytes: Uint8Array): number {
    let int1 = bytes[0] & 0xff;
    let int2 = (bytes[1] & 0xff) << 8;
    let int3 = (bytes[2] & 0xff) << 16;
    let int4 = (bytes[3] & 0xff) << 24;
    return int1 | int2 | int3 | int4;
  }

  /**
   * byte数组到int的转换(大端)
   *
   * @param bytes
   * @return
   */
  static bytes2IntBig(bytes: Uint8Array): number {
    let int1 = bytes[3] & 0xff;
    let int2 = (bytes[2] & 0xff) << 8;
    let int3 = (bytes[1] & 0xff) << 16;
    let int4 = (bytes[0] & 0xff) << 24;
    return int1 | int2 | int3 | int4;
  }

  /**
   * Byte[] 与 short 互转
   * =============================================================================================
   */

  /**
   * 将short转为高字节在前，低字节在后的byte数组（大端）
   *
   * @param n short
   * @return byte[]
   */
  static shortToByteBig(n: number): Uint8Array {
    let b = new Uint8Array(2);
    b[1] = (n & 0xff);
    b[0] = (n >> 8 & 0xff);
    return b;
  }

  /**
   * 将short转为低字节在前，高字节在后的byte数组(小端)
   *
   * @param n short
   * @return byte[]
   */
  static shortToByteLittle(n: number): Uint8Array {
    let b = new Uint8Array(2);
    b[0] = (n & 0xff);
    b[1] = (n >> 8 & 0xff);
    return b;
  }

  /**
   * 读取小端byte数组为short
   *
   * @param b
   * @return
   */
  static byteToShortLittle(b: Uint8Array): number {
    return (((b[1] << 8) | b[0] & 0xff));
  }

  /**
   * 读取大端byte数组为short
   *
   * @param b
   * @return
   */
  static byteToShortBig(b: Uint8Array): number {
    return (((b[0] << 8) | b[1] & 0xff));
  }

  /**
   * 将ArrayBuffer编码为Base64字符串，不使用换行符(NO_WRAP)
   * 完全仿照Java的Base64.encodeToString(chunk, Base64.NO_WRAP)
   * @param buffer - 要编码的ArrayBuffer
   * @returns 编码后的Base64字符串(不带换行符)
   */
  static base64EncodeToStringNoWrap(buffer: ArrayBuffer): string {
    if (buffer === null || buffer === undefined) {
      throw new TypeError("Cannot read property 'byteLength' of null");
    }

    // 处理空输入
    if (buffer.byteLength === 0) {
      return "";
    }

    const base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    const bytes = new Uint8Array(buffer);
    let result = "";
    let padding = 0;

    for (let i = 0; i < bytes.length; i += 3) {
      // 读取3个字节
      const byte1 = bytes[i];
      const byte2 = i + 1 < bytes.length ? bytes[i + 1] : 0;
      const byte3 = i + 2 < bytes.length ? bytes[i + 2] : 0;

      // 计算填充字节数
      if (i + 1 >= bytes.length) padding = 2;
      else if (i + 2 >= bytes.length) padding = 1;

      // 转换为4个Base64字符
      const b64_1 = (byte1 & 0xfc) >> 2;
      const b64_2 = ((byte1 & 0x03) << 4) | ((byte2 & 0xf0) >> 4);
      const b64_3 = ((byte2 & 0x0f) << 2) | ((byte3 & 0xc0) >> 6);
      const b64_4 = byte3 & 0x3f;

      // 添加到结果字符串
      result += base64Chars.charAt(b64_1);
      result += base64Chars.charAt(b64_2);

      // 处理填充
      result += padding > 1 ? '=' : base64Chars.charAt(b64_3);
      result += padding > 0 ? '=' : base64Chars.charAt(b64_4);
    }

    return result;
  }
}
