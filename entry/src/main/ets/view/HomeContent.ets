// 导入页面路由模块
import { router } from '@kit.ArkUI';
import { BusinessError, emitter } from '@kit.BasicServicesKit';
import { PermissionUtil } from '../utils/PermissionUtil';
import { BLE_DEVICE_CONNECTED, BLE_DEVICE_DISCONNECTED } from '../constants/EventIds';
import dateTimeManager from '../core/DateTimeManager';
import { JhProgressHUD } from '../utils/JhProgressHUD';
import { HomeGridItemView } from './HomeGridItemView';
import { ResourceUtil } from '../utils/ResourceUtil';
import { GlassView } from './GlassView';
import { QuickSettingsView } from './QuickSettingsView';
import { HeaderInfoView } from './HeaderInfoView';
import { DevicesUtil } from '../utils/DevicesUtil';
import aiHttpRequest from '../network/AIHttpRequest';
import { Logger } from '../utils/Logger';
import cmgClient from '../core/CMGClient';

const TAG = '[HomeContent]'
const VERTICAL_SPACING = ResourceUtil.getCommonPadding()[0]

@Component
struct HomeContent {
  private context: UIContext = this.getUIContext();
  @State message: string = 'First Page';
  @State button: String = 'Go Second';
  @State connectText: string = 'Disconnected';

  aboutToAppear(): void {
    JhProgressHUD.initUIConfig(this.context)
  }

  private connectDevice() {
    PermissionUtil.init(getContext(this))
      .addPermissions('ohos.permission.ACCESS_BLUETOOTH')
      .request()
      .then((result) => {

      })
      .catch((error: BusinessError) => {
        console.error(JSON.stringify(error))
      })

    emitter.on({ eventId: BLE_DEVICE_CONNECTED }, (eventData: emitter.EventData) => {
      this.connectText = 'Connected';
      dateTimeManager.start()
    });
    emitter.on({ eventId: BLE_DEVICE_DISCONNECTED }, (eventData: emitter.EventData) => {
      this.connectText = 'Connected';
      dateTimeManager.stop()
    });
  }

  build() {
    Scroll() {
      Column() {
        RelativeContainer() {
          Image($r('app.media.ic_logo')).height('25vp')
          Image($r('app.media.ic_setting'))
            .height('25vp')
            .alignRules({
              right: { anchor: '__container__', align: HorizontalAlign.End }
            })
        }.height('25vp').margin({ top: VERTICAL_SPACING, bottom: VERTICAL_SPACING })

        HeaderInfoView().margin({ bottom: VERTICAL_SPACING })
        QuickSettingsView().margin({ bottom: VERTICAL_SPACING })
        GlassView().margin({ bottom: VERTICAL_SPACING })
          .onClick(() => {
            router.pushUrl({ url: 'pages/SearchARGlassPage' })
          })
        GridRow({
          columns: 2,
          gutter: { x: ResourceUtil.getCommonPadding()[2], y: VERTICAL_SPACING },
          direction: GridRowDirection.Row
        }) {
          //翻译官
          GridCol() {
            HomeGridItemView({
              iconRes: $r('app.media.ic_interpreter'),
              text: $r('app.string.interpreter'),
              des: $r("app.string.interpreter_desc")
            })
          }
          .onClick(() => {
            // router.pushUrl({ url: 'pages/SearchARGlassPage' })
            cmgClient.commandM().enterTranslatePage()
          })

          //提词器
          GridCol() {
            HomeGridItemView({
              iconRes: $r('app.media.ic_teleprompter'),
              text: $r("app.string.teleprompter"),
              des: $r("app.string.teleprompter_desc")
            })
          }
          .onClick(() => {
            router.pushUrl({ url: 'pages/TeleprompterHomePage' })
          })

          //会议助手
          GridCol() {
            HomeGridItemView({
              iconRes: $r("app.media.ic_meeting_assistant"),
              text: $r("app.string.meeting_assistant"),
              des: $r("app.string.meeting_assistant_desc")
            })
          }
          .onClick(() => {
            // router.pushUrl({ url: 'pages/TeleprompterHomePage' })
            cmgClient.commandM().enterTranslatePage()
          })

          //智慧提醒
          GridCol() {
            HomeGridItemView({
              iconRes: $r('app.media.ic_smart_reminder'),
              text: $r("app.string.smart_reminder"),
              des: $r("app.string.smart_reminder_desc")
            })
          }
          .onClick(() => {
            router.pushUrl({ url: 'pages/TeleprompterHomePage' })
          })
        }
      }.margin({
        left: ResourceUtil.getCommonPadding()[3],
        top: DevicesUtil.statusBarHeight,
        right: ResourceUtil.getCommonPadding()[3],
      }).height('100%')
    }
    .height('100%')
    .width('100%')
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }
}

export { HomeContent };
