import { TimeUtil } from "../utils/TimeUtil"
import { systemDateTime } from "@kit.BasicServicesKit"
import { font } from "@kit.ArkUI"

@Preview
@Component
export struct CreateTeleprompterView {
  @Link title: string
  @Link content: string

  aboutToAppear() {
    // familyName和familySrc都支持string
    font.registerFont({
      familyName: 'kaishu',
      familySrc: '/font/SanJiWenHaoKaiShu-2.ttf' // font文件与pages目录同级
    })
  }

  build() {
    Column() {
      TextArea({ placeholder: $r('app.string.teleprompt_new_untitle'), text: this.title })
        .lineHeight(20)
        .maxLength(80)
        .placeholderColor('#919191')
        .fontColor('#343434')
        .fontSize(16)
        .fontFamily('kaishu')
        .borderRadius(0)
        .padding(0)
        .backgroundColor(Color.Transparent)
        .onChange((value: string) => {
          this.title = value;
        })
      Text(TimeUtil.formatTimestamp(systemDateTime.getTime()))
        .fontColor('#969696')
        .fontSize(12)
        .height(20)
        .alignSelf(ItemAlign.Start)
      TextArea({ placeholder: $r('app.string.teleprompt_new_enter_text'), text: this.content })
        .layoutWeight(1)
        .placeholderColor('#919191')
        .fontColor('#343434')
        .fontSize(16)
        .fontFamily('kaishu')
        .borderRadius(0)
        .padding(0)
        .margin({ top: 20 })
        .backgroundColor(Color.Transparent)
        .onChange((value: string) => {
          this.content = value;
        })
    }
    .backgroundColor(Color.White)
    .borderRadius(5)
    .padding(10)
  }
}