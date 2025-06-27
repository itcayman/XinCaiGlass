import { App, font, MeasureText, MeasureUtils, router } from '@kit.ArkUI';
import { DoubleClick, RemoteControl } from '../core/CommandManager';
import { DevicesUtil } from '../utils/DevicesUtil';
import { TimeUtil } from '../utils/TimeUtil';
import { ViewUtil } from '../utils/ViewUtil';
import { CustomNavigationBar } from '../view/CustomNavigationBar';
import { TeleprompterEntity } from '../database/bean/TeleprompterEntity';
import { TeleprompterLine } from '../viewmodel/TeleprompterLine';
import { common } from '@kit.AbilityKit';
import { PermissionUtil } from '../utils/PermissionUtil';
import { BusinessError, emitter } from '@kit.BasicServicesKit';
import { Logger } from '../utils/Logger';
import { JhProgressHUD } from '../utils/JhProgressHUD';
import { DynamicIconButton } from '../view/DynamicIconButton';

import measure from '@ohos.measure'
import { isBlank } from '../utils/StringUtil';
import cmgClient from '../core/CMGClient';
import systemDateTime from '@ohos.systemDateTime';
import { DynamicArrayBuffer } from '../viewmodel/DynamicArrayBuffer';
import { StringChecker } from '../utils/StringChecker';
import { BLE_DEVICE_DISCONNECTED, TELEPROMPTER_EDIT_SUCCESS } from '../constants/EventIds';

