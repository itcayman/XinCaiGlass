export class TransferBLEData {
  public cmd: number = -1;
  public tlvType: number = 0x01;
  public tlvValue: Uint8Array | string = new Uint8Array;
  public error?: string;
  public wrapperData: boolean = true;

  constructor(cmd: number, tlvValue: Uint8Array | string, error: string = '', wrapperData:boolean = true) {
    this.cmd = cmd;
    this.tlvValue = tlvValue;
    this.error = error;
    this.wrapperData = wrapperData
  }

}