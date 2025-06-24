export class TransferBLEData {
  public cmd: number = -1;
  public tlvType: number = 0x01;
  public tlvValue: Uint8Array | string = new Uint8Array;
  public error?: string;
  public wrapperData: boolean = true;
  public longText: boolean = false;

  constructor(cmd: number, tlvValue: Uint8Array | string, error: string = '', wrapperData: boolean = true,
    longText: boolean = false) {
    this.cmd = cmd;
    this.tlvValue = tlvValue;
    this.error = error;
    this.wrapperData = wrapperData;
    this.longText = longText;
  }
}