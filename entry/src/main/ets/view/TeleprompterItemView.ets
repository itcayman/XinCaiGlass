import { TimeUtil } from '../utils/TimeUtil';
import { systemDateTime } from '@kit.BasicServicesKit';
import { TeleprompterEntity } from '../database/bean/TeleprompterEntity';

@Preview
@Component
  //定义组件片段TitlePreview
struct TelepromptItemWidgetPreview {
  build() {
    TeleprompterItemView({
      item: new TeleprompterEntity(-1, '测试提词器', '测试内容测试内容', systemDateTime.getTime())
    }
    )
  }
}

@Component
export struct TeleprompterItemView {
  @State item: TeleprompterEntity = new TeleprompterEntity(0, '','', 0)

  build() {
    Row() {
      Column() {
        Text(this.item.title)
          .fontColor($r('app.color.teleprompt_item_title'))
          .fontSize($r("app.float.teleprompt_item_title_font_size"))
        Text(TimeUtil.formatTimestamp(this.item.timestamp))
          .margin({top: 8})
          .fontColor($r('app.color.teleprompt_item_time'))
          .fontSize($r('app.float.teleprompt_item_time_font_size'))
      }.layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Image($r('app.media.ic_public_arrow_right'))
        .width(20)
        .height(20)
        .align(Alignment.End)
    }.width('100%')
    .padding(10)
    .borderRadius(5)
    .backgroundColor(Color.White)
  }
}