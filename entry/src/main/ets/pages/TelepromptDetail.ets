import { App, font, MeasureText, router } from '@kit.ArkUI';
import gattClientManager, { GattClientManager } from '../core/GattClientManager';
import {
  ENTER_TELEPROMPTER_VALUE,
  COMMAND_SWITCH_PAGE,
  COMMAND_TELEPROMPT as COMMAND_SCROLL_TELEPROMPTER
} from '../utils/ProtocolPacket';
import { TimeUtil } from '../utils/TimeUtil';
import { CreateTelepromptView } from '../view/CreateTelepromptView';
import { CustomNavigationBar } from '../view/CustomNavigationBar';
import { IconButton } from '../view/IconButton';
import { GlassPacket } from '../viewmodel/GlassPacket';
import { TelepromptLine } from '../viewmodel/TelepromptILine';
import { TelepromptData } from '../viewmodel/TelepromptItem';

// import router from '@ohos.router'
const TAG: string = '[JVC]TelepromptDetail';
//眼镜上一页对应的行数
const LINES_PER_PAGE: number = 2;

@Entry
@Component
struct TelepromptDetail {
  private scrollerForScroll: Scroller = new Scroller()
  private contentController: TextController = new TextController();
  @State title: string = '提词器';
  @State navHeight: number = 0;
  @State telepromptData: TelepromptData = new TelepromptData('', '', 0)
  //是否在自动滚动
  @State private isAutoScrolling: boolean = false
  //每行文字的高度
  @State private lineHeight: number = 0
  //当前所在行数索引
  @State private currentLineIndex: number = 0
  private timer: number | null = null
  private contentLines: Array<TelepromptLine> = new Array()

  aboutToAppear() {
    this.telepromptData = router.getParams() as TelepromptData
    for (let i = 0; i < 23; i++) {
      this.telepromptData.content = this.telepromptData.content + '\n'
    }
    console.log('@tc', this.telepromptData.toString())

    font.registerFont({
      familyName: 'kaishu',
      familySrc: '/font/SanJiWenHaoKaiShu-2.ttf' // font文件与pages目录同级
    })
    this.lineHeight = this.getChangeLineHeight(16)
    console.warn(TAG, '进入提词器详情页, lineHeight:' + this.lineHeight);
    this.lineHeight = 25
    let data: GlassPacket = {
      cmd: COMMAND_SWITCH_PAGE, tlvValue: ENTER_TELEPROMPTER_VALUE,
      valid: true
    }
    gattClientManager.writeCharacteristicValue(data)
  }

  aboutToDisappear(): void {
    this.stopAutoScroll()
  }

  private getChangeLineHeight(size: number): number {
    let sizeOption: SizeOptions =
      MeasureText.measureTextSize({ textContent: 'Hello World', fontSize: size, fontFamily: 'kaishu' })
    return Number(sizeOption.height)
  }

  // 自动滚动控制
  private startAutoScroll(): void {
    if (!this.isAutoScrolling) {
      this.isAutoScrolling = true
      console.log('@tc', '开始滚动')
      this.timer = setInterval(() => {
        this.currentLineIndex++
        console.log('@tc', '计算行高')
        let translationY = this.lineHeight * this.currentLineIndex
        this.scrollerForScroll.scrollTo({
          xOffset: 0, yOffset: translationY, animation: {
            duration: 500,
            curve: Curve.Smooth
          }
        })
        // this.scrollerForScroll.scrollToIndex()
        if (this.currentLineIndex == this.contentLines.length - LINES_PER_PAGE) {
          this.stopAutoScroll()
        }

        console.log(TAG, '滚动到:' + translationY);
        let sendText = '';
        let targetIndex = LINES_PER_PAGE + this.currentLineIndex;
        for (let i = this.currentLineIndex; i < targetIndex && i < this.contentLines.length; i++) {
          sendText += this.contentLines[i].text + '\n'
        }
        let data: GlassPacket = {
          cmd: COMMAND_SCROLL_TELEPROMPTER, tlvValue: sendText,
          valid: true
        }
        gattClientManager.writeCharacteristicValue(data)
      }, 5000)
    }
  }

