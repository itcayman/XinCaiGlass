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
}
