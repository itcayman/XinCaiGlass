import cmgClient from '../core/CMGClient'
import { Logger } from '../utils/Logger'
import { ResourceUtil } from '../utils/ResourceUtil'
import { CustomNavigationBar } from '../view/CustomNavigationBar'
import { TeleprompterConfig } from '../viewmodel/config/TeleprompterConfig'
import { TeleprompterSpeed } from '../viewmodel/TelepromterSpeed'

const TAG = '[提词器设置]'

@Entry
@Component
struct TeleprompterSettingPage {
  private config: TeleprompterConfig = new TeleprompterConfig()
  @State receiveMessageOn: boolean = false
  @State private speedData: Array<TeleprompterSpeed> = [
    new TeleprompterSpeed(20, $r('app.string.teleprompter_setting_speed1')),
    new TeleprompterSpeed(15, $r('app.string.teleprompter_setting_speed2')),
    new TeleprompterSpeed(10, $r('app.string.teleprompter_setting_speed3'))
  ]

  aboutToAppear(): void {
    this.config = cmgClient.teleprompterC()
    this.speedData = this.speedData.map(target => {
      target.selected = target.scrollOnePageTime == cmgClient.teleprompterC().scrollOnePageSeconds
      return target;
    })
  }

  @Builder
  private itemView(item: TeleprompterSpeed) {
    Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
      Checkbox({ name: 'checkbox1', group: 'checkboxGroup' })
        .shape(CheckBoxShape.CIRCLE)
        .onChange((value: boolean) => {
          if (value) {
            this.speedData = this.speedData.map(target => {
              return new TeleprompterSpeed(target.scrollOnePageTime, target.desc,
                item.scrollOnePageTime == target.scrollOnePageTime);
            })
          }
          this.config.scrollOnePageSeconds = item.scrollOnePageTime;
          cmgClient.updateTeleprompterConfig(this.config)
        })
        .select(item.selected)
        .width(25)
        .height(25)
      Text(item.desc).fontSize(16).margin({ left: 10 })
    }.padding({ top: 10, bottom: 10 })
  }

  build() {
    RelativeContainer() {
      CustomNavigationBar({
        parTitle: $r("app.string.teleprompter_setting")
      }).id('navigationBar')

      Column() {
        Text($r('app.string.teleprompter_setting_speed_desc'))
          .fontSize(16).fontWeight(FontWeight.Bold)
        List() {
          ForEach(this.speedData, (item: TeleprompterSpeed) => {
            ListItem() {
              this.itemView(item)
            }
          })
        }.width('100%').margin({ top: 10 }).alignListItem(ListItemAlign.Start)
      }
      .id('speedLayout')
      .alignItems(HorizontalAlign.Start)
      .alignRules({
        top: { anchor: 'navigationBar', align: VerticalAlign.Bottom },
      })
      .padding(15)
      .margin({ left: 15, right: 15 })
      .borderRadius(ResourceUtil.getCommonBorderRadius())
      .backgroundColor(Color.White)

      Row() {
        Text($r('app.string.teleprompter_setting_message_desc')).layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.receiveMessageOn })
          .margin({ left: '15vp' })
      }
      .alignRules({
        top: { anchor: 'speedLayout', align: VerticalAlign.Bottom },
      })
      .margin({ left: 15, top: 10, right: 15 })
      .padding(15)
      .borderRadius(ResourceUtil.getCommonBorderRadius())
      .backgroundColor(Color.White)
    }
    .height('100%')
    .width('100%')
    .backgroundColor($r('app.color.teleprompt_background'))
  }
}