  //停止自动滚动
  private stopAutoScroll(): void {
    if (this.isAutoScrolling && this.timer !== null) {
      this.isAutoScrolling = false
      clearInterval(this.timer)
      this.timer = null
    }
  }

  build() {
    RelativeContainer() {
      CustomNavigationBar({ parTitle: this.title, parBGColor: Color.White }).alignRules({
        top: { anchor: '__container__', align: VerticalAlign.Top }
      }).id('navigationBar')

      Column() {
        //标题
        Text(this.telepromptData.title)
          .fontColor('#8a8a8a')
          .fontSize(16)
          .padding({ left: 20, top: 20 })
          .alignSelf(ItemAlign.Start)
        //日期
        Text(TimeUtil.formatTimestamp(this.telepromptData.timestamp))
          .fontColor('#c1c1c1')
          .fontSize(12)
          .padding({ left: 20 })
          .height(20)
          .alignSelf(ItemAlign.Start)
        //内容区域
        Stack({ alignContent: Alignment.BottomStart }) {
          Scroll(this.scrollerForScroll) {
            Text(this.telepromptData.content, { controller: this.contentController })
              .fontColor('#343434')
              .fontSize(16)
              .fontFamily('kaishu')
              .padding({ left: 20 })
              .lineHeight(25)
              .alignSelf(ItemAlign.Start)
              .width('100%')
              .onAreaChange(() => {
                let layoutManager: LayoutManager = this.contentController.getLayoutManager();
                if (layoutManager.getLineCount() <= 0 || this.contentLines.length > 0) {
                  return
                }
                let lineCount = layoutManager.getLineCount();
                console.warn('@tc', 'lineCount: ' + lineCount);
                for (let index = 0; index < lineCount; index++) {
                  let metrics = layoutManager.getLineMetrics(index)
                  let text = this.telepromptData.content.substring(metrics.startIndex, metrics.endIndex)
                  let line = new TelepromptLine(index, metrics.height, metrics.startIndex, metrics.endIndex, text)
                  this.contentLines.push(line)
                  console.log('@tc', 'line: ' + line.toString());
                }
              })
          }
          .width('100%')
          .backgroundColor(Color.White)
          .margin({ top: 20, bottom: 60 })
          .scrollBarWidth(0)
          .edgeEffect(EdgeEffect.Spring)

          //遮罩层
          Text()
            .width('100%')
            .height('88.5%')
            .backgroundColor('#f9f9f9')
            .opacity(0.7)
            .enabled(false)
          //此控件是为了在自动滑动时，屏蔽手势滑动事件
          Text()
            .width('100%')
            .height('100%')
            .opacity(0)
            .enabled(this.isAutoScrolling)
        }
      }
      .backgroundColor($r('app.color.teleprompt_detail_background'))
      .borderRadius(5)
      .width('100%')
      .constraintSize({ maxWidth: '100%' })
      .margin({
        left: $r('app.float.page_content_margin'),
        right: $r('app.float.page_content_margin')
      })
      .alignRules({
        top: { anchor: 'navigationBar', align: VerticalAlign.Bottom },
        bottom: { anchor: 'bottomAction', align: VerticalAlign.Top }
      })

      //底部按钮
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
          text: $r('app.string.teleprompt_scroll_start')
        }).layoutWeight(1).margin({ right: 20 })
          .onClick(() => {
            this.startAutoScroll()
          })
      }
      .id('bottomAction')
      .margin({ left: 10, top: 5, bottom: 20 })
      .width('100%')
      .height(45)
      .alignRules({
        bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
      })
    }
    .height('100%')
    .width('100%')
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }
}