// 导入页面路由模块
import { router } from '@kit.ArkUI';
import { BusinessError, emitter } from '@kit.BasicServicesKit';
import bleScanManager from '../core/BleScanManager';
import discoveryDeviceManager from '../core/DiscoveryDeviceManager';
import { PermissionUtil } from '../utils/PermissionUtil';
import ProtocolPacket from '../core/ProtocolPacket';
import { buffer } from '@kit.ArkTS';
import { ByteUtil } from '../utils/ByteUtil';
import { Test } from '../utils/Test';
import { BLE_DEVICE_CONNECTED, BLE_DEVICE_DISCONNECTED } from '../utils/EventIds';
import dateTimeManager from '../core/DateTimeManager';
import databaseManager, { DatabaseManager } from '../database/DatabaseManager';

@Entry
@Component
struct HomePage {
  @State message: string = 'First Page';
  @State button: String = 'Go Second';
  @State connectText: string = 'Disconnected';

  aboutToAppear(): void {
    PermissionUtil.init(getContext(this))
      .addPermissions('ohos.permission.ACCESS_BLUETOOTH')
      .request()
      .then((result) => {
        console.error(JSON.stringify(result))
        // bleScanManager.startScan()
        // discoveryDeviceManager.startDiscovery()
      })
      .catch((error: BusinessError) => {
        console.error(JSON.stringify(error))
      })

    emitter.on({ eventId: BLE_DEVICE_CONNECTED }, (eventData: emitter.EventData) => {
      this.connectText = 'Connected';
      dateTimeManager.start()
    });
    emitter.on({ eventId: BLE_DEVICE_DISCONNECTED }, (eventData: emitter.EventData) => {
      this.connectText = 'Connected';
      dateTimeManager.stop()
    });

    databaseManager.init();
  }

  build() {
    Scroll() {
      GridRow({ columns: 2, gutter: { x: 5, y: 5 }, direction: GridRowDirection.Row }) {
        GridCol() {
          Column() {
            Text(this.connectText).alignSelf(ItemAlign.Start)
            Image($r('app.media.ic_device_battery_glass')).width('80%').height(50).margin({ top: 50 })
          }.padding({ top: 15 }).alignItems(HorizontalAlign.Start)
        }
        .aspectRatio(1)
        .backgroundColor(Color.White)
        .borderRadius(5)
        .margin({ left: 10 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/SearchARGlassPage' })
        })

        GridCol() {
          Column() {
            Image($r('app.media.ic_public_download'))
              .width(30)
              .height(30)
            Text($r('app.string.teleprompt')).margin({ top: 80 }).alignSelf(ItemAlign.Start)
          }.padding({ left: 10, top: 15 }).alignItems(HorizontalAlign.Start)
        }
        .aspectRatio(1)
        .backgroundColor(Color.White)
        .borderRadius(5)
        .margin({ right: 10 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/TeleprompterHomePage' })
        })
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }
}
