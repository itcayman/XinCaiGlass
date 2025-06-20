export class BleScanItem {
  public deviceId: string = '';
  public rssi: number = 0;
  public deviceName: string = '';
  public connectable: boolean = false;
  public connected: boolean = false;
  public connecting: boolean = false;

  constructor(deviceId: string, rssi: number, deviceName: string, connectable: boolean, connected: boolean,
    connecting: boolean) {
    this.deviceId = deviceId;
    this.rssi = rssi;
    this.deviceName = deviceName;
    this.connectable = connectable;
    this.connected = connected;
    this.connecting = connecting;
  }

  toString(): string {
    return 'deviceName:' + this.deviceName + ', deviceId:' + this.deviceId + ", rssi:" + this.rssi + ', connectable:' +
    this.connectable + ', connected:' + this.connected + ', connecting:' + this.connecting;
  }
}