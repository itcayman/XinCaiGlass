import { ble } from '@kit.ConnectivityKit';
import { constant } from '@kit.ConnectivityKit';
import { AsyncCallback, BusinessError, emitter } from '@kit.BasicServicesKit';
import {
  BLE_DEVICE_CONNECTED,
  BLE_DEVICE_CONNECTING,
  BLE_DEVICE_DISCONNECTED,
  BLE_DEVICE_DISCONNECTING,
  BLE_DEVICE_UNDEFINED
} from '../utils/EventIds';
import ProtocolPacket, { ENTER_TELEPROMPTER_VALUE, COMMAND_SWITCH_PAGE } from '../utils/ProtocolPacket';
import { GlassPacket } from '../viewmodel/GlassPacket';
import { buffer } from '@kit.ArkTS';


const TAG: string = '[JVC]GattClientManager';
const MTU_SIZE: number = 517;


export class GattClientManager {
  device: string | undefined = undefined;
  gattClient: ble.GattClientDevice | undefined = undefined;
  connectState: ble.ProfileConnectionState = constant.ProfileConnectionState.STATE_DISCONNECTED;
  serviceUuid: string = 'F48A23C0-F69A-11E8-8EB2-F2801F1B9FD1';
  writeCharacteristicUuid: string = 'F48A24C1-F69A-11E8-8EB2-F2801F1B9FD1'; //写入数据
  notifyCharacteristicUuid: string = 'F48A25C2-F69A-11E8-8EB2-F2801F1B9FD1'; //读取数据
  notifyDescriptorUuid: string = '00002902-0000-1000-8000-00805F9B34FB'; // 2902一般用于notification或者indication
  mySecondDescriptorUuid: string = '00002903-0000-1000-8000-00805F9B34FB';
  found: boolean = false;

  // 构造BLEDescriptor
  private initDescriptor(des: string, charUuid: string, value: ArrayBuffer): ble.BLEDescriptor {
    let descriptor: ble.BLEDescriptor = {
      serviceUuid: this.serviceUuid,
      characteristicUuid: charUuid,
      descriptorUuid: des,
      descriptorValue: value
    };
    return descriptor;
  }


  // 构造BLECharacteristic
  private initWriteCharacteristic(): ble.BLECharacteristic {
    let descriptors: Array<ble.BLEDescriptor> = [];
    let descBuffer = new ArrayBuffer(2);
    let charBuffer = new ArrayBuffer(2);
    let charValue = new Uint8Array(charBuffer);
    let characteristic: ble.BLECharacteristic = {
      serviceUuid: this.serviceUuid,
      characteristicUuid: this.writeCharacteristicUuid,
      characteristicValue: charBuffer,
      descriptors: descriptors
    };
    return characteristic;
  }

  // 构造BLECharacteristic
  private initNotifyCharacteristic(): ble.BLECharacteristic {
    let descriptors: Array<ble.BLEDescriptor> = [];
    let descBuffer = new ArrayBuffer(2);
    let descValue = new Uint8Array(descBuffer);
    descValue[0] = 0x01;
    descValue[1] = 0x00;
    descriptors[0] = this.initDescriptor(this.notifyDescriptorUuid, this.notifyCharacteristicUuid, descBuffer);
    let charBuffer = new ArrayBuffer(2);
    let charValue = new Uint8Array(charBuffer);
    // charValue[0] = 1;
    // charValue[1] = 2;
    let characteristic: ble.BLECharacteristic = {
      serviceUuid: this.serviceUuid,
      characteristicUuid: this.notifyCharacteristicUuid,
      characteristicValue: charBuffer,
      descriptors: descriptors
    };
    return characteristic;
  }


  private logCharacteristic(char: ble.BLECharacteristic) {
    let message = 'logCharacteristic uuid:' + char.characteristicUuid + '\n';
    let value = new Uint8Array(char.characteristicValue);
    message += 'logCharacteristic value: ';
    for (let i = 0; i < char.characteristicValue.byteLength; i++) {
      message += value[i] + ' ';
    }
    console.info(TAG, message);
  }


