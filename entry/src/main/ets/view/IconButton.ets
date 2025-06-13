@Preview
struct IconButtonPreview {
  build() {
    IconButton({ iconRes: $r("app.media.ic_teleprompter_import"), text: 'New' })
  }
}

@Component
export struct IconButton {
  @State iconRes: Resource = $r('sys.media.ohos_ic_back')
  @State text: ResourceStr = ''

  build() {
    Button({ type: ButtonType.Normal, stateEffect: true }) {
      Row() {
        Image(this.iconRes).height(20).margin({ left: 12 })
        Text(this.text).fontSize(14).fontColor('#282828').margin({ left: 15, right: 12 })
      }.alignItems(VerticalAlign.Center)
    }
    .borderRadius(8)
    .backgroundColor(Color.White)
    .width('100%')
    .height('100%')
  }
}