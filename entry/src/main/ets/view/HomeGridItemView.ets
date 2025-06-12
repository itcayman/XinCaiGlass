import { ResourceUtil } from "../utils/ResourceUtil"

@Component
export struct HomeGridItemView {
  @State iconRes: Resource = $r('sys.media.ohos_ic_back')
  @State text: ResourceStr = ''
  @State des: ResourceStr = ''

  build() {
    RelativeContainer() {
      Image(this.iconRes)
        .id('image')
        .width(ResourceUtil.getCommonImgSize()[4])
        .height(ResourceUtil.getCommonImgSize()[4])
        .fillColor(Color.Red)
        .alignRules({ left: { anchor: '__container__', align: HorizontalAlign.Start } })

      Image($r('app.media.ic_arrow_right'))
        .width(ResourceUtil.getCommonImgSize()[1])
        .height(ResourceUtil.getCommonImgSize()[1])
        .margin({top: '8vp'})
        .alignRules({ right: { anchor: '__container__', align: HorizontalAlign.End } })

      Text(this.text)
        .id('text')
        .fontSize(ResourceUtil.getCommonTextSize()[2])
        .margin({top: ResourceUtil.getCommonPadding()[2]})
        .alignRules({ top: { anchor: 'image', align: VerticalAlign.Bottom } })

      Text(this.des)
        .fontColor(ResourceUtil.getCommonTextColor()[1])
        .fontSize(ResourceUtil.getCommonTextSize()[1])
        .margin({top: ResourceUtil.getCommonPadding()[2]})
        .alignRules({ top: { anchor: 'text', align: VerticalAlign.Bottom } })
    }
    .aspectRatio(1.21)
    .padding(ResourceUtil.getCommonPadding()[2])
    .borderRadius(10)
    .backgroundColor(ResourceUtil.getCommonBackgroundColor()[1])
  }
}