  private logDescriptor(des: ble.BLEDescriptor) {
    let message = 'logDescriptor uuid:' + des.descriptorUuid + '\n';
    let value = new Uint8Array(des.descriptorValue);
    message += 'logDescriptor value: ';
    for (let i = 0; i < des.descriptorValue.byteLength; i++) {
      message += value[i] + ' ';
    }
    console.info(TAG, message);
  }


  private checkService(services: Array<ble.GattService>): boolean {
    let service: ble.GattService | null = null
    for (let i = 0; i < services.length; i++) {
      let tempService = services[i]
      if (tempService.serviceUuid == this.serviceUuid) {
        service = tempService
        break;
      }
    }
    if (service == null) {
      return false;
    }
    //写入特征值
    let writeCharacteristic: ble.BLECharacteristic | null = null
    //通知特征值
    let notifyCharacteristic: ble.BLECharacteristic | null = null
    for (let i = 0; i < service.characteristics.length; i++) {
      let tempChar = service.characteristics[i];
      if (tempChar.characteristicUuid == this.writeCharacteristicUuid) {
        writeCharacteristic = tempChar;
        console.info(TAG, '找到写入数据特征值');
      }
      if (tempChar.characteristicUuid == this.notifyCharacteristicUuid) {
        notifyCharacteristic = tempChar;
        console.info(TAG, '找到通知特征值');
      }
    }

    if (writeCharacteristic == null || notifyCharacteristic == null) {
      return false;
    }
    console.info(TAG, '服务特征值都找到了');
    //写入描述符
    let descriptor: ble.BLEDescriptor | null = null
    for (let i = 0; i < notifyCharacteristic.descriptors.length; i++) {
      let tempDesc = notifyCharacteristic.descriptors[i];
      console.info(TAG, '描述符' + i + ':' + tempDesc.descriptorUuid);
      if (tempDesc.descriptorUuid == this.notifyDescriptorUuid) {
        descriptor = tempDesc;
        console.info(TAG, '找到通知的描述符, 申请启动通知...');
        //启动通知
        this.gattClient?.setCharacteristicChangeNotification(notifyCharacteristic, true).then(() => {
          if (descriptor == null) {
            return
          }
          this.writeNotifyDescriptorValue()
        })
        return true;
      }
    }
    if (descriptor == null) {
      return false;
    }
    return true;
  }


