import { ResourceUtil } from "../utils/ResourceUtil"

@Component
export struct GlassView {
  @State glassRes: Resource = $r('app.media.glass_un_wear')
  @State batteryRes: Resource = $r('app.media.ic_battery')

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