// import router from '@ohos.router'
const TAG: string = '[TeleprompterDetail]';
//眼镜上一页对应的行数
const LINES_PER_PAGE: number = 5;
const COUNT_TO_LAST = 2;
//最少匹配2个字
const MIN_FILTER_CHARACTERS = 2;
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
  @State private title: string = ''
  @State private timestamp: string = ''
  @State private content: string = ''
  @State private maskLayerHeight: number = 500;
  /*************** 逻辑部分 ***************/
  //是否在自动滚动
  @State private isSpeedScrolling: boolean = false
  //是否在动态滚动
  private isDynamicScrolling = false
  private scrollerForScroll: Scroller = new Scroller()
  private contentController: TextController = new TextController();
  @State teleprompterData: TeleprompterEntity = new TeleprompterEntity(0, '', '', 0)
  //当前显示页对应行的索引
  private currentPageFirstLineIndex: number = 0
  //当前正在朗读行的索引
  private currentReadLineIndex = 0
  private lastScrolledY = -1
  private timer: number | null = null
  private contentLines: Array<TeleprompterLine> = new Array()
  private enterTimestamp = 0;
  private audioCallback: Callback<ArrayBuffer> | undefined;
  private remoteControlCallback = (command: RemoteControl) => {
    Logger.warn(TAG, `收到遥控器按键: ${command}`);
    switch (command) {
      case RemoteControl.LEFT:
        break;
      case RemoteControl.RIGHT:
        break;
      case RemoteControl.PREV:
        this.innerScrollLine(this.currentPageFirstLineIndex - LINES_PER_PAGE);
        break;
      case RemoteControl.NEXT:
        const current = systemDateTime.getTime();
        if (current - this.enterTimestamp < 500) {
          this.innerScrollLine(0);
        } else {
          this.innerScrollLine(this.currentPageFirstLineIndex + LINES_PER_PAGE);
        }
        break;
      case RemoteControl.ESC:
        break;
    }
  };
  private doubleClickCallback = (command: DoubleClick) => {
    Logger.warn(TAG, `收到双击事件: ${command}`);
    switch (command) {
      case DoubleClick.START:
        break;
      case DoubleClick.STOP:
        break;
      case DoubleClick.CLOSE:
        break;
      case DoubleClick.ERROR:
        break;
    }
  };
  private transcriptionCallback = (result: string) => {
    this.afterGetTranscriptResult(result);
  };
  private onTeleprompterEditDone = (eventData: emitter.EventData) => {
    let target: TeleprompterEntity = eventData?.data?.Teleprompter;
    Logger.debug(TAG, `收到回调 id=${target.id}, title=${target.title}, timestamp=${target.timestamp}`);
    if (this.teleprompterData.timestamp == target.timestamp) {
      this.teleprompterData = target;
      this.title = this.teleprompterData.title;
      this.timestamp = TimeUtil.formatTimestamp(this.teleprompterData.timestamp);
      this.content = this.teleprompterData.content;
    }
  };

  private onDisconnected = () => {
    JhProgressHUD.showToast($r('app.string.state_disconnect_toast'))
  }

  aboutToAppear() {
    this.observerTeleprompterEditDone();
    emitter.on({ eventId: BLE_DEVICE_DISCONNECTED }, this.onDisconnected)
    this.enterTimestamp = systemDateTime.getTime();
    this.teleprompterData = router.getParams() as TeleprompterEntity
    this.title = this.teleprompterData.title;
    this.timestamp = TimeUtil.formatTimestamp(this.teleprompterData.timestamp);
    this.content = this.teleprompterData.content;
    Logger.log(TAG, this.teleprompterData.toString())

    font.registerFont({
      familyName: 'kaishu',
      familySrc: '/font/SanJiWenHaoKaiShu-2.ttf' // font文件与pages目录同级
    })
    Logger.warn(TAG, '进入提词器详情页');
    cmgClient.commandM().addRemoteControlCallback(this.remoteControlCallback);
    cmgClient.commandM().addDoubleCallback(this.doubleClickCallback);
    cmgClient.commandM().enterTeleprompterPage()
    // this.innerScrollLine(0);
  }

  aboutToDisappear(): void {
    emitter.off(TELEPROMPTER_EDIT_SUCCESS, this.onTeleprompterEditDone);
    emitter.off(BLE_DEVICE_DISCONNECTED, this.onDisconnected)
    this.stopSpeedScroll();
    cmgClient.commandM().removeRemoteControlCallback(this.remoteControlCallback);
    cmgClient.commandM().removeDoubleCallback(this.doubleClickCallback);
    cmgClient.commandM().enterHomePage();
    cmgClient.realtimeAsrM().stopAudioCapture();
    cmgClient.realtimeAsrM().setConnectSuccessCallback(undefined);
    this.stopSpeedScroll();
    this.stopDynamicScroll();
  }

  private observerTeleprompterEditDone() {
    emitter.on({ eventId: TELEPROMPTER_EDIT_SUCCESS }, this.onTeleprompterEditDone)
  }

  private initRealtimeASR() {
    JhProgressHUD.showLoadingText('加载中...')
    cmgClient.realtimeAsrM().setConnectSuccessCallback(() => {
      if (cmgClient.teleprompterC().useMicForGlass) {
        this._initGlassMic();
      } else {
        cmgClient.realtimeAsrM().startAudioCapture();
      }
      JhProgressHUD.hide();
    })
    cmgClient.realtimeAsrM().addTranscriptionCallback(this.transcriptionCallback);
    PermissionUtil.init(getContext(this))
      .addPermissions('ohos.permission.MICROPHONE')
      .addPermissions('ohos.permission.INTERNET')
      .request()
      .then(() => {
        this.btnDynamicScrollIcon = $r('app.media.ic_mic_off');
        this.btnDynamicScrollText = $r('app.string.teleprompter_stop_scroll');
        cmgClient.realtimeAsrM().connect()
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
    if (!this.isDynamicScrolling) {
      return;
    }
    this.isDynamicScrolling = false;
    this.btnDynamicScrollIcon = $r('app.media.ic_mic_on');
    this.btnDynamicScrollText = $r('app.string.teleprompter_dynamic_scroll');
    if (cmgClient.realtimeAsrM().isRecordingAudio()) {
      cmgClient.realtimeAsrM().stopAudioCapture();
      cmgClient.realtimeAsrM().complete();
    }
    cmgClient.realtimeAsrM().reset();
    cmgClient.commandM().closeMic();
    cmgClient.realtimeAsrM().removeTranscriptionCallback(this.transcriptionCallback);
    if (this.audioCallback) {
      cmgClient.gattClientM().removeAudioCallback(this.audioCallback);
    }
  }

  // 开始匀速滚动控制
  private startSpeedScroll() {
    if (!this.isSpeedScrolling) {
      Logger.log(TAG, '开始匀速滚动')
      this.isSpeedScrolling = true
      this.btnSpeedScrollIcon = $r('app.media.ic_public_pause_norm')
      this.btnSpeedScrollText = $r("app.string.teleprompter_stop_scroll")
      this.timer = setInterval(() => {
        this.innerScrollLine(this.currentPageFirstLineIndex + LINES_PER_PAGE)
      }, cmgClient.teleprompterC().scrollOnePageSeconds * 1000)
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
    if (lineNum < 0 || lineNum >= this.contentLines.length) {
      return;
    }

    this.currentPageFirstLineIndex = lineNum;
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

  private _initGlassMic() {
    let buffer = new DynamicArrayBuffer();
    let lastTime = systemDateTime.getTime();
    this.audioCallback = (data: ArrayBuffer) => {
      // Logger.info(TAG, '===============收到音频通知，数据长度:' + characteristic.characteristicValue.byteLength);\
      let current = systemDateTime.getTime();
      buffer.append(data);
      if (current - lastTime >= 500) {
        // Logger.info(TAG, `积累到100个包长度 ${buffer.length}，发送音频数据进行识别...`);
        // Logger.info(TAG, `发送长度 ${buffer.length}，发送音频数据进行识别...`);
        cmgClient.realtimeAsrM().sendAudioData(buffer.getBuffer());
        buffer = new DynamicArrayBuffer();
        lastTime = current;
      }
      // this.pcm.writePCMData(data);
    }
    cmgClient.gattClientM().addAudioCallback(this.audioCallback);
    cmgClient.commandM().openMic();
  }

  /**
   * 发送数据到眼镜端
   * */
  private sendTextToGlass() {
    let sendText = '';
    let targetIndex = LINES_PER_PAGE + this.currentPageFirstLineIndex;
    for (let i = this.currentPageFirstLineIndex; i < targetIndex && i < this.contentLines.length; i++) {
      let text = this.contentLines[i].text
      text = text.replaceAll('“', '"')
      text = text.replaceAll('”', '"')
      text = text.replaceAll('，', ', ')
      text = text.replaceAll('！', '! ')
      text = text.replaceAll('：', ': ')
      text = text.replaceAll('；', '; ')
      text = text.replaceAll('？', '? ')
      sendText += text.endsWith('\n') ? text : (text + '\n')
    }
    cmgClient.commandM().scrollTeleprompterText(sendText)
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
  private btnMoreClickEvent = () => {
    router.pushUrl({ url: 'pages/TeleprompterSettingPage' })
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
      let text = this.content.substring(metrics.startIndex, metrics.endIndex)
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
      this.content = this.content + '\n'
    }
    Logger.warn(TAG, 'maskLayerHeight:' + this.maskLayerHeight)
  }

  private afterScroll() {
    let scrolledY = this.scrollerForScroll.currentOffset().yOffset;
    if (this.lastScrolledY == scrolledY) {
      return;
    }
    this.lastScrolledY = scrolledY;
    if (scrolledY != 0 && scrolledY % LINE_HEIGHT == 0) {
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
    Logger.info(TAG, `当前页第一行索引是【${this.currentPageFirstLineIndex}】待查找【${result}】...`);
    if (!isBlank(result) && result.length == 1) {
      Logger.info(TAG, `return: ${result}`);
      return;
    }
    if (this.currentPageFirstLineIndex + LINES_PER_PAGE >= this.contentLines.length) {
      Logger.warn(TAG, '已经到最后一页了，不需要再滚动');
      return;
    }
    let lastLine = this.currentPageFirstLineIndex + LINES_PER_PAGE;
    // Logger.info(TAG, `lastLine: ${lastLine}`);
    for (let i = this.currentReadLineIndex; i < lastLine; i++) {
      let lineText = this.contentLines[i].text;
      let findSuccess = lineText.indexOf(result) >= 0;
      //没有完全匹配的情况下，需要看里面是否有3个字符匹配
      if (!findSuccess && result.length >= 3) {
        findSuccess = StringChecker.hasConsecutiveChars(result, lineText);
      }
      Logger.info(TAG, `line: ${i}, text: ${lineText}, findSuccess: ${findSuccess}}`);
      if (findSuccess) {
        this.currentReadLineIndex = i;
        Logger.info(TAG, `语音识别到当前行数: 【${i}】 对应内容:【${this.contentLines[i].text}】`);
        if (i - this.currentPageFirstLineIndex >= LINES_PER_PAGE - COUNT_TO_LAST) {
          this.innerScrollLine(i);
        }
        return;
      }
    }
  }

  build() {
    RelativeContainer() {
      CustomNavigationBar({
        parTitle: $r("app.string.teleprompter"),
        parBGColor: Color.White,
        moreRes: $r('app.media.ic_setting'),
        moreClickCallback: this.btnMoreClickEvent
      }).alignRules({
        top: { anchor: '__container__', align: VerticalAlign.Top }
      }).id('navigationBar')

      Column() {
        Column() {
          //标题
          Text(this.title)
            .fontColor('#8a8a8a')
            .fontSize(16)
            .alignSelf(ItemAlign.Start)
          //日期
          Text(this.timestamp)
            .fontColor('#c1c1c1')
            .fontSize(12)
            .height(20)
        }.id('topContent').width('100%').padding({ left: 25, top: 20, bottom: 25 }).alignItems(HorizontalAlign.Start)

        //内容区域
        Stack({ alignContent: Alignment.BottomStart }) {
          Scroll(this.scrollerForScroll) {
            Text(this.content, { controller: this.contentController })
              .fontColor('#343434')
              .fontSize(16)// .fontFamily('kaishu')
              .lineHeight(LINE_HEIGHT)
              .padding({ left: 25, right: 25 })
              .width('100%')
              .onAreaChange(() => {
                this.onTextAreaChanged();
              })
              .gesture(LongPressGesture({ fingers: 1, repeat: false, duration: 500 }).onAction(() => {
                this.stopSpeedScroll();
                this.stopDynamicScroll();
                router.pushUrl({
                  url: 'pages/TeleprompterEditPage', params: this.teleprompterData
                })
              }))
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