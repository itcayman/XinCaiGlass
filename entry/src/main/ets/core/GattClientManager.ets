import { ble } from '@kit.ConnectivityKit';
import { constant } from '@kit.ConnectivityKit';
import { BusinessError, emitter } from '@kit.BasicServicesKit';
import {
  BLE_DEVICE_CONNECTED,
  BLE_DEVICE_CONNECTING,
  BLE_DEVICE_DISCONNECTED,
  BLE_DEVICE_DISCONNECTING,
  BLE_DEVICE_UNDEFINED
} from '../constants/EventIds';
import { TransferBLEData } from '../viewmodel/TransferBLEData';
import { buffer } from '@kit.ArkTS';
import ProtocolPacket from './ProtocolPacket';
import { BluetoothConstants } from '../constants/BluetoothConstants';
import { Logger } from '../utils/Logger';
import { PCMManager } from './PCMManager';
import { DynamicArrayBuffer } from '../viewmodel/DynamicArrayBuffer';
import systemDateTime from '@ohos.systemDateTime';
import { HexUtil } from '../utils/HexUtil';
import { BleScanItem } from '../viewmodel/BleScanItem';


const TAG: string = '[GattClientManager]';
const MTU_SIZE: number = 517;
const MAX_RETRY = 5;

export class Notify {
  desc: string = '';
  characteristic: ble.BLECharacteristic | undefined;
  descriptor: ble.BLEDescriptor | undefined;

  constructor(desc: string, characteristic: ble.BLECharacteristic | undefined,
    descriptor: ble.BLEDescriptor | undefined) {
    this.desc = desc;
    this.characteristic = characteristic;
    this.descriptor = descriptor;
  }
}


export class GattClientManager {
  private device: BleScanItem | undefined = undefined;
  private gattClient: ble.GattClientDevice | undefined = undefined;
  private normalService: ble.GattService | undefined;
  private audioService: ble.GattService | undefined;
  private normalSendCharacteristic: ble.BLECharacteristic | undefined;
  private normalReceiverCharacteristic: ble.BLECharacteristic | undefined;
  private audioReceiverCharacteristic: ble.BLECharacteristic | undefined;
  private normalReceiverDescriptor: ble.BLEDescriptor | undefined;
  private audioReceiverDescriptor: ble.BLEDescriptor | undefined;
  private waitWriteNotifyArray: Array<Notify> = new Array();
  private connectState: ble.ProfileConnectionState = constant.ProfileConnectionState.STATE_DISCONNECTED;
  private found: boolean = false;
  private isWritingCharacteristicData = false; //正在写入数据
  private waitingSendQueue: Array<Uint8Array> = new Array();
  private receiverDataCallback: Callback<TransferBLEData> | undefined;
  private audioDataCallback: Array<Callback<ArrayBuffer>> = new Array();
  private retryConnectCount = 0;

  public setNormalCallback(callback: Callback<TransferBLEData> | undefined) {
    this.receiverDataCallback = callback;
  }

  public addAudioCallback(callback: Callback<ArrayBuffer>) {
    this.audioDataCallback.push(callback);
  }

  public removeAudioCallback(callback: Callback<ArrayBuffer>) {
    const index = this.audioDataCallback.indexOf(callback);
    if (index >= 0) {
      this.audioDataCallback.splice(index, 1);
    }
  }

  // 1. client端主动连接时调用
  public startConnect(peerDevice: BleScanItem) { // 对端设备一般通过ble scan获取到
    if (this.connectState == constant.ProfileConnectionState.STATE_CONNECTED && this.device?.deviceId != peerDevice.deviceId) {
      // this.stopConnect();
      // this.startConnect(peerDevice);
    }
    if (this.connectState != constant.ProfileConnectionState.STATE_DISCONNECTED) {
      Logger.error(TAG, `不能发起连接，当前连接状态: ${this.connectState}`);
      return;
    }
    Logger.info(TAG, `尝试连接设备【${peerDevice}】`);
    this.device = peerDevice;
    // 1.1 使用device构造gattClient，后续的交互都需要使用该实例
    this.gattClient = ble.createGattClientDevice(peerDevice.deviceId);
    this.onGattClientStateChange(); // 1.2 订阅连接状态
    try {
      this.gattClient.connect(); // 1.3 发起连接
    } catch (err) {
      this.printErr('建立连接报错', err as BusinessError);
    }
  }

