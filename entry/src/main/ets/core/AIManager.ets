import { Logger } from "../utils/Logger";
import { CommandManager, DoubleClick } from "./CommandManager";
import { GattClientManager } from "./GattClientManager";
import { RealtimeAsrManager } from "./RealtimeAsrClient";
import systemDateTime from "@ohos.systemDateTime";
import { DynamicArrayBuffer } from "../viewmodel/DynamicArrayBuffer";
import { PCMManager } from "./PCMManager";
import aiHttpRequest from "../network/AIHttpRequest";
import { ChatResponse, Choice } from "../viewmodel/ChatResponse";
import { isBlank } from "../utils/StringUtil";

const TAG = '[AI]'

export class AIManager {
  private command: CommandManager;
  private realtimeASR: RealtimeAsrManager;
  private gattClient: GattClientManager;
  private pcm = new PCMManager();
  private glassAIOpened = false;
  private asrResult = '';
  private waitingAnswer = false;
  private audioCallback: Callback<ArrayBuffer> | undefined;
  private doubleClickCallback = (data: DoubleClick) => {
    switch (data) {
      case DoubleClick.DEFAULT:
        if (this.glassAIOpened) {
          this.stopGlassAI();
        } else {
          this.startGlassAI();
        }
        this.glassAIOpened = !this.glassAIOpened;
        break;
    }
  }

  constructor(command: CommandManager, realtimeASR: RealtimeAsrManager, gattClient: GattClientManager) {
    this.command = command;
    this.realtimeASR = realtimeASR;
    this.gattClient = gattClient;
    this.command.addDoubleCallback(this.doubleClickCallback)

    this.realtimeASR.addTranscriptionCallback((result) => {
      this.asrResult = result;
      Logger.info(TAG, `语音识别结果: ${result}`);
    })
    this.realtimeASR.setConnectSuccessCallback(() => {
      // this.realtimeASR.startAudioCapture();
    })
  }

  private startGlassAI() {
    this.realtimeASR.connect();
    // this.pcm.createPCMFile();
    let buffer = new DynamicArrayBuffer();
    let lastTime = systemDateTime.getTime();

    this.audioCallback = (data: ArrayBuffer) => {
      // Logger.info(TAG, '===============收到音频通知，数据长度:' + characteristic.characteristicValue.byteLength);\
      let current = systemDateTime.getTime();
      buffer.append(data);
      if (current - lastTime >= 500) {
        // Logger.info(TAG, `积累到100个包长度 ${buffer.length}，发送音频数据进行识别...`);
        Logger.info(TAG, `发送长度 ${buffer.length}，发送音频数据进行识别...`);
        this.realtimeASR.sendAudioData(buffer.getBuffer());
        buffer = new DynamicArrayBuffer();
        lastTime = current;
      }
      this.pcm.writePCMData(data);
    }
    this.gattClient.addAudioCallback(this.audioCallback);
    this.command.enterAIPage();
    this.command.openMic();
    // this.asrResult = '南昌今天天气怎么样';
    // this.askAI();
  }

  private stopGlassAI() {
    this.gattClient.removeAudioCallback(this.audioCallback!);
    // this.pcm.done();
    this.command.closeMic();
    if (this.asrResult == '返回' || this.asrResult == '回到主界面') {
      this.command.enterHomePage();
    } else if (!isBlank(this.asrResult)) {
      // this.askAIByStream();
      this.askAI();
      this.asrResult = '';
    }
  }

  private askAI() {
    const text = this.asrResult + '(请用简短话语回答)';
    // const text = this.asrResult;
    Logger.info(TAG, '向AI提问:' + text);
    aiHttpRequest.aiChatWithText(text).then((result: ChatResponse) => {
      let choiceArray: Array<Choice> | undefined = result.choices;
      Logger.info(TAG, 'AI响应1:' + choiceArray?.length);
      if (choiceArray && choiceArray[0].message) {
        this.command.sendAIResponse(choiceArray[0].message?.content)
      }
    });
  }

  private askAIByStream() {
    aiHttpRequest.aiChatWithTextByStream((result: ChatResponse) => {
      // Logger.info(TAG, 'AI响应:'+result.toString());
      let choiceArray: Array<Choice> | undefined = result.choices;
      if (choiceArray) {
        Logger.info(TAG, 'AI响应2');
        let choice = choiceArray.pop();
        if (choice && choice.delta) {
          this.command.sendAIResponse(choice.delta.content);
        }
      } else {
        Logger.error(TAG, '语音识别结束');
        this.waitingAnswer = false;
      }
    }, this.asrResult);
  }
}