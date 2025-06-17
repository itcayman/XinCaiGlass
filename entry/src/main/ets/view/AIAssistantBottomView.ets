import { Logger } from "../utils/Logger";
import { ResourceUtil } from "../utils/ResourceUtil";
import { isBlank } from "../utils/StringUtil";

const TAG = '[AIBottom]'
@Component
export struct AIAssistantBottomView {
  @State inputText: string = '';
  @State rightImageRes: Resource = $r('app.media.ic_add');
  callback: Callback<string> | undefined;

  build() {
    RelativeContainer() {
      Image($r('app.media.ic_input_voice'))
        .id('imageLeft')
        .width(30)
        .height(30)
        .alignRules({
          left: { anchor: '__container__', align: HorizontalAlign.Start },
          center: { anchor: '__container__', align: VerticalAlign.Center }
        })
      TextArea({ placeholder: $r('app.string.ai_input_holder'), text: this.inputText })
        .height(40)
        .borderRadius(5)
        .margin({ left: 10, right: 10 })
        .alignRules(
          {
            left: { anchor: 'imageLeft', align: HorizontalAlign.End },
            right: { anchor: 'imageRight', align: HorizontalAlign.Start }
          })
        .backgroundColor(ResourceUtil.getCommonBackgroundColor()[1])
        .onChange((value) => {
          this.inputText = value;
          if(isBlank(value)) {
            this.rightImageRes = $r('app.media.ic_add');
          } else {
            this.rightImageRes = $r('app.media.ic_send');
          }
        })
      Image(this.rightImageRes)
        .id('imageRight')
        .width(30)
        .height(30)
        .alignRules({
          right: { anchor: '__container__', align: HorizontalAlign.End },
          center: { anchor: '__container__', align: VerticalAlign.Center }
        })
        .onClick(()=>{
          if(isBlank(this.inputText)) {
            Logger.debug(TAG, '选择图库和吊起摄像头功能，待开发');
          } else {
            this.getUIContext().getFocusController().clearFocus();
            this.callback?.(this.inputText);
            this.inputText = '';
          }
        })
    }
    .width('100%')
    .height(60)
    .padding({
      top: ResourceUtil.getCommonPadding()[0],
      bottom: ResourceUtil.getCommonPadding()[0]
    })
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }
}