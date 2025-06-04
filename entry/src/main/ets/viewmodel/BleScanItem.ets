export class BleScanItem {
  public deviceId: string = '';
  public rssi: number = 0;
  public deviceName: string = '';
  public connectable: boolean = false;

  constructor(deviceId: string, rssi: number, deviceName: string, connectable: boolean) {
    this.deviceId = deviceId;
    this.rssi = rssi;
    this.deviceName = deviceName;
    this.connectable = connectable;
  }

  toString(): string {
    return 'deviceName:' + this.deviceName + ', deviceId:' + this.deviceId + ", rssi:" + this.rssi + ', connectable:' +
    this.connectable
  }
}