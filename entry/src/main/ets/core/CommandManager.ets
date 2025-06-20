import { DateTime } from "../viewmodel/DateTime";
import { TransferBLEData } from "../viewmodel/TransferBLEData";
import { buffer } from "@kit.ArkTS";
import ProtocolPacket from "./ProtocolPacket";
import { Logger } from "../utils/Logger";
import { GattClientManager } from "./GattClientManager";

export enum Command {
  SET_DATETIME = 0x01, //设置日期时间
  SET_TELEPROMPTER = 0x04, //手机端发送题词
  SET_PAGE = 0x05, //打开界面
  SEND_TRANSLATE = 0x07, //发送翻译结果
  SEND_AI = 0x08, //发送AI结果
  SET_MIC = 0x09, //设置mic
  REMOTE_CONTROL = 0x82, //遥控器
  DOUBLE_CLICK = 0x86 //双击操作
}

export enum RemoteControl {
  NULL = 0x00,
  NEXT = 0x09, //按键下
  PREV = 0x0B, //按键上
  ENTER = 0x0A, //按键确定
  RIGHT = 0x13, //按键右
  LEFT = 0x14, //按键左
  ESC = 0x1B //按键返回
}

export enum DoubleClick {
  DEFAULT = 0,
  START = 1, //开始
  STOP = 2, //停止
  CLOSE = 3, //关闭
  ERROR = -1 //错误
}

export const ENTER_HOME_VALUE: Uint8Array = new Uint8Array([0x01, 0x02, 0x00, 0x32, 0x00]); // 打开首页

export const ENTER_TELEPROMPTER_VALUE: Uint8Array = new Uint8Array([0x01, 0x02, 0x00, 0x33, 0x00]); // 打开提词

export const ENTER_TRANSLATE_VALUE: Uint8Array = new Uint8Array([0x01, 0x02, 0x00, 0x3A, 0x00]); //打开翻译

export const ENTER_AI_VALUE: Uint8Array = new Uint8Array([0x01, 0x02, 0x00, 0x35, 0x00]); //打开AI

export const OPEN_MIC_VALUE: Uint8Array = new Uint8Array([0x01, 0x02, 0x00, 0x00, 0x00]); //打开mic

export const CLOSE_MIC_VALUE: Uint8Array = new Uint8Array([0x02, 0x02, 0x00, 0x00, 0x00]); //关闭mic

const TAG = '[CommandManager]'

export class CommandManager {
  private gattClient: GattClientManager;
  private remoteControlCallback: Array<Callback<RemoteControl>> = new Array();
  private doubleClickCallback: Array<Callback<DoubleClick>> = new Array();

  constructor(gattClient: GattClientManager) {
    this.gattClient = gattClient;
    this.gattClient.setNormalCallback((data: TransferBLEData) => {
      let tlvValue = data.tlvValue as Uint8Array;
      let second = ProtocolPacket.decodeTlvValue(tlvValue);
      switch (data.cmd) {
        case Command.REMOTE_CONTROL:
          Logger.info(TAG, `收到遥控器事件: ${second.tlvValue[0]}`);
          this.remoteControlCallback.forEach((item) => {
            item(second.tlvValue[0]);
          })
          break;
        case Command.DOUBLE_CLICK:
          Logger.info(TAG, `收到眼镜双击事件: ${second.tlvValue[0]}`);
          this.doubleClickCallback.forEach((item) => {
            item(second.tlvValue[0])
          })
          break;
      }
    })
  }

  public addRemoteControlCallback(callback: Callback<RemoteControl>) {
    this.remoteControlCallback.push(callback);
  }

  public removeRemoteControlCallback(callback: Callback<RemoteControl>) {
    const index = this.remoteControlCallback.indexOf(callback);
    if (index >= 0) {
      this.remoteControlCallback.splice(index, 1);
    }
  }

  public addDoubleCallback(callback: Callback<DoubleClick>) {
    this.doubleClickCallback.push(callback);
  }

  public removeDoubleCallback(callback: Callback<DoubleClick>) {
    const index = this.doubleClickCallback.indexOf(callback);
    if (index >= 0) {
      this.doubleClickCallback.splice(index, 1);
    }
  }

  /**
   * 进入首面
   * */
  public enterHomePage() {
    this.enterPage(ENTER_HOME_VALUE);
  }

  /**
   * 进入提词器页面
   * */
  public enterTeleprompterPage() {
    this.enterPage(ENTER_TELEPROMPTER_VALUE);
  }

  /**
   * 进入AI页面
   * */
  public enterAIPage() {
    this.enterPage(ENTER_AI_VALUE);
  }

  /**
   * 进入翻译官页面
   * */
  public enterTranslatePage() {
    this.enterPage(ENTER_TRANSLATE_VALUE);
  }

  /**
   * 进入翻译官页面
   * */
  public enterMeetingAssistant() {
    this.enterPage(ENTER_TRANSLATE_VALUE);
  }

  /**
   * 提词器滚动题词
   * */
  public scrollTeleprompterText(sendText: string) {
    let data: TransferBLEData = new TransferBLEData(Command.SET_TELEPROMPTER, sendText, '');
    this.gattClient.sendNormalData(data)
  }

  /**
   * 打开眼镜mic
   * */
  public openMic() {
    Logger.info(TAG, '打开眼镜端mic')
    let data: TransferBLEData = new TransferBLEData(Command.SET_MIC, OPEN_MIC_VALUE, '');
    this.gattClient.sendNormalData(data)
  }

  /**
   * 关闭眼镜mic
   * */
  public closeMic() {
    Logger.info(TAG, '关闭眼镜端mic')
    let data: TransferBLEData = new TransferBLEData(Command.SET_MIC, CLOSE_MIC_VALUE, '');
    this.gattClient.sendNormalData(data)
  }

  /**
   * 发送AI响应结果
   * */
  public sendAIResponse(sendText: string) {
    Logger.info(TAG, '发送AI结果:' + sendText);
    let data: TransferBLEData = new TransferBLEData(Command.SEND_AI, sendText, '');
    this.gattClient.sendNormalData(data)
  }

  /**
   * 上报日期时间
   * */
  public reportDateTime(dateTime: DateTime) {
    const valueBuffer = buffer.alloc(8);
    valueBuffer.writeInt16LE(dateTime.year, 0);
    valueBuffer.writeInt8(dateTime.month, 2);
    valueBuffer.writeInt8(dateTime.day, 3);
    valueBuffer.writeInt8(dateTime.hour, 4);
    valueBuffer.writeInt8(dateTime.minute, 5);
    valueBuffer.writeInt8(dateTime.second, 6);
    valueBuffer.writeInt8(dateTime.week, 7);
    let data: TransferBLEData = new TransferBLEData(Command.SET_DATETIME, new Uint8Array(valueBuffer.buffer), '');
    this.gattClient.sendNormalData(data)
  }

  private enterPage(tlvValue: Uint8Array) {
    let data: TransferBLEData = new TransferBLEData(Command.SET_PAGE, tlvValue, '', false);
    this.gattClient.sendNormalData(data)
  }
}