  // 1. 订阅连接状态变化事件
  public onGattClientStateChange() {
    if (!this.gattClient) {
      console.error(TAG, 'no gattClient');
      return;
    }
    try {
      this.gattClient.on('BLEConnectionStateChange', (stateInfo: ble.BLEConnectionChangeState) => {
        let state = '';
        let eventData: emitter.EventData = { data: { 'deviceId': stateInfo.deviceId } }
        switch (stateInfo.state) {
          case 0:
            state = 'DISCONNECTED';
            emitter.emit({ eventId: BLE_DEVICE_DISCONNECTED, priority: emitter.EventPriority.HIGH }, eventData)
            break;
          case 1:
            state = 'CONNECTING';
            emitter.emit({ eventId: BLE_DEVICE_CONNECTING, priority: emitter.EventPriority.HIGH }, eventData)
            break;
          case 2:
            state = 'CONNECTED';
            this.onGattClientMtuChange();
            this.onCharacteristicChanged()
            console.info(TAG, '更新MTU size为:' + MTU_SIZE);
            this.gattClient?.setBLEMtuSize(MTU_SIZE);
            emitter.emit({ eventId: BLE_DEVICE_CONNECTED, priority: emitter.EventPriority.HIGH }, eventData)
            break;
          case 3:
            state = 'DISCONNECTING';
            emitter.emit({ eventId: BLE_DEVICE_DISCONNECTING, priority: emitter.EventPriority.HIGH }, eventData)
            break;
          default:
            state = 'undefined';
            emitter.emit({ eventId: BLE_DEVICE_UNDEFINED, priority: emitter.EventPriority.HIGH }, eventData)

            break;
        }
        console.info(TAG, '设备deviceId=' + stateInfo.deviceId + ', 连接状态=' + state);
        if (stateInfo.deviceId == this.device) {
          this.connectState = stateInfo.state;
        }
      });
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  public onGattClientMtuChange() {
    if (!this.gattClient) {
      console.error(TAG, 'no gattClient');
      return;
    }
    this.gattClient?.on('BLEMtuChange', (state: number) => {
      console.info(TAG, '收到BLEMtuChange回调 state:' + state);
      // if (state == 0) {
      this.discoverServices()
      // }
    })
  }

  public onCharacteristicChanged() {
    if (!this.gattClient) {
      console.error(TAG, 'no gattClient');
      return;
    }
    this.gattClient?.on('BLECharacteristicChange', (characteristic: ble.BLECharacteristic) => {
      console.warn(TAG, '==========================特征值回调');
      if (characteristic.characteristicUuid == this.writeCharacteristicUuid) {
        console.info(TAG, '===============收到写入数据特征值响应');
      }
      if (characteristic.characteristicUuid == this.notifyCharacteristicUuid) {
        console.info(TAG, '===============收到通知特征值响应');
      }
    })
  }

  // 2. client端主动连接时调用
  public startConnect(peerDevice: string) { // 对端设备一般通过ble scan获取到
    if (this.connectState != constant.ProfileConnectionState.STATE_DISCONNECTED) {
      console.error(TAG, 'startConnect failed');
      return;
    }
    console.info(TAG, '尝试连接设备: ' + peerDevice);
    this.device = peerDevice;
    // 2.1 使用device构造gattClient，后续的交互都需要使用该实例
    this.gattClient = ble.createGattClientDevice(peerDevice);
    try {
      this.onGattClientStateChange(); // 2.2 订阅连接状态
      this.gattClient.connect(); // 2.3 发起连接
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }


  // 3. client端连接成功后，需要进行服务发现
  public discoverServices() {
    if (!this.gattClient) {
      console.info(TAG, 'no gattClient');
      return;
    }
    console.info(TAG, '开始扫描BLE服务...');
    try {
      this.gattClient.getServices().then((result: Array<ble.GattService>) => {
        // console.info(TAG, 'getServices success: ' + JSON.stringify(result));
        this.found = this.checkService(result); // 要确保server端的服务内容有业务所需要的服务
        console.info(TAG, '查询目标服务结果: ' + this.found);
        // this.initCharacteristicValue()
        // this.writeDescriptorValue();
      });
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }


  // 4. 在确保拿到了server端的服务结果后，读取server端特定服务的特征值时调用
  public initCharacteristicValue() {
    if (!this.gattClient || this.connectState != constant.ProfileConnectionState.STATE_CONNECTED) {
      console.error(TAG, 'no gattClient or not connected');
      return;
    }
    if (!this.found) { // 要确保server端有对应的characteristic
      console.error(TAG, 'no characteristic from server');
      return;
    }


    // let writeCharacteristic = this.initWriteCharacteristic();
    // console.info(TAG, '开始读取写入数据特征值信息');
    // try {
    //   this.gattClient.readCharacteristicValue(writeCharacteristic).then((outData: ble.BLECharacteristic) => {
    //     console.warn(TAG, '读取写入数据特征值信息 成功!!!');
    //     this.logCharacteristic(outData);
    //     this.writeCharacteristicValue();
    //   }).catch((err: Result)=>{
    //     console.error(TAG, '读取写入数据特征值报错======:'+err.code+", data:"+err.data);
    //   })
    // } catch (err) {
    //   console.error(TAG, '读取写入数据特征值报错 errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    // }

    let notifyCharacteristic = this.initNotifyCharacteristic();
    console.info(TAG, '开始读取通知数据特征值信息');
    try {
      this.gattClient.readCharacteristicValue(notifyCharacteristic).then((outData: ble.BLECharacteristic) => {
        this.logCharacteristic(outData);
      }).catch((err: Result) => {
        console.error(TAG, '读取通知数据特征值报错======:' + err.code + ", data:" + err.data);
      })
    } catch (err) {
      console.error(TAG, '读取通知特征值报错 errCode: ' + (err as BusinessError).code + ', errMessage: ' +
      (err as BusinessError).message);
    }
  }


  // 5. 在确保拿到了server端的服务结果后，写入server端特定服务的特征值时调用
  public writeCharacteristicValue(data: GlassPacket) {
    if (!this.gattClient || this.connectState != constant.ProfileConnectionState.STATE_CONNECTED) {
      console.error(TAG, 'no gattClient or not connected');
      return;
    }
    if (!this.found) { // 要确保server端有对应的characteristic
      console.error(TAG, 'no characteristic from server');
      return;
    }

    let writeCharacteristic = this.initWriteCharacteristic();

    let dataPacket: Uint8Array = ProtocolPacket.encode(data)
    writeCharacteristic.characteristicValue = buffer.from(dataPacket).buffer
    console.info(TAG, '开始写入数据:' + ProtocolPacket.toHexString(dataPacket));
    try {
      this.gattClient.writeCharacteristicValue(writeCharacteristic, ble.GattWriteType.WRITE, (err) => {
        if (err) {
          console.error(TAG,
            'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
          return;
        }
        console.info(TAG, '写入数据成功');
      });
    } catch (err) {
      console.error(TAG, '写入数据失败, errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }


  // 6. 在确保拿到了server端的服务结果后，读取server端特定服务的描述符时调用
  public readDescriptorValue() {
    if (!this.gattClient || this.connectState != constant.ProfileConnectionState.STATE_CONNECTED) {
      console.error(TAG, 'no gattClient or not connected');
      return;
    }
    if (!this.found) { // 要确保server端有对应的descriptor
      console.error(TAG, 'no descriptor from server');
      return;
    }


    let descBuffer = new ArrayBuffer(0);
    let descriptor = this.initDescriptor(this.notifyDescriptorUuid, this.notifyCharacteristicUuid, descBuffer);
    console.info(TAG, 'readDescriptorValue');
    try {
      this.gattClient.readDescriptorValue(descriptor).then((outData: ble.BLEDescriptor) => {
        this.logDescriptor(outData);
      });
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }


  // 7. 在确保拿到了server端的服务结果后，写入server端特定服务的描述符时调用
  public writeNotifyDescriptorValue() {
    if (!this.gattClient || this.connectState != constant.ProfileConnectionState.STATE_CONNECTED) {
      console.error(TAG, 'no gattClient or not connected');
      return;
    }
    if (!this.found) { // 要确保server端有对应的descriptor
      console.error(TAG, 'no descriptor from server');
      return;
    }

    let descriptor =
      this.initDescriptor(this.notifyDescriptorUuid, this.notifyCharacteristicUuid, buffer.from([0x01, 0x00]).buffer);
    console.info(TAG, '开始写入通知描述符...');
    try {
      this.gattClient.writeDescriptorValue(descriptor, (err) => {
        if (err) {
          console.error(TAG,
            '写入通知描述符失败1: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
          return;
        }
        console.info(TAG, 'writeDescriptorValue success');
        // this.initCharacteristicValue()
      });
    } catch (err) {
      console.error(TAG,
        '写入通知描述符失败2: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }


  // 8.client端主动断开时调用
  public stopConnect() {
    if (!this.gattClient || this.connectState != constant.ProfileConnectionState.STATE_CONNECTED) {
      console.error(TAG, 'no gattClient or not connected');
      return;
    }


    console.info(TAG, 'stopConnect ' + this.device);
    try {
      this.gattClient.disconnect(); // 8.1 断开连接
      this.gattClient.off('BLEConnectionStateChange', (stateInfo: ble.BLEConnectionChangeState) => {
      });
      this.gattClient.close() // 8.2 如果不再使用此gattClient，则需要close
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }
}


let gattClientManager = new GattClientManager();

export default gattClientManager as GattClientManager;