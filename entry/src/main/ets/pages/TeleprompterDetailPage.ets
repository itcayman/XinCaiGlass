import { App, font, MeasureText, router } from '@kit.ArkUI';
import CommandManager from '../core/CommandManager';
import { DevicesUtil } from '../utils/DevicesUtil';
import { TimeUtil } from '../utils/TimeUtil';
import { ViewUtil } from '../utils/ViewUtil';
import { CustomNavigationBar } from '../view/CustomNavigationBar';
import { IconButton } from '../view/IconButton';
import { TeleprompterEntity } from '../database/bean/TeleprompterEntity';
import { TeleprompterLine } from '../viewmodel/TeleprompterLine';
import { common } from '@kit.AbilityKit';

// import router from '@ohos.router'
const TAG: string = '[JVC]TeleprompterDetail';
//眼镜上一页对应的行数
const LINES_PER_PAGE: number = 2;

@Entry
@Component
struct TeleprompterDetailPage {
  private context = getContext(this) as common.UIAbilityContext;
  @State private maskLayerHeight: number = 500;
  private scrollerForScroll: Scroller = new Scroller()
  private contentController: TextController = new TextController();
  @State navHeight: number = 0;
  @State teleprompterData: TeleprompterEntity = new TeleprompterEntity(0, '', '', 0)
  //是否在自动滚动
  @State private isAutoScrolling: boolean = false
  //每行文字的高度
  @State private lineHeight: number = 0
  //当前所在行数索引
  @State private currentLineIndex: number = 0
  private timer: number | null = null
  private contentLines: Array<TeleprompterLine> = new Array()

  aboutToAppear() {
    this.teleprompterData = router.getParams() as TeleprompterEntity
    console.log('@tc', this.teleprompterData.toString())

    font.registerFont({
      familyName: 'kaishu',
      familySrc: '/font/SanJiWenHaoKaiShu-2.ttf' // font文件与pages目录同级
    })
    this.lineHeight = Number(this.getChangeLineHeight(16).height);
    console.warn(TAG, '进入提词器详情页, lineHeight:' + this.lineHeight);
    CommandManager.enterTeleprompterPage()
  }

  aboutToDisappear(): void {
    this.stopAutoScroll()
    CommandManager.enterHomePage()
  }

  private getChangeLineHeight(size: number): SizeOptions {
    let sizeOption: SizeOptions =
      MeasureText.measureTextSize({ textContent: 'Hello world!', fontSize: size, fontFamily: 'kaishu' })
    return sizeOption
  }

  private calculateMaskLayerHeight() {

  }

  // 自动滚动控制
  private startAutoScroll(): void {
    if (!this.isAutoScrolling) {
      this.isAutoScrolling = true
      console.log('@tc', '开始滚动')
      this.innerScroll()
      this.timer = setInterval(() => {
        this.innerScroll()
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

  private innerScroll() {
    this.currentLineIndex += LINES_PER_PAGE
    console.log('@tc', '计算行高')
    // let translationY = this.lineHeight * this.currentLineIndex
    let translationY = 25 * this.currentLineIndex
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
    CommandManager.scrollTeleprompterText(sendText)
  }

  build() {
    RelativeContainer() {
      CustomNavigationBar({ parTitle: $r('app.string.teleprompt'), parBGColor: Color.White }).alignRules({
        top: { anchor: '__container__', align: VerticalAlign.Top }
      }).id('navigationBar')

      Column() {
        Column() {
          //标题
          Text(this.teleprompterData.title)
            .fontColor('#8a8a8a')
            .fontSize(16)
            .alignSelf(ItemAlign.Start)
          //日期
          Text(TimeUtil.formatTimestamp(this.teleprompterData.timestamp))
            .fontColor('#c1c1c1')
            .fontSize(12)
            .height(20)
        }.id('topContent').width('100%').padding({left:25, top: 20, bottom:25}).alignItems(HorizontalAlign.Start)

        //内容区域
        Stack({ alignContent: Alignment.BottomStart }) {
          Scroll(this.scrollerForScroll) {
            Text(this.teleprompterData.content, { controller: this.contentController })
              .fontColor('#343434')
              .fontSize(16)
              .fontFamily('kaishu')
              .padding({ left: 25, right:25 })
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
                  let text = this.teleprompterData.content.substring(metrics.startIndex, metrics.endIndex)
                  let line = new TeleprompterLine(index, metrics.height, metrics.startIndex, metrics.endIndex, text)
                  this.contentLines.push(line)
                  console.log('@tc', 'line: ' + line.toString());
                }
              })
          }
          .width('100%')
          .backgroundColor(Color.White)
          .margin({ bottom: 60 })
          .scrollBarWidth(0)
          .edgeEffect(EdgeEffect.Spring)

          //遮罩层
          Text()
            .id('maskLayer')
            .width('100%')
            .height(this.maskLayerHeight)
            // .height('88.5%')
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
        .id('stack')
        .onAreaChange(() => {
          let screenHeightPX = DevicesUtil.getScreenHeight(false)
          let statusBarHeightPx = DevicesUtil.getStatusBarHeight(this.context, false).then((height)=>{
            console.log(TAG, 'statusBarHeightPX:' + height+', screenHeight:'+screenHeightPX)

            let navigationBarViewSize = ViewUtil.getComponentSize('navigationBar')
            console.log(TAG, 'navigationBar width: ' + navigationBarViewSize.width + ', height:' + navigationBarViewSize.height);

            let contentViewSize = ViewUtil.getComponentSize('content')
            console.log(TAG, 'content width: ' + contentViewSize.width + ', height:' + contentViewSize.height);

            let stackViewSize = ViewUtil.getComponentSize('stack')
            console.log(TAG, 'stack width: ' + stackViewSize.width + ', height:' + stackViewSize.height);

            let topContentViewSize = ViewUtil.getComponentSize('topContent')
            console.log(TAG, 'topContent width: ' + topContentViewSize.width + ', height:' + topContentViewSize.height);

            let bottomActionViewSize = ViewUtil.getComponentSize('bottomAction')
            console.log(TAG, 'bottomAction width: ' + bottomActionViewSize.width + ', height:' + bottomActionViewSize.height);

            let maskLayerViewSize = ViewUtil.getComponentSize('maskLayer')
            console.log(TAG, 'maskLayer width: ' + maskLayerViewSize.width + ', height:' + maskLayerViewSize.height);

            this.maskLayerHeight = screenHeightPX - height - navigationBarViewSize.height - topContentViewSize.height - (this.lineHeight - 42) * LINES_PER_PAGE;

            let splitCount = this.maskLayerHeight / (this.lineHeight + 30);
            for (let i = 0; i < splitCount; i++) {
              this.teleprompterData.content = this.teleprompterData.content + '\n'
            }
            this.maskLayerHeight = DevicesUtil.pxToVp(this.maskLayerHeight)
            console.warn(TAG, 'maskLayerHeight:'+this.maskLayerHeight)
          })
        })
      }
      .id('content')
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
          text: $r("app.string.teleprompt_ai_scroll_start")
        }).layoutWeight(1)
          .onClick(() => {
            // this.data.push(new TelepromptItem("测试12", "测试内容12", systemDateTime.getTime()))
            router.pushUrl({ url: 'pages/EditTeleprompt' })
          })
        IconButton({
          iconRes: $r('app.media.ic_public_play_norm'),
          text: $r("app.string.teleprompt_auto_scroll_start")
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