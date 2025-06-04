export class GlassPacket {
  public valid?: boolean;
  public cmd: number = -1;
  public tlvValue: Uint8Array | string = new Uint8Array;
  public error?: string;
}