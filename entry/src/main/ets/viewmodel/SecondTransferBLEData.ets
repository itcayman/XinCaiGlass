export class SecondTransferBLEData {
  public tlvType: number = 0x01;
  public tlvValue: Uint8Array;

  constructor(tlvType: number, tlvValue: Uint8Array) {
    this.tlvType = tlvType;
    this.tlvValue = tlvValue;
  }
}