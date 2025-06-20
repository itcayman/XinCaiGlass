import { http } from '@kit.NetworkKit';
import { Logger } from '../utils/Logger';
import { BusinessError } from '@ohos.base';
import { plainToClass, plainToInstance } from 'class-transformer'
import { ChatResponse } from '../viewmodel/ChatResponse';
import buffer from '@ohos.buffer';
import call from '@ohos.telephony.call';
import json from '@ohos.util.json';
import { JSON } from '@kit.ArkTS';
import { isBlank } from '../utils/StringUtil';

const TAG = '[HttpRequest]'
const OK = 200
const DEFAULT_MODEL = '7514517924820975651'
const CHAT_URL = 'https://ai-gateway.vei.volces.com/v1/chat/completions';
const AI_API_KEY = 'sk-282ef4a97b964f17b331f152955c3ce8238nzue7rf65kpcq'

export class AIHttpRequest {
  constructor() {
    // this.client = new HttpClient.Builder()
    //   .setConnectTimeout(60, TimeUnit.SECONDS)
    //   .setReadTimeout(60, TimeUnit.SECONDS)
    //   .setWriteTimeout(60, TimeUnit.SECONDS)
    //   .build();
  }

  public aiChatWithText(text: string, temperature: number = 0.7, maxTokens: number = 300,
    model: string = DEFAULT_MODEL): Promise<ChatResponse> {
    return new Promise<ChatResponse>((resolve, reject) => {
      Logger.info(TAG, `aiChatWithText, text: ${text}`)
      let requestOption: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: { "Content-Type": "application/json", "Authorization": `Bearer ${AI_API_KEY}` },
        extraData: {
          "model": model,
          "messages": [{
            "role": "user",
            "content": [{ "type": "text", "text": text }]
          }],
          "temperature": temperature,
          "stream": false,
          "max_tokens": maxTokens
        },
        expectDataType: http.HttpDataType.STRING
      };
      let request = http.createHttp()
      request.request(CHAT_URL, requestOption).then((value: http.HttpResponse) => {
        Logger.info(TAG, `result, text: ${value.result}`)
        if (value.responseCode === http.ResponseCode.OK) {
          let obj = JSON.parse(value.result as string) as ChatResponse
          resolve(obj)
        } else {
          // serverData.msg = `${$r('app.string.http_error_message')}&${value.responseCode}`
          reject({})
        }
      })
    });
  }

  public aiChatWithTextByStream(callback: Callback<ChatResponse>, text: string, temperature: number = 0.7,
    maxTokens: number = 300,
    model: string = DEFAULT_MODEL) {
    Logger.info(TAG, `aiChatWithTextByStream, text: ${text}`)
    let requestOption: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: { "Content-Type": "application/json", "Authorization": `Bearer ${AI_API_KEY}` },
      extraData: {
        "model": model,
        "messages": [{
          "role": "user",
          "content": [{ "type": "text", "text": text }]
        }],
        "temperature": temperature,
        "stream": true,
        "max_tokens": maxTokens
      },
      expectDataType: http.HttpDataType.STRING
    };
    let request = http.createHttp()
    request.on('dataReceive', (data: ArrayBuffer) => {
      let result = this.processStreamData(data);
      result.forEach((item) => {
        callback(item)
      })
    });
    request.requestInStream(CHAT_URL, requestOption)
  }

  /**
   * 解析流式请求返回的数据
   * @param data 服务端返回的数据流
   * @returns
   * */
  private processStreamData(data: ArrayBuffer): Array<ChatResponse> {
    let str = buffer.from(data).toString('utf-8');
    let result = new Array<ChatResponse>()
    if ('[DONE]' == str) {
      result.push(new ChatResponse())
      return result;
    }
    let lines = str.split('data:')
    // Logger.info(TAG, 'lines:' + lines.length);
    try {
      for (let i = 0; i < lines.length; i++) {
        let jsonData = lines[i];
        if (isBlank(jsonData)) {
          continue;
        }
        if ('[DONE]' == str || ' [DONE]' == str) {
          result.push(new ChatResponse())
          return result;
        }
        // Logger.info(TAG, 'line data:' + jsonData);

        let jsonObj = JSON.parse(jsonData);
        let responseItem = plainToInstance(ChatResponse, jsonObj);
        result.push(responseItem);
      }
    } catch (err) {
      Logger.error(TAG, 'text:' + str);
    }
    return result;
  }
}

let aiHttpRequest = new AIHttpRequest();

export default aiHttpRequest as AIHttpRequest;