import { ResourceUtil } from "../utils/ResourceUtil"
import { emitter } from "@kit.BasicServicesKit";
import {
  BLE_DEVICE_CONNECTED,
  BLE_DEVICE_CONNECTING,
  BLE_DEVICE_DISCONNECTED as BLE_DEVICE_DISCONNECT
} from "../constants/EventIds";
import { Logger } from "../utils/Logger";

const TAG = '[GlassView]'

@Component
export struct GlassView {
  @State glassRes: Resource = $r('app.media.glass_un_wear')
  @State batteryRes: Resource = $r('app.media.ic_battery')
  @State connectStateRes: Resource = $r('app.string.state_disconnect')

  aboutToAppear(): void {
    Logger.info(TAG, 'aboutToAppear');
    emitter.on({ eventId: BLE_DEVICE_DISCONNECT }, () => {
      this.connectStateRes = $r('app.string.state_disconnect')
    })
    emitter.on({ eventId: BLE_DEVICE_CONNECTING }, () => {
      this.connectStateRes = $r('app.string.state_connecting')
    })
    emitter.on({ eventId: BLE_DEVICE_CONNECTED }, () => {
      this.connectStateRes = $r('app.string.state_connected')
    })
  }

  aboutToDisappear(): void {
    Logger.info(TAG, 'aboutToDisappear');
    emitter.off(BLE_DEVICE_DISCONNECT);
    emitter.off(BLE_DEVICE_CONNECTING);
    emitter.off(BLE_DEVICE_CONNECTED);
  }

  build() {
    Column() {
      Flex({ direction: FlexDirection.Row }) {
        Text('CMG Y1').width('30%')
        Text(this.connectStateRes).width('40%').textAlign(TextAlign.Center)
        Row() {
          Text().layoutWeight(1)
          Image(this.batteryRes)
            .rotate({ angle: "90" })
            .width('25vp')
            .height('25vp')
          Text('80%').margin({ left: '5vp' })
        }.width('30%')
      }

      Image(this.glassRes).width('100%').height('60vp')
    }
    .padding(ResourceUtil.getCommonPadding()[2])
    .borderRadius(10)
    .backgroundColor(ResourceUtil.getCommonBackgroundColor()[1])
  }
}