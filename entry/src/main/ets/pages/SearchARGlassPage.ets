import { ble } from '@kit.ConnectivityKit';
import bleScanManager from '../core/BleScanManager';
import { PermissionUtil } from '../utils/PermissionUtil';
import { BusinessError, emitter } from '@kit.BasicServicesKit';
import { BLE_DEVICE_CONNECTED, BLE_DEVICE_CONNECTING, BLE_SCAN_ID } from '../constants/EventIds';
import { CustomNavigationBar } from '../view/CustomNavigationBar';
import { BleScanItem } from '../viewmodel/BleScanItem';
import process from '@ohos.process';
import { Logger } from '../utils/Logger';
import cmgClient from '../core/CMGClient';

const TAG = '[ScanBLE]'

@Entry
@Component
struct SearchARGlassPage {
  @State title: string = 'Search AR Glass';
  @State searchResult: Array<BleScanItem> = new Array

  private onScanResult = (eventData: emitter.EventData) => {
    let data = eventData.data?.BleScanItem as BleScanItem;
    if (data.deviceName.indexOf('AR_NANCHANG') >= 0 || data.deviceName.indexOf('CMG') >= 0) {
      if (cmgClient.gattClientM().getConnectedDeviceId() == data.deviceId) {
        Logger.info(TAG, `设备【${data.deviceId} 已连接】`);
        data.connected = true;
      }
      this.searchResult.push(data)
    }
  }

  private onConnecting = (eventData: emitter.EventData) => {
    let device: BleScanItem = eventData?.data?.device;
    Logger.warn(TAG, '正在连接设备:' + device.deviceId);
    this.searchResult = this.searchResult.map(item => {
      if (item != undefined && item.deviceId == device.deviceId) {
        return new BleScanItem(item.deviceId, item.rssi, item.deviceName, item.connectable, false, true)
      }
      return item;
    })
  }

  private onConnected = (eventData: emitter.EventData) => {
    let device: BleScanItem = eventData?.data?.device;
    Logger.error(TAG, '连接到设备:' + device.deviceId);
    this.searchResult = this.searchResult.map(item => {
      if (item != undefined && item.deviceId == device.deviceId) {
        return new BleScanItem(item.deviceId, item.rssi, item.deviceName, item.connectable, true, false)
      }
      return item;
    })
  }

  aboutToAppear(): void {
    this.onScanDevice()
    this.onBLEDeviceConnecting()
    this.onBLEDeviceConnected()
  }

  aboutToDisappear(): void {
    emitter.off(BLE_SCAN_ID, this.onScanResult)
    emitter.off(BLE_DEVICE_CONNECTING, this.onConnecting)
    emitter.off(BLE_DEVICE_CONNECTED, this.onConnected)
    bleScanManager.stopScan()
  }

  private handleSearchClick() {
    PermissionUtil.init(getContext(this))
      .addPermissions('ohos.permission.ACCESS_BLUETOOTH')
      .request()
      .then((result) => {
        bleScanManager.stopScan()
        bleScanManager.startScan()
        Logger.info(TAG, '开始扫描BLE设备...')
      })
      .catch((error: BusinessError) => {
        Logger.error(TAG, '扫描BLE发生错误: ' + JSON.stringify(error))
      })
  }

  private onScanDevice() {
    emitter.on({ eventId: BLE_SCAN_ID }, this.onScanResult)
  }

  private onBLEDeviceConnecting() {
    emitter.on({ eventId: BLE_DEVICE_CONNECTING }, this.onConnecting)
  }

  private onBLEDeviceConnected() {
    emitter.on({ eventId: BLE_DEVICE_CONNECTED }, this.onConnected)
  }

  @Builder
  private connectedItem(item: BleScanItem) {
    Column() {
      Text(item.deviceName + ' (已连接)')
        .fontColor('#FFEF0F0F')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .onClick(() => {
          cmgClient.gattClientM().startConnect(item)
        })
      Text(item.deviceId + ' ' + item.rssi)
        .margin({ left: 20 })
        .fontColor('#cccccc')
    }
  }

  @Builder
  private connectingItem(item: BleScanItem) {
    Column() {
      Text(item.deviceName + ' (连接中)')
        .fontColor('#fff5a70c')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .onClick(() => {
          cmgClient.gattClientM().startConnect(item)
        })
      Text(item.deviceId + ' ' + item.rssi)
        .margin({ left: 20 })
        .fontColor('#cccccc')
    }
  }

  @Builder
  private normalItem(item: BleScanItem) {
    Column() {
      Text(item.deviceName)
        .fontColor($r('app.color.teleprompt_item_title'))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .onClick(() => {
          cmgClient.gattClientM().startConnect(item)
        })
      Text(item.deviceId + ' ' + item.rssi)
        .margin({ left: 20 })
        .fontColor('#cccccc')
    }
  }

  build() {
    RelativeContainer() {
      // 使用自定义导航栏组件
      CustomNavigationBar({
        parTitle: this.title, parBGColor: Color.White, onHeightChange: (height) => {
        }
      }).id('navigationBar').alignRules({
        top: { anchor: '__container__', align: VerticalAlign.Top }
      })

      Button('Search')
        .id('searchButton')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 })
        .align(Alignment.Center)
        .alignRules({
          top: { anchor: 'navigationBar', align: VerticalAlign.Bottom },
          middle: { anchor: "__container__", align: HorizontalAlign.Center }
        })
        .onClick(this.handleSearchClick)

      List({ space: 20, initialIndex: 0 }) {
        ForEach(this.searchResult, (item: BleScanItem) => {
          ListItem() {
            if (item.connected) {
              this.connectedItem(item);
            } else if (item.connecting) {
              this.connectingItem(item);
            } else {
              this.normalItem(item);
            }
          }
        })
      }.alignRules({
        top: { anchor: 'searchButton', align: VerticalAlign.Bottom },
        bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
      }).height(LayoutPolicy.matchParent).margin({ left: 20, top: 5, right: 20 })
    }
    .height('100%')
    .width('100%')
  }
}