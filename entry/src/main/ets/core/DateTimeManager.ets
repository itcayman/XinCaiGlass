import { systemDateTime } from "@kit.BasicServicesKit";
import { TimeUtil } from "../utils/TimeUtil";
import CommandManager from "./CommandManager";

const TAG: string = '[JVC]DateTimeManager'

export class DateTimeManager {
  private timer: number | null = null
  private lastMinute: number = 0

  start() {
    console.log(TAG, '启动时间上报...')
    this.timer = setInterval(() => {
      let dateTime = TimeUtil.getCurrentDateTime()
      if (dateTime.minute != this.lastMinute) {
        this.lastMinute = dateTime.minute
        CommandManager.reportDateTime(dateTime)
      }
    }, 1000);
  }

  stop() {
    console.log(TAG, '停止时间上报...')
    clearInterval(this.timer)
  }
}

let dateTimeManager = new DateTimeManager()

export default dateTimeManager as DateTimeManager