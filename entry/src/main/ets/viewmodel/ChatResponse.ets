import { Expose } from 'class-transformer'
import 'reflect-metadata'

export class ChatResponse {
  public id: string = '';
  @Expose({ name: 'object' })
  public objectType: string = '';
  public created: number = 0;
  public model: string = '';
  public choices: Array<Choice> | undefined;
  public usage: Usage | undefined;
  public systemFingerprint: string | undefined;

  toString(): string {
    return `{id:${this.id}, objectType:${this.objectType}, created:${this.created}, model:${this.model},
    choices:${this.choices?.toString()}, useage:${this.usage}, systemFingerprint:${this.systemFingerprint}}`;
  }
}

export class Choice {
  public index: number = 0;
  public message: Message | undefined;
  @Expose({ name: 'finish_reason' })
  public finishReason: string = '';
  public delta: Delta | undefined;

  toString(): string {
    return `{"index":${this.index}, "delta":${this.delta?.toString()}`;
  }
}

export class Message {
  public role: string = '';
  public content: string = '';
}

export class Delta {
  public content: string = '';

  toString(): string {
    return `{"content":${this.content}}`;
  }
}


export class Usage {
  @Expose({ name: 'prompt_tokens' })
  public promptTokens: number = 0;
  @Expose({ name: 'completion_tokens' })
  public completionTokens: number | undefined;
  @Expose({ name: 'total_tokens' })
  public totalTokens: number = 0;
}