  public getConnectedDeviceId(): string | undefined {
    if (this.connectState == constant.ProfileConnectionState.STATE_CONNECTED) {
      return this.device!.deviceId;
    }
    return undefined;
  }

  public stopConnect() {
    if (!this.gattClient || this.connectState != constant.ProfileConnectionState.STATE_CONNECTED) {
      Logger.warn(TAG, 'no gattClient or not connected');
      return;
    }
    Logger.info(TAG, `与【${this.device}】 断开连接...`);
    try {
      this.gattClient.disconnect();
      this.gattClient.off('BLEConnectionStateChange');
      this.gattClient.close() // 8.2 如果不再使用此gattClient，则需要close
    } catch (err) {
      this.printErr('断开连接失败', err as BusinessError);
    }
  }

  public sendNormalData(data: TransferBLEData) {
    let dataPacket = ProtocolPacket.createPacket(data);
    dataPacket.forEach((item) => {
      this.waitingSendQueue.push(item);
      Logger.warn(TAG, 'push包:' + item.byteLength);
    })
    if (this.isWritingCharacteristicData) {
      Logger.warn(TAG, '当前正在发送数据!!!');
      return;
    }
    Logger.debug(TAG, '发送送消息,当前队列长度:' + this.waitingSendQueue.length);
    this._writeCharacteristicValue(this.waitingSendQueue[0]);
  }

  private _writeCharacteristicValue(data: Uint8Array) {
    if (!this.gattClient || this.connectState != constant.ProfileConnectionState.STATE_CONNECTED) {
      Logger.error(TAG, 'gattClient未连接');
      return;
    }
    if (!this.found) {
      Logger.error(TAG, '相关服务、特征值、描述符校验失败!!!');
      return;
    }
    // Logger.warn(TAG, '写入数据:'+HexUtil.uint8ArrayToHexStr(data));
    try {
      this.isWritingCharacteristicData = true;
      this.normalSendCharacteristic!.characteristicValue = buffer.from(data).buffer
      this.gattClient.writeCharacteristicValue(this.normalSendCharacteristic!, ble.GattWriteType.WRITE, (err) => {
        if (err) {
          this.printErr('写入数据失败1', err as BusinessError);
          this.isWritingCharacteristicData = false;
          this.waitingSendQueue.splice(this.waitingSendQueue.indexOf(data), 1);
          Logger.error(TAG, `写入失败数据长度: ${data.byteLength}`);
          return;
        }
        const index = this.waitingSendQueue.indexOf(data);
        this.waitingSendQueue.splice(index, 1);
        Logger.debug(TAG, '写入数据成功, 当前队列长度:' + this.waitingSendQueue.length);
        let next = this.waitingSendQueue.splice(0, 1);
        if (next && next.length == 1) {
          Logger.debug(TAG, '发送下一个数据包');
          this._writeCharacteristicValue(next[0]);
        } else {
          this.isWritingCharacteristicData = false;
        }
      });
    } catch (err) {
      this.isWritingCharacteristicData = false;
      this.printErr('写入通知描述符失败2', err as BusinessError);
      this.waitingSendQueue.splice(this.waitingSendQueue.indexOf(data), 1);
      Logger.error(TAG, `写入失败数据长度: ${data.byteLength}`);
    }
  }

  private retryConnect() {
    if (this.retryConnectCount < MAX_RETRY) {
      Logger.info(TAG, `已经重连 ${this.retryConnectCount} 次，继续尝试重连...`);
      this.startConnect(this.device!);
      this.retryConnectCount++;
    }
  }

  private checkService(services: Array<ble.GattService>) {
    Logger.info(TAG, '校验所有服务...');
    services.forEach((service) => {
      // Logger.info(TAG, `serviceUUID: ${service.serviceUuid}`);
      switch (service.serviceUuid) {
        case BluetoothConstants.NORMAL_SERVICE_UUID:
          this.normalService = service;
          break;
        case BluetoothConstants.AUDiO_SERVICE_UUID:
          this.audioService = service;
          break;
      }
    });
    if (this.normalService == undefined) {
      Logger.error(TAG, '未找到通用服务!!!');
      return;
    }
    if (this.audioService == undefined) {
      Logger.error(TAG, '未找到音频服务!!!');
      return;
    }
    this.found = true;
  }

