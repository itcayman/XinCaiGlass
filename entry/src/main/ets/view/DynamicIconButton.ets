@Preview
struct DynamicIconButtonPreview {
  @State iconRes: Resource = $r("app.media.ic_teleprompter_import");
  @State text: string = 'Nex'

  build() {
    DynamicIconButton({ iconRes: $iconRes, text: $text })
  }
}

@Component
export struct DynamicIconButton {
  @Link iconRes: Resource
  @Link text: ResourceStr | string

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