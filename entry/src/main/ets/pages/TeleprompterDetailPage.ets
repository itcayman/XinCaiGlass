import { App, font, MeasureText, MeasureUtils, router } from '@kit.ArkUI';
import CommandManager from '../core/CommandManager';
import { DevicesUtil } from '../utils/DevicesUtil';
import { TimeUtil } from '../utils/TimeUtil';
import { ViewUtil } from '../utils/ViewUtil';
import { CustomNavigationBar } from '../view/CustomNavigationBar';
import { TeleprompterEntity } from '../database/bean/TeleprompterEntity';
import { TeleprompterLine } from '../viewmodel/TeleprompterLine';
import { common } from '@kit.AbilityKit';
import { PermissionUtil } from '../utils/PermissionUtil';
import realtimeAsrManager from '../core/RealtimeAsrClient';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from '../utils/Logger';
import { JhProgressHUD } from '../utils/JhProgressHUD';
import { DynamicIconButton } from '../view/DynamicIconButton';

import measure from '@ohos.measure'
import { isBlank } from '../utils/StringUtil';

// import router from '@ohos.router'
const TAG: string = '[TeleprompterDetail]';
//眼镜上一页对应的行数
const LINES_PER_PAGE: number = 4;
const LINE_HEIGHT = 25

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
  //当前所在行数索引
  @State private currentLineIndex: number = 0
  private timer: number | null = null
  private contentLines: Array<TeleprompterLine> = new Array()

  aboutToAppear() {
    this.teleprompterData = router.getParams() as TeleprompterEntity
    Logger.log(TAG, this.teleprompterData.toString())

    font.registerFont({
      familyName: 'kaishu',
      familySrc: '/font/SanJiWenHaoKaiShu-2.ttf' // font文件与pages目录同级
    })
    Logger.warn(TAG, '进入提词器详情页');
    CommandManager.enterTeleprompterPage()
  }

  aboutToDisappear(): void {
    this.stopSpeedScroll()
    CommandManager.enterHomePage()
  }

  private initRealtimeASR() {
    realtimeAsrManager.setConnectSuccessCallback(() => {
      realtimeAsrManager.startAudioCapture();
    })
    realtimeAsrManager.setTranscriptionCallback((result) => {
      this.afterGetTranscriptResult(result);
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
      realtimeAsrManager.stopAudioCapture();
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
        this.innerScrollLine(this.currentLineIndex + LINES_PER_PAGE)
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

  private innerScrollLine(lineNum: number) {
    this.currentLineIndex = lineNum;
    let translationY = LINE_HEIGHT * lineNum
    Logger.log(TAG, `滚动到 ${lineNum} 行， y: ${translationY}`);
    this.scrollerForScroll.scrollTo({
      xOffset: 0, yOffset: translationY, animation: {
        duration: 500,
        curve: Curve.Smooth
      }
    })
    if (lineNum >= (this.contentLines.length - LINES_PER_PAGE)) {
      this.stopSpeedScroll()
    }
    this.sendTextToGlass();
  }

  /**
   * 发送数据到眼镜端
   * */
  private sendTextToGlass() {
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

  private onTextAreaChanged() {
    let layoutManager: LayoutManager = this.contentController.getLayoutManager();
    if (layoutManager.getLineCount() <= 0 || this.contentLines.length > 0) {
      return
    }
    let lineCount = layoutManager.getLineCount();
    Logger.info(TAG, `文本总行数: ${lineCount}`);
    for (let index = 0; index < lineCount; index++) {
      let metrics = layoutManager.getLineMetrics(index)
      let text = this.teleprompterData.content.substring(metrics.startIndex, metrics.endIndex)
      let line = new TeleprompterLine(index, metrics.height, metrics.startIndex, metrics.endIndex, text)
      this.contentLines.push(line)
      // Logger.log(TAG, 'line: ' + line.toString());
    }
  }

  private onStackAreaChanged() {
    let stackViewSize = ViewUtil.getComponentSize('stack')
    this.maskLayerHeight = px2vp(stackViewSize.height) - LINE_HEIGHT * LINES_PER_PAGE;
    let spaceLineCount = this.maskLayerHeight / LINE_HEIGHT;
    for (let i = 0; i < spaceLineCount; i++) {
      this.teleprompterData.content = this.teleprompterData.content + '\n'
    }
    Logger.warn(TAG, 'maskLayerHeight:' + this.maskLayerHeight)
  }

  private afterScroll() {
    let scrolledY = this.scrollerForScroll.currentOffset().yOffset;
    if (scrolledY % LINE_HEIGHT == 0) {
      this.sendTextToGlass();
      return;
    }
    let targetLineNum = Math.floor(scrolledY / LINE_HEIGHT);
    Logger.debug(TAG, `scrolled y: ${scrolledY}`);
    this.innerScrollLine(targetLineNum);
  }

  /**
   * 获取到语音识别的结果后，需要滚动到文本对应的行数
   * @param result 通过语音流识别到的文本内容
   * */
  private afterGetTranscriptResult(result: string) {
    if (!isBlank(result) && result.length == 1) {
      Logger.info(TAG, `return: ${result}`);
      return;
    }
    let lastLine = this.currentLineIndex + LINES_PER_PAGE;
    // Logger.info(TAG, `lastLine: ${lastLine}`);
    for (let i = this.currentLineIndex; i < lastLine; i++) {
      let lineText = this.contentLines[i].text;
      let findSuccess = lineText.indexOf(result) >= 0;
      // Logger.info(TAG, `line: ${i}, text: ${lineText}, findSuccess: ${findSuccess}}`);
      if (findSuccess && i > this.currentLineIndex) {
        Logger.info(TAG, `语音识别到当前行数: ${i}`);
        this.innerScrollLine(i);
        return;
      }
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
              .id('contentText')
              .fontColor('#343434')
              .fontSize(16)
              // .fontFamily('kaishu')
              .lineHeight(LINE_HEIGHT)
              .padding({ left: 35, right: 35 })
              .width('100%')
              .onAreaChange(() => {
                this.onTextAreaChanged();
              })
          }
          .width('100%')
          .backgroundColor(Color.White)
          // .edgeEffect(EdgeEffect.Spring)
          .onScrollStop(() => {
            this.afterScroll()
          })

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
        }).layoutWeight(1)
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
}