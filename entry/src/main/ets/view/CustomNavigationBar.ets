import { router, window } from '@kit.ArkUI';
import { DevicesUtil } from '../utils/DevicesUtil';
import { common } from '@kit.AbilityKit';

@Component
export struct CustomNavigationBar {
  @State private statusBarHeight: number = 24 // 默认值(vp)
  @State private navHeight: number = 44
  @State parTitle: string = ''
  @State parBGColor: Color = Color.White
  @LocalStorageProp('isLandScape') isLandScape: boolean = false;
  @LocalStorageProp('isDevice2in1') isDevice2in1: boolean = false;
  private context = getContext(this) as common.UIAbilityContext;
  onHeightChange?: (height: number) => void

  aboutToAppear() {
    DevicesUtil.getStatusBarHeight(this.context).then(height => {
      this.statusBarHeight = height
      this.onHeightChange?.(height + this.navHeight) // 触发回调
    })
  }

  build() {
    Column() {
      Row({space: 0}) {
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.hwid_next_ic_appback'))
            .backgroundColor(Color.Transparent)
            .borderRadius(20)
            .width(40)
            .height(40)
            .draggable(false)
            .autoResize(false)
            .focusable(true)
            .fillColor($r('sys.color.ohos_id_color_titlebar_icon'))
            .matchTextDirection(true)
        }
        .alignSelf(ItemAlign.Start)
        .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
        .borderRadius(20)
        .width(40)
        .height(40)
        .margin({
          left: 15,
          top: 15,
          bottom: 15
        })
        .id('personalInfoBackPressButton')
        .onClick(() => {
          router.back()
        })

        Text(this.parTitle)
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontWeight(FontWeight.Bold)
          .padding({ left: 8 })
      }
    }
    .width('100%')
    .padding({
      // There is no need to avoid the top status bar when the device is a phone in landscape mode or 2-in-1 device.
      top: this.isLandScape || this.isDevice2in1 ? 0 : this.statusBarHeight
    })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }
}