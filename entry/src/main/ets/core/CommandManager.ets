import { DateTime } from "../viewmodel/DateTime";
import { TransferBLEData } from "../viewmodel/TransferBLEData";
import gattClientManager from "./GattClientManager";
import { buffer } from "@kit.ArkTS";

export const COMMAND_SET_DATETIME = 0x01; //设置日期时间

export const COMMAND_SCROLL_TELEPROMPTER = 0x04; //手机端发送题词

export const COMMAND_SWITCH_PAGE = 0x05; //打开界面

export const ENTER_HOME_VALUE: Uint8Array = new Uint8Array([0x01, 0x02, 0x00, 0x32, 0x00]) // 打开首页

export const ENTER_TELEPROMPTER_VALUE: Uint8Array = new Uint8Array([0x01, 0x02, 0x00, 0x33, 0x00]) // 打开提词


class CommandManager {
  /**
   * 进入首面
   * */
  public static enterHomePage() {
    CommandManager.enterPage(ENTER_HOME_VALUE);
  }

  /**
   * 进入提词器页面
   * */
  public static enterTeleprompterPage() {
    CommandManager.enterPage(ENTER_TELEPROMPTER_VALUE);
  }

  /**
   * 提词器滚动题词
   * */
  public static scrollTeleprompterText(sendText: string) {
    let data: TransferBLEData = new TransferBLEData(COMMAND_SCROLL_TELEPROMPTER, sendText, '');
    gattClientManager.writeCharacteristicValue(data)
  }

  /**
   * 上报日期时间
   * */
  public static reportDateTime(dateTime: DateTime) {
    const valueBuffer = buffer.alloc(8);
    valueBuffer.writeInt16LE(dateTime.year, 0);
    valueBuffer.writeInt8(dateTime.month, 2);
    valueBuffer.writeInt8(dateTime.day, 3);
    valueBuffer.writeInt8(dateTime.hour, 4);
    valueBuffer.writeInt8(dateTime.minute, 5);
    valueBuffer.writeInt8(dateTime.second, 6);
    valueBuffer.writeInt8(dateTime.week, 7);
    let data: TransferBLEData = new TransferBLEData(COMMAND_SET_DATETIME, new Uint8Array(valueBuffer.buffer), '');
    gattClientManager.writeCharacteristicValue(data)
  }

  private static enterPage(tlvValue: Uint8Array) {
    let data: TransferBLEData = new TransferBLEData(COMMAND_SWITCH_PAGE, tlvValue, '', false);
    gattClientManager.writeCharacteristicValue(data)
  }
}

export default CommandManager;