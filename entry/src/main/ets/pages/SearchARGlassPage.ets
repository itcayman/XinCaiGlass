import { ble } from '@kit.ConnectivityKit';
import bleScanManager from '../core/BleScanManager';
import { PermissionUtil } from '../utils/PermissionUtil';
import { BusinessError, emitter } from '@kit.BasicServicesKit';
import { BLE_DEVICE_CONNECTED, BLE_SCAN_ID } from '../utils/EventIds';
import { CustomNavigationBar } from '../view/CustomNavigationBar';
import { BleScanItem } from '../viewmodel/BleScanItem';
import process from '@ohos.process';
import gattClientManager from '../core/GattClientManager';

@Entry
@Component
struct SearchARGlassPage {
  @State title: string = 'Search AR Glass';
  @State searchResult: Array<BleScanItem> = new Array

  aboutToDisappear(): void {
    bleScanManager.stopScan()
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
        .onClick(() => {
          PermissionUtil.init(getContext(this))
            .addPermissions('ohos.permission.ACCESS_BLUETOOTH')
            .request()
            .then((result) => {
              console.error(JSON.stringify(result))
              emitter.on({ eventId: BLE_SCAN_ID }, (eventData: emitter.EventData) => {
                this.searchResult.push(eventData?.data?.BleScanItem)
              })
              emitter.on({ eventId: BLE_DEVICE_CONNECTED }, (eventData: emitter.EventData) => {
                let deviceId: string = eventData?.data?.deviceId;
                console.error('[JVC]', '连接到设备:' + deviceId);
                // this.searchResult.push(eventData?.data?.BleScanItem)
                // gattClientManager.discoverServices()
                this.searchResult = this.searchResult.map(item => {
                  if (item != undefined && item.deviceId == deviceId) {
                    return new BleScanItem(item.deviceId, item.rssi, item.deviceName, item.connectable, true)
                  }
                  return item;
                })
              })
              bleScanManager.stopScan()
              bleScanManager.startScan()
            })
            .catch((error: BusinessError) => {
              console.error(JSON.stringify(error))
            })
        })

      List({ space: 20, initialIndex: 0 }) {
        ForEach(this.searchResult, (item: BleScanItem) => {
          ListItem() {
            if (item.connected) {
              Text(item.deviceName + ' (已连接)')
                .fontColor('#FFEF0F0F')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .onClick(() => {
                  gattClientManager.startConnect(item.deviceId)
                })
            } else {
              Text(item.deviceName)
                .fontColor($r('app.color.teleprompt_item_title'))
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .onClick(() => {
                  gattClientManager.startConnect(item.deviceId)
                })
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