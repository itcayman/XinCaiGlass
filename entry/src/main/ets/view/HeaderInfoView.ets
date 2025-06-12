import { ResourceUtil } from "../utils/ResourceUtil"

@Component
export struct HeaderInfoView {
  @State time: string = '00:00'
  @State date: string = '6月3日 星期一'

  build() {
    RelativeContainer() {
      //日期、时间
      Column() {
        Text(this.time).fontSize('36fp')
        Text(this.date).fontSize('14fp')
      }
      .margin({ left: '30vp' })
      .alignRules({
        left: { anchor: '__container__', align: HorizontalAlign.Start },
        center: { anchor: '__container__', align: VerticalAlign.Center },
      })
      .alignSelf(ItemAlign.Center)

      Image($r('app.media.ic_controller'))
        .width(ResourceUtil.getCommonImgSize()[3])
        .height(ResourceUtil.getCommonImgSize()[3])
        .alignRules({
          right: { anchor: '__container__', align: HorizontalAlign.End },
          bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
        })
    }
    .height('180vp')
    .padding(ResourceUtil.getCommonPadding()[2])
    .borderRadius(10)
    .backgroundColor(ResourceUtil.getCommonBackgroundColor()[1])
  }
}