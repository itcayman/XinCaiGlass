import { buffer } from "@kit.ArkTS";

export class HexUtil {
  static readonly TAG: string = 'HexUtil';

  static numberToHex(num: number): string {
    return num.toString(16).toUpperCase().padStart(2, '0');
  }

  //十六进制转Uint8Array
  static HexStrToUint8Array(data: string): Uint8Array {
    return new Uint8Array(buffer.from(data, 'hex').buffer);
  }

  // Uint8Array转十六进制
  static uint8ArrayToHexStr(data: Uint8Array): string {
    let hexString = '';
    let i: number;
    for (i = 0; i < data.length; i++) {
      let char = ('00' + data[i].toString(16)).slice(-2);
      hexString += char;
    }
    return hexString;
  }
}
