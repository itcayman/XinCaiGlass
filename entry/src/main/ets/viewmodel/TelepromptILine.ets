import { systemShare } from "@kit.ShareKit"
import { systemDateTime } from "@kit.BasicServicesKit"
import { TimeUtil } from "../utils/TimeUtil"

export class TelepromptLine {
  public line: number = 0
  public lineHeight: number = 0
  public startIndex: number = 0
  public endIndex: number = 0
  public text: string = ''

  constructor(line: number, lineHeight: number, startIndex: number, endIndex: number, text: string) {
    this.line = line
    this.lineHeight = lineHeight
    this.startIndex = startIndex
    this.endIndex = endIndex
    this.text = text
  }


  toString(): string {
    return 'line:' + this.line + ', lineHeight:' + this.lineHeight + ", startIndex:" + this.startIndex + ", endIndex:" +
    this.endIndex + ", text:" + this.text
  }
}