import { ComposeTitleBar, ComposeTitleBarMenuItem, promptAction, router } from '@kit.ArkUI';
import { CustomNavigationBar } from '../view/CustomNavigationBar';
import { TeleprompterItemView } from '../view/TeleprompterItemView';
import { TeleprompterEntity } from '../database/bean/TeleprompterEntity';
import { BusinessError, emitter, systemDateTime } from '@kit.BasicServicesKit';
import { IconButton } from '../view/IconButton';
import { PermissionUtil } from '../utils/PermissionUtil';
import { TELEPROMPTER_ADD_SUCCESS } from '../utils/EventIds';
import { Logger } from '../utils/Logger';
import databaseManager from '../database/DatabaseManager';

const TAG: string = '[Page][TeleprompterHome]'

@Entry
@Component
struct TeleprompterHomePage {
  private context = getContext(this);
  @State title: string = '提词器';
  @State navHeight: number = 0;
  @State data: Array<TeleprompterEntity> = [
    new TeleprompterEntity(0, "测试内容1", this.context.resourceManager.getStringSync($r('app.string.tets0').id),
      systemDateTime.getTime()),
    new TeleprompterEntity(-1, "测试内容2", this.context.resourceManager.getStringSync($r('app.string.tets1').id),
      systemDateTime.getTime())
  ]

  aboutToAppear(): void {
    emitter.on({ eventId: TELEPROMPTER_ADD_SUCCESS }, (eventData: emitter.EventData) => {
      let target: TeleprompterEntity = eventData?.data?.Teleprompter;
      Logger.debug(TAG, `收到回调 id=${target.id}, title=${target.title}, timestamp=${target.timestamp}`);
      let filterResult = this.data.filter((item) => {
        return item.timestamp === target.timestamp;
      })
      if (filterResult.length == 0) {
        Logger.debug(TAG, '列表中没有匹配到数据')
        this.data.push(target)
      } else {
        Logger.debug(TAG, '列表中匹配到数据')
      }
    })
    this.loadDataFromDB()
  }

  private loadDataFromDB() {
    databaseManager.getAllTeleprompter((result: Array<TeleprompterEntity>) => {
      Logger.debug(TAG, `数据库中查询到 ${result.length} 条数据`)
      if (result.length > 0) {
        this.data = result;
      }
    })
  }

  build() {
    RelativeContainer() {
      // 使用自定义导航栏组件
      CustomNavigationBar({
        parTitle: this.title, parBGColor: Color.White, onHeightChange: (height) => {
          this.navHeight = height
        }
      }).id('navigationBar').alignRules({
        top: { anchor: '__container__', align: VerticalAlign.Top }
      })

      Row() {
        Text($r('app.string.teleprompt_files')).fontSize(12).fontColor('#909090').align(Alignment.Start).layoutWeight(1)
        Text(this.data.length.toString()).fontSize(12).align(Alignment.End)
      }
      .id('filesLayout')
      .layoutWeight(1)
      .height(35)
      .margin({
        left: $r('app.float.page_content_margin'), right: $r('app.float.page_content_margin')
      })
      .alignItems(VerticalAlign.Center)
      .alignRules({
        top: { anchor: 'navigationBar', align: VerticalAlign.Bottom },
      })

      List({ space: 5, initialIndex: 0 }) {
        ForEach(this.data, (item: TeleprompterEntity) => {
          ListItem() {
            TeleprompterItemView({ item: item }).margin({ left: 10, right: 10 })
              .onClick(() => {
                router.pushUrl({ url: 'pages/TeleprompterDetailPage', params: item })
              })
          }
        })
      }.alignRules({
        top: { anchor: 'filesLayout', align: VerticalAlign.Bottom },
        bottom: { anchor: 'bottomAction', align: VerticalAlign.Top }
      }).height(LayoutPolicy.matchParent).margin({ top: 5 })

      Row({ space: 5 }) {
        IconButton({
          iconRes: $r('app.media.ic_public_add_norm'),
          text: $r('app.string.teleprompt_new')
        }).layoutWeight(1)
          .onClick(() => {
            // this.data.push(new TelepromptItem("测试12", "测试内容12", systemDateTime.getTime()))
            router.pushUrl({ url: 'pages/TeleprompterEditPage' })
          })
        IconButton({
          iconRes: $r('app.media.ic_public_download'),
          text: $r('app.string.teleprompt_import')
        }).layoutWeight(1).margin({ right: 20 })
      }
      .id('bottomAction')
      .margin({
        left: 10,
        top: 5,
        bottom: 20
      })
      .width('100%')
      .height(45)
      .alignRules({
        bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.teleprompt_background'))
    .onAppear(() => {

    })
  }
}