import { router, window } from '@kit.ArkUI';
import { DevicesUtil } from '../utils/DevicesUtil';
import { common } from '@kit.AbilityKit';
import { CustomNavigationBar } from './CustomNavigationBar';

@Preview
struct NewTelepromptNavigationBarPreview {
  build() {
    CustomNavigationBar({ parBGColor: Color.White })
  }
}

@Component
export struct NewTelepromptNavigationBar {
  @State private statusBarHeight: number = 24 // 默认值(vp)
  @State parBGColor: Color = Color.White
  @LocalStorageProp('isLandScape') isLandScape: boolean = false;
  @LocalStorageProp('isDevice2in1') isDevice2in1: boolean = false;
  private context = getContext(this) as common.UIAbilityContext;

  aboutToAppear() {
    DevicesUtil.getStatusBarHeight(this.context).then(height => {
      this.statusBarHeight = height
    })
  }

  doneEdit: () => void = () => {
  };

  build() {
    Row() {
      Column() {
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.hwid_next_ic_appback'))
            .backgroundColor(Color.Transparent)
            .width(40)
            .height(40)
            .draggable(false)
            .autoResize(false)
            .focusable(true)
            .fillColor($r('sys.color.ohos_id_color_titlebar_icon'))
            .matchTextDirection(true)
        }
        .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
        .borderRadius(20)
        .height(40)
        .alignRules({
          right: { anchor: "__container__", align: HorizontalAlign.Start }
        })
        .onClick(() => {
          router.back()
        })
      }.width('25%').alignItems(HorizontalAlign.Start)

      Column() {
        Button() {
          Image($r('app.media.ic_undo')).width(24).height(24)
        }.width(40).height(40).backgroundColor(Color.Transparent)
      }.width('25%')

      Column() {
        Button() {
          Image($r('app.media.ic_redo')).width(24).height(24)
        }.width(40).height(40).backgroundColor(Color.Transparent)
      }.width('25%')

      Column() {
        Text($r('app.string.teleprompt_new_enter_done'))
          .fontSize($r('sys.float.ohos_id_text_size_headline9'))
          .padding({ left: 8 })
          .height(40)
          .alignRules({
            right: { anchor: "__container__", align: HorizontalAlign.End }
          })
          .onClick(this.doneEdit)
      }.width('25%').alignItems(HorizontalAlign.End)

    }
    .width('100%')
    .padding({
      left: 15,
      // There is no need to avoid the top status bar when the device is a phone in landscape mode or 2-in-1 device.
      top: this.isLandScape || this.isDevice2in1 ? 0 : this.statusBarHeight,
      right: 15,
      bottom: 15
    })
    .justifyContent(FlexAlign.SpaceAround)
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }
}