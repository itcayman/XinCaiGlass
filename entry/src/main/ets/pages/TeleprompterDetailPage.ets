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
import { PermissionUtil } from '../utils/PermissionUtil';
import realtimeAsrManager from '../core/RealtimeAsrClient';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from '../utils/Logger';
import { notificationManager } from '@kit.NotificationKit';
import notification from '@ohos.notification';
import { JhProgressHUD } from '../utils/JhProgressHUD';
import { DynamicIconButton } from '../view/DynamicIconButton';

// import router from '@ohos.router'
const TAG: string = '[JVC]TeleprompterDetail';
//眼镜上一页对应的行数
const LINES_PER_PAGE: number = 4;

@Entry
@Component
struct TeleprompterDetailPage {
  /*************** UI部分 ***************/
  private context = getContext(this) as common.UIAbilityContext;
  @State private btnDynamicScrollIcon: Resource = $r('app.media.ic_mic_on');
  @State private btnDynamicScrollText: Resource = $r("app.string.teleprompter_dynamic_scroll")
  @State private btnSpeedScrollIcon: Resource = $r('app.media.ic_public_play_norm');
  @State private btnSpeedScrollText: Resource = $r("app.string.teleprompter_speed_scroll");
  @State private maskLayerHeight: number = 500;
  /*************** 逻辑部分 ***************/
  //是否在自动滚动
  @State private isSpeedScrolling: boolean = false
  //是否在动态滚动
  private isDynamicScrolling = false
  private scrollerForScroll: Scroller = new Scroller()
  private contentController: TextController = new TextController();
  @State navHeight: number = 0;
  @State teleprompterData: TeleprompterEntity = new TeleprompterEntity(0, '', '', 0)
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
    this.stopSpeedScroll()
    CommandManager.enterHomePage()
  }

  private initRealtimeASR() {
    realtimeAsrManager.setConnectSuccessCallback(()=>{
      realtimeAsrManager.startAudioCapture();
    })
    PermissionUtil.init(getContext(this))
      .addPermissions('ohos.permission.MICROPHONE')
      .addPermissions('ohos.permission.INTERNET')
      .request()
      .then(() => {
        this.btnDynamicScrollIcon = $r('app.media.ic_mic_off');
        this.btnDynamicScrollText = $r('app.string.teleprompter_stop_scroll');
        realtimeAsrManager.connect()
      })
      .catch((error: BusinessError) => {
        Logger.error(TAG, JSON.stringify(error))
      })
  }

  private getChangeLineHeight(size: number): SizeOptions {
    let sizeOption: SizeOptions =
      MeasureText.measureTextSize({ textContent: 'Hello world!', fontSize: size, fontFamily: 'kaishu' })
    return sizeOption
  }

  private calculateMaskLayerHeight() {

  }

  // 开始动态滚动控制
  private startDynamicScroll() {
    this.isDynamicScrolling = true;
    this.initRealtimeASR();
  }

  // 停止动态滚动控制
  private stopDynamicScroll() {
    this.isDynamicScrolling = false;
    this.btnDynamicScrollIcon = $r('app.media.ic_mic_on');
    this.btnDynamicScrollText = $r('app.string.teleprompter_dynamic_scroll');
    if (realtimeAsrManager.isRecordingAudio()) {
      realtimeAsrManager.complete();
    }
    realtimeAsrManager.reset();
  }

  // 开始匀速滚动控制
  private startSpeedScroll() {
    if (!this.isSpeedScrolling) {
      Logger.log(TAG, '开始匀速滚动')
      this.isSpeedScrolling = true
      this.btnSpeedScrollIcon = $r('app.media.ic_public_pause_norm')
      this.btnSpeedScrollText = $r("app.string.teleprompter_stop_scroll")
      this.timer = setInterval(() => {
        this.innerScroll()
      }, 5000)
    }
  }

  //停止匀速滚动
  private stopSpeedScroll() {
    if (this.isSpeedScrolling && this.timer !== null) {
      Logger.log(TAG, '停止匀速滚动')
      this.isSpeedScrolling = false
      this.btnSpeedScrollIcon = $r('app.media.ic_public_play_norm')
      this.btnSpeedScrollText = $r("app.string.teleprompter_speed_scroll")
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
      this.stopSpeedScroll()
    }

    console.log(TAG, '滚动到:' + translationY);
    let sendText = '';
    let targetIndex = LINES_PER_PAGE + this.currentLineIndex;
    for (let i = this.currentLineIndex; i < targetIndex && i < this.contentLines.length; i++) {
      sendText += this.contentLines[i].text + '\n'
    }
    CommandManager.scrollTeleprompterText(sendText)
  }

  private btnDynamicClickEvent = () => {
    if (this.isDynamicScrolling) {
      this.stopDynamicScroll();
    } else if (this.isSpeedScrolling) {
      Logger.warn(TAG, '请先停止匀速滚动');
      JhProgressHUD.showError($r('app.string.tips_stop_speed_scroll'))
    } else {
      this.startDynamicScroll();
    }
  }
  private btnSpeedClickEvent = () => {
    if (this.isSpeedScrolling) {
      this.stopSpeedScroll();
    } else if (this.isDynamicScrolling) {
      Logger.warn(TAG, '请先停止动态滚动');
      JhProgressHUD.showError($r('app.string.tips_stop_dynamic_scroll'))
    } else {
      this.startSpeedScroll();
    }
  }

  build() {
    RelativeContainer() {
      CustomNavigationBar({ parTitle: $r("app.string.teleprompter"), parBGColor: Color.White }).alignRules({
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
        }.id('topContent').width('100%').padding({ left: 25, top: 20, bottom: 25 }).alignItems(HorizontalAlign.Start)

        //内容区域
        Stack({ alignContent: Alignment.BottomStart }) {
          Scroll(this.scrollerForScroll) {
            Text(this.teleprompterData.content, { controller: this.contentController })
              .fontColor('#343434')
              .fontSize(16)
              .fontFamily('kaishu')
              .padding({ left: 25, right: 25 })
              .lineHeight(25)
              .alignSelf(ItemAlign.Start)
              .width('100%')
              .onAreaChange(() => {
                this.onTextAreaChanged();
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
            .height(this.maskLayerHeight)// .height('88.5%')
            .backgroundColor('#f9f9f9')
            .opacity(0.7)
            .enabled(false)
          //此控件是为了在自动滑动时，屏蔽手势滑动事件
          Text()
            .width('100%')
            .height('100%')
            .opacity(0)
            .enabled(this.isSpeedScrolling)
        }
        .id('stack')
        .onAreaChange(() => {
          this.onStackAreaChanged();
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
        DynamicIconButton({
          iconRes: $btnDynamicScrollIcon,
          text: $btnDynamicScrollText,
        }).layoutWeight(1)
          .onClick(this.btnDynamicClickEvent)
        DynamicIconButton({
          iconRes: $btnSpeedScrollIcon,
          text: $btnSpeedScrollText
        }).layoutWeight(1).margin({ right: 20 })
          .onClick(this.btnSpeedClickEvent)
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

  private onTextAreaChanged() {
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
  }

  private onStackAreaChanged() {
    let screenHeightPX = DevicesUtil.getScreenHeight(false)
    let statusBarHeightPx = DevicesUtil.getStatusBarHeight(this.context, false).then((height) => {
      console.log(TAG, 'statusBarHeightPX:' + height + ', screenHeight:' + screenHeightPX)

      let navigationBarViewSize = ViewUtil.getComponentSize('navigationBar')
      console.log(TAG,
        'navigationBar width: ' + navigationBarViewSize.width + ', height:' + navigationBarViewSize.height);

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

      this.maskLayerHeight = screenHeightPX - height - navigationBarViewSize.height - topContentViewSize.height -
        (this.lineHeight - 42) * LINES_PER_PAGE;

      let splitCount = this.maskLayerHeight / (this.lineHeight + 30);
      for (let i = 0; i < splitCount; i++) {
        this.teleprompterData.content = this.teleprompterData.content + '\n'
      }
      this.maskLayerHeight = DevicesUtil.pxToVp(this.maskLayerHeight)
      console.warn(TAG, 'maskLayerHeight:' + this.maskLayerHeight)
    })
  }
}