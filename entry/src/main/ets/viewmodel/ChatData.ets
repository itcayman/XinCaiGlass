export class ChatData {
  public type: Role = Role.ME;
  public text: string | ResourceStr = '';
  public time: number = 0

  constructor(type: Role, text: string | ResourceStr, time: number) {
    this.type = type;
    this.text = text;
    this.time = time;
  }

  public isMe() {
    return this.type == Role.ME;
  }
}

export enum Role {
  ME,
  AI
}