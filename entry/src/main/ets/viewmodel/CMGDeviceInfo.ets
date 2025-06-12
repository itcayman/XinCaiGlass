export class CMGDeviceInfo {
  public deviceName: string = '' //设备名称
  public modelNumber: string = '' //
  public softwareVersion: string = '' //软件版本号
  public firmwareVersion: string = '' //固件版本号
  public serialNumber: string = '' //设备序列号
  public mac: string = '' // 设备mac地址
  public electricity: number = 0 //电量

  toString(): string {
    return `deviceName: ${this.deviceName}, modelNumber: ${this.modelNumber}, softwareversion:${this.softwareVersion}
    , firmwareVersion:${this.firmwareVersion}, serialNumber:${this.serialNumber}, mac:${this.mac}`;
  }
}