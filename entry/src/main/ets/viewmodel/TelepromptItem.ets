import { systemShare } from "@kit.ShareKit"
import { systemDateTime } from "@kit.BasicServicesKit"
import { TimeUtil } from "../utils/TimeUtil"

export class TelepromptData {
  /**
   * id
   */
  public id: number = systemDateTime.getTime()
  /**
   * 提词器的标题
   */
  public title: string = ''
  /**
   * 提词器的内容
   */
  public content: string = ''
  /**
   * 提词器的日期时间 YYYY/MM/DD HH:MM
   */
  public timestamp: number = 0

  constructor(title: string, content: string, timestamp: number) {
    this.title = title
    this.content = content
    this.timestamp = timestamp
  }

  toString(): string {
    return 'title:' + this.title + " /n" + this.content + " /n" + TimeUtil.formatTimestamp(this.timestamp)
  }
}