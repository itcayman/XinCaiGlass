import { ResourceUtil } from "../utils/ResourceUtil"

@Component
export struct QuickSettingsView {
  @State brightnessValue: number = 20
  @State silentModeOn: boolean = false

  build() {
    Row() {
      Row() {
        Image($r('app.media.ic_brightness')).width('30vp').height('30vp')
        Progress({ value: this.brightnessValue, total: 100, type: ProgressType.Linear })
          .margin({ left: '5vp' })
          .layoutWeight(1)
      }
      .padding({
        left: ResourceUtil.getCommonPadding()[2],
        top: ResourceUtil.getCommonPadding()[0],
        right: ResourceUtil.getCommonPadding()[2],
        bottom: ResourceUtil.getCommonPadding()[0]
      })
      .borderRadius(10)
      .backgroundColor(ResourceUtil.getCommonBackgroundColor()[1])
      .layoutWeight(1)

      Row() {
        Image($r('app.media.ic_silent_mode')).width('30vp').height('30vp')
        Toggle({ type: ToggleType.Switch, isOn: this.silentModeOn })
          .margin({ left: '15vp' })
      }
      .margin({ left: '10vp' })
      .padding({
        left: ResourceUtil.getCommonPadding()[2],
        top: ResourceUtil.getCommonPadding()[0],
        right: ResourceUtil.getCommonPadding()[2],
        bottom: ResourceUtil.getCommonPadding()[0]
      })
      .borderRadius(10)
      .backgroundColor(ResourceUtil.getCommonBackgroundColor()[1])
    }
  }
}