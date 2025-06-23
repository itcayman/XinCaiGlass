import { ResourceUtil } from "../utils/ResourceUtil"

@Component
export struct GlassView {
  @State glassRes: Resource = $r('app.media.glass_un_wear')
  @State batteryRes: Resource = $r('app.media.ic_battery')

  aboutToAppear(): void {

  }

  aboutToDisappear(): void {
    // emitter.on({ eventId: BLE_DEVICE_CONNECTED }, (eventData: emitter.EventData) => {
    //   let deviceId: string = eventData?.data?.deviceId;
    //   Logger.error(TAG, '连接到设备:' + deviceId);
    //   this.searchResult = this.searchResult.map(item => {
    //     if (item != undefined && item.deviceId == deviceId) {
    //       return new BleScanItem(item.deviceId, item.rssi, item.deviceName, item.connectable, true, false)
    //     }
    //     return item;
    //   })
    // })
  }

  build() {
    Column() {
      Flex({ direction: FlexDirection.Row }) {
        Text('CMG Y1').width('30%')
        Text('Disconnected').width('40%').textAlign(TextAlign.Center)
        Row() {
          Text().layoutWeight(1)
          Image(this.batteryRes)
            .rotate({ angle: "90" })
            .width('25vp')
            .height('25vp')
          Text('80%').margin({left: '5vp'})
        }.width('30%')
      }

      Image(this.glassRes).width('100%').height('60vp')
    }
    .padding(ResourceUtil.getCommonPadding()[2])
    .borderRadius(10)
    .backgroundColor(ResourceUtil.getCommonBackgroundColor()[1])
  }
}