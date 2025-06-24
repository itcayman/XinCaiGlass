export class TeleprompterSpeed {
  scrollOnePageTime: number = 0
  desc: string | ResourceStr = ''
  selected: boolean = false

  constructor(scrollOnePageTime: number, desc: string | ResourceStr, selected: boolean = false) {
    this.scrollOnePageTime = scrollOnePageTime
    this.desc = desc
    this.selected = selected
  }
}