  private checkCharacteristics() {
    if (!this.found) {
      return;
    }
    Logger.info(TAG, '校验所有服务的特征值...');
    for (let i = 0; i < this.normalService!.characteristics.length; i++) {
      let characteristic = this.normalService!.characteristics[i];
      switch (characteristic.characteristicUuid) {
        case BluetoothConstants.NORMAL_SEND_UUID:
          this.normalSendCharacteristic = characteristic;
          this.printCharacteristicInfo('通用服务写入数据特征值', characteristic);
          break;
        case BluetoothConstants.NORMAL_RECEIVE_UUID:
          this.normalReceiverCharacteristic = characteristic;
          this.printCharacteristicInfo('通用服务接收数据特征值', characteristic);
          break;
      }
    }
    for (let i = 0; i < this.audioService!.characteristics.length; i++) {
      let characteristic: ble.BLECharacteristic = this.audioService!.characteristics[i];
      switch (characteristic.characteristicUuid) {
        case BluetoothConstants.AUDIO_RECEIVE_UUID:
          this.audioReceiverCharacteristic = characteristic;
          this.printCharacteristicInfo('音频服务接收数据特征值', characteristic);
          break;
      }
    }
    if (this.normalSendCharacteristic == undefined) {
      Logger.error(TAG, '未找到通用服务的发送数据特征值!!!');
      return;
    }
    if (this.normalReceiverCharacteristic == undefined) {
      Logger.error(TAG, '未找到通用服务的接收数据特征值!!!');
      return;
    }
    if (this.audioReceiverCharacteristic == undefined) {
      Logger.error(TAG, '未找到音频服务的接收数据特征值!!!');
      return;
    }
    this.found = true;
  }

  private printCharacteristicInfo(desc: string, characteristic: ble.BLECharacteristic) {
    let properties = characteristic.properties;
    Logger.info(TAG, `${desc}, write:${properties?.write}, read:${properties?.read}, notify:${properties?.notify}`);
  }

  private checkDescriptors() {
    if (!this.found) {
      return;
    }
    Logger.info(TAG, '校验所有服务特征值的描述符...');
    this.normalReceiverCharacteristic!.descriptors.forEach((descriptor) => {
      // Logger.info(TAG, `描述符: ${descriptor.descriptorUuid}`);
      if (descriptor.descriptorUuid == BluetoothConstants.NOTIFY_DESC_UUID) {
        this.normalReceiverDescriptor = descriptor;
        this.waitWriteNotifyArray.push(new Notify('通用服务接收特征值', this.normalReceiverCharacteristic!,
          descriptor));
      }
    })
    this.audioReceiverCharacteristic!.descriptors.forEach((descriptor) => {
      // Logger.info(TAG, `描述符: ${descriptor.descriptorUuid}`);
      if (descriptor.descriptorUuid == BluetoothConstants.NOTIFY_DESC_UUID) {
        this.audioReceiverDescriptor = descriptor;
        this.waitWriteNotifyArray.push(new Notify('音频服务接收特征值', this.audioReceiverCharacteristic!, descriptor));
      }
    })
    if (this.normalReceiverDescriptor == undefined) {
      Logger.error(TAG, '未找到通用服务>接收数据特征值的描述符!!!');
      return;
    }
    if (this.audioReceiverDescriptor == undefined) {
      Logger.error(TAG, '未找到音频服务>接收数据特征值的描述符!!!');
      return;
    }
    this.found = true;
  }

  private enableNotifyReceivers() {
    if (!this.found) {
      return;
    }
    // Logger.info(TAG, '启动所有服务的通知功能...');
    // this.gattClient?.setCharacteristicChangeNotification(this.normalReceiverCharacteristic!, true).then(() => {
    //   Logger.warn(TAG, '设置通用服务描述符...');
    //   this.enableNotificationDescriptor(this.normalReceiverDescriptor!)
    // })
    let notify = this.waitWriteNotifyArray.pop();
    if (notify == undefined) {
      return
    }
    this.gattClient?.setCharacteristicChangeNotification(notify.characteristic!, true).then(() => {
      this.enableNotificationDescriptor(notify!.desc, notify!.descriptor!)
    }).catch((error: BusinessError) => {
      Logger.error(TAG, '设置音频服务描述符发生错误:' + error.code + " " + error.message);
    });
  }

