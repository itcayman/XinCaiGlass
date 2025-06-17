import { TimeUtil } from '../utils/TimeUtil';
import { ChatData, Role } from '../viewmodel/ChatData';
import systemDateTime from '@ohos.systemDateTime';
import { DevicesUtil } from '../utils/DevicesUtil';
import { ResourceUtil } from '../utils/ResourceUtil';
import { AIAssistantBottomView } from './AIAssistantBottomView';
import aiHttpRequest from '../network/AIHttpRequest';
import { ChatResponse, Choice } from '../viewmodel/ChatResponse';
import { Logger } from '@ohos/httpclient';

const TAG = '[AIAssistant]'

@Component
export struct AIAssistantContent {
  private scrollerForList: Scroller = new Scroller()
  @State message: string = 'Hello World';
  @State data: Array<ChatData> = new Array();
  private waitingAnswer: boolean = false;
  private callback: Callback<string> = (value) => this.sendMessageToAI(value);

  aboutToAppear(): void {
    // this.data.push(new ChatData(Role.ME, '今天南昌天气怎么样', systemDateTime.getTime()))
    // this.data.push(new ChatData(Role.AI, '思考中...', systemDateTime.getTime()))
    // this.data.push(new ChatData(Role.AI,
    //   '今日（2025年6月17日）南昌天气晴，气温25℃到32℃，白天和夜间均为西南风1级，湿度80%。你今天出行可以做好防晒措施哦，相信这样美好的天气会让你有超棒的心情！',
    //   systemDateTime.getTime()))
  }

  private sendMessageToAI(message: string) {
    if (this.waitingAnswer) {
      Logger.warn(TAG, '正在等待AI回答的结果...');
      return;
    }
    this.waitingAnswer = true;
    this.createAskItem(message);
    this.createAIItem();
    this.scrollerForList.scrollEdge(Edge.Bottom);
    let aiResult = '';
    aiHttpRequest.aiChatWithTextByStream((result: ChatResponse) => {
      let choiceArray: Array<Choice> | undefined = result.choices;
      let targetIndex = this.data.length - 1;
      let target = this.data[targetIndex];
      if (choiceArray) {
        let choice = choiceArray.pop();
        if (choice) {
          aiResult += choice?.delta?.content;
          this.data[targetIndex] = new ChatData(target.type, aiResult, systemDateTime.getTime());
        }
      } else {
        Logger.error(TAG, '语音识别结束');
        this.waitingAnswer = false;
      }
      this.scrollerForList.scrollEdge(Edge.Bottom);
    }, message);
  }

  private createAskItem(text: string) {
    this.data.push(new ChatData(Role.ME, text, systemDateTime.getTime()));
  }

  private createAIItem() {
    this.data.push(new ChatData(Role.AI, $r('app.string.ai_wait_answer'), systemDateTime.getTime()));
  }

  @Builder
  private mineAskViewBuilder(item: ChatData) {
    Column() {
      Column() {
        Text(item.text).fontSize(15).margin({ bottom: 10 }).lineHeight(20)
        Text(TimeUtil.formatTimestamp(item.time, true)).fontSize(13)
      }
      .borderRadius(10)
      .padding(ResourceUtil.getCommonPadding()[1])
      .backgroundColor($r('app.color.ai_item_ask_background'))
      .alignItems(HorizontalAlign.Start)
    }.width('100%').alignItems(HorizontalAlign.End)
  }

  @Builder
  private aiAnswerViewBuilder(item: ChatData) {
    Column() {
      Column() {
        Text(item.text).fontSize(15).margin({ bottom: 10 }).lineHeight(20)
        Text(TimeUtil.formatTimestamp(item.time, true)).fontSize(13)
      }
      .borderRadius(10)
      .padding(ResourceUtil.getCommonPadding()[1])
      .backgroundColor($r('app.color.ai_item_answer_background'))
      .alignItems(HorizontalAlign.Start)
    }.width('100%').alignItems(HorizontalAlign.Start)
  }

  build() {
    RelativeContainer() {
      Row() {
        Text().height(1).layoutWeight(1)
        Image($r('app.media.ic_public_history'))
          .width(ResourceUtil.getCommonImgSize()[2])
          .height(ResourceUtil.getCommonImgSize()[2])
      }
      .id('topLayout')
      .width('100%')
      .height(50)
      .margin({
        top: DevicesUtil.statusBarHeight,
      })
      .alignRules({ right: { anchor: '__container__', align: HorizontalAlign.End } })

      List({ space: 15, initialIndex: 0, scroller: this.scrollerForList }) {
        ForEach(this.data, (item: ChatData) => {
          ListItem() {
            if (item.isMe()) {
              this.mineAskViewBuilder(item);
            } else {
              this.aiAnswerViewBuilder(item);
            }
          }
        })
      }
      .width('100%')
      .height(LayoutPolicy.matchParent)
      .scrollBar(BarState.Off)
      .alignRules({
        top: { anchor: 'topLayout', align: VerticalAlign.Bottom },
        bottom: { anchor: 'bottomLayout', align: VerticalAlign.Top }
      })

      AIAssistantBottomView({ callback: this.callback })
        .id('bottomLayout')
        .alignRules({
          bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
        })
    }
    .padding({ left: ResourceUtil.getCommonPadding()[0], right: ResourceUtil.getCommonPadding()[0] })
    .height('100%')
    .width('100%')
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }
}