import { ComposeTitleBar, ComposeTitleBarMenuItem, promptAction, router } from '@kit.ArkUI';
import { CustomNavigationBar } from '../view/CustomNavigationBar';
import { TelepromptItemView } from '../view/TelepromptItemView';
import { TelepromptData } from '../viewmodel/TelepromptItem';
import { systemDateTime } from '@kit.BasicServicesKit';
import { IconButton } from '../view/IconButton';

@Entry
@Component
struct TelepromptHome {
  private context = getContext(this);
  @State title: string = '提词器';
  @State navHeight: number = 0;
  @State data: Array<TelepromptData> = [
    new TelepromptData("测试0", this.context.resourceManager.getStringSync($r('app.string.tets0').id), systemDateTime.getTime()),
    new TelepromptData("测试1",  this.context.resourceManager.getStringSync($r('app.string.tets1').id), systemDateTime.getTime()),
    new TelepromptData("测试2", "测试内容2", systemDateTime.getTime()),
    new TelepromptData("测试3", "测试内容3", systemDateTime.getTime()),
    new TelepromptData("测试4", "测试内容4", systemDateTime.getTime()),
    new TelepromptData("测试5", "测试内容5", systemDateTime.getTime()),
    new TelepromptData("测试6", "测试内容6", systemDateTime.getTime()),
    new TelepromptData("测试7", "测试内容7", systemDateTime.getTime()),
    new TelepromptData("测试8", "测试内容8", systemDateTime.getTime()),
    new TelepromptData("测试9", "测试内容9", systemDateTime.getTime()),
    new TelepromptData("测试10", "测试内容10", systemDateTime.getTime()),
    new TelepromptData("测试11", "测试内容11", systemDateTime.getTime()),
  ]

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
        ForEach(this.data, (item: TelepromptData) => {
          ListItem() {
            TelepromptItemView({ item: item }).margin({ left: 10, right: 10 })
              .onClick(() => {
                router.pushUrl({ url: 'pages/TelepromptDetail', params: item })
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
            router.pushUrl({ url: 'pages/EditTeleprompt' })
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