  // 2. 订阅连接状态变化事件
  private onGattClientStateChange() {
    if (!this.gattClient) {
      Logger.error(TAG, 'no gattClient');
      return;
    }
    try {
      this.gattClient.on('BLEConnectionStateChange', (stateInfo: ble.BLEConnectionChangeState) => {
        if (stateInfo.deviceId == this.device?.deviceId) {
          this.connectState = stateInfo.state;
        }
        let state = '';
        let eventData: emitter.EventData = { data: { device: this.device} }
        switch (stateInfo.state) {
          case 0:
            state = 'DISCONNECTED';
            emitter.emit({ eventId: BLE_DEVICE_DISCONNECTED, priority: emitter.EventPriority.HIGH }, eventData)
            this.retryConnect();
            break;
          case 1:
            state = 'CONNECTING';
            emitter.emit({ eventId: BLE_DEVICE_CONNECTING, priority: emitter.EventPriority.HIGH }, eventData)
            break;
          case 2:
            state = 'CONNECTED';
            this.onGattClientMtuChange();
            this.onCharacteristicChanged()
            Logger.info(TAG, '更新MTU size为:' + MTU_SIZE);
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
        Logger.info(TAG, '设备deviceId=' + stateInfo.deviceId + ', 连接状态=' + state);
      });
    } catch (err) {
      this.printErr('BLEConnectionStateChange报错', err as BusinessError);
    }
  }

  /**
   * 收到MTU更新的回调
   * */
  private onGattClientMtuChange() {
    if (!this.gattClient) {
      Logger.error(TAG, 'no gattClient');
      return;
    }
    this.gattClient?.on('BLEMtuChange', (state: number) => {
      Logger.info(TAG, '收到BLEMtuChange回调 state:' + state);
      // if (state == 0) {
      this.discoverServices()
      // }
    })
  }

  private onCharacteristicChanged() {
    if (!this.gattClient) {
      Logger.error(TAG, 'no gattClient');
      return;
    }
    this.gattClient?.on('BLECharacteristicChange', (characteristic: ble.BLECharacteristic) => {
      switch (characteristic.characteristicUuid) {
        case BluetoothConstants.NORMAL_SEND_UUID:
          Logger.info(TAG, '===============收到写入数据特征值响应');
          break;
        case BluetoothConstants.NORMAL_RECEIVE_UUID:
          let data: TransferBLEData = ProtocolPacket.decode(new Uint8Array(characteristic.characteristicValue));
          Logger.info(TAG, '===============收到通知特征值响应:' +
          ProtocolPacket.toHexString(new Uint8Array(characteristic.characteristicValue)));
          this.receiverDataCallback?.(data);
          break;
        case BluetoothConstants.AUDIO_RECEIVE_UUID:
          this.audioDataCallback.forEach((item) => {
            item(characteristic.characteristicValue);
          });
          break;
      }
    })
  }

  // 3. client端连接成功后，需要进行服务发现
  private discoverServices() {
    if (!this.gattClient) {
      Logger.info(TAG, 'no gattClient');
      return;
    }
    Logger.info(TAG, '开始扫描BLE服务...');
    try {
      this.gattClient.getServices().then((services: Array<ble.GattService>) => {
        // console.info(TAG, 'getServices success: ' + JSON.stringify(result));
        this.checkService(services);
        this.checkCharacteristics();
        this.checkDescriptors();
        Logger.info(TAG, '校验结果: ' + this.found);
        this.enableNotifyReceivers();
      });
    } catch (err) {
      this.printErr('获取服务报错', err as BusinessError);
    }
  }

  private enableNotificationDescriptor(desc: string, descriptor: ble.BLEDescriptor) {
    descriptor.descriptorValue = buffer.from([0x01, 0x00]).buffer;
    Logger.debug(TAG, `设置 ${desc} 描述符...`);
    try {
      this.gattClient!.writeDescriptorValue(descriptor, (err) => {
        if (err) {
          this.printErr(`写入 ${desc}} 描述符失败1`, err as BusinessError);
          return;
        }
        Logger.debug(TAG, `设置 ${desc} 描述符成功`);
        // this.initCharacteristicValue()
        this.enableNotifyReceivers();
      });
    } catch (err) {
      this.printErr(`写入 ${desc}} 通知描述符失败2`, err as BusinessError);
    }
  }

  private printErr(desc: string, err: BusinessError) {
    Logger.error(TAG, desc + JSON.stringify(err));
  }
}