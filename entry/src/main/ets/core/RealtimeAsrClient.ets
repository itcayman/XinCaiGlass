import { Logger } from "../utils/Logger";
import { AudioProcessor } from "./AudioProcessor";
import { WebsocketManager, WebSocketMessageType } from "./WebsocketManager";
import { common } from "@kit.AbilityKit";
import { ByteUtil } from "../utils/ByteUtil";
import { isBlank } from "../utils/StringUtil";
import { PCMManager } from "./PCMManager";

interface Transcription {
  model: string
}

interface Session {
  "input_audio_format": string, //输入的音频格式。目前仅支持 pcm 格式。
  "input_audio_codec": string, //输入的音频编码格式。
  "input_audio_sample_rate": number, //输入的音频采样率。
  "input_audio_bits": number, //输入的音频采样位宽。
  "input_audio_channel": number, //输入的音频声道数。
  "input_audio_transcription": Transcription //语音识别的其他配置。
}

interface SessionConfig {
  type: string,
  session: Session
}

interface AudioBuffer {
  'type': string,
  'audio': string
}

interface Word {
  start: number,
  end: number,
  word: string
}

interface AudioTranscriptionResult {
  'type': string,
  'event_id': string,
  "item_id": string,
  'transcript': string,
  'words': Word[]
}

const TAG = '[RealtimeASR]'

/**
 * 豆包语音识别连接管理类
 * https://www.volcengine.com/docs/6893/1527759#client-event-1
 */
export class RealtimeAsrManager {
  private context = getContext(this) as common.UIAbilityContext;
  private websocketManager = new WebsocketManager()
  private audioProcessor = new AudioProcessor(this.context)
  private sessionChecked = false
  private lastResultText = ''
  private pcm = new PCMManager();
  private onConnectSuccessCallback: Callback<void> | undefined;
  private onTranscriptionCallback: Callback<string> | undefined;

  constructor() {
    this.initAudioProcessor();

    this.websocketManager.setOnOpenCallback(() => {
      this.sendSessionConfig()
    });
    this.websocketManager.setOnMessageCallback((data: string | ArrayBuffer, type: WebSocketMessageType) => {
      switch (type) {
        case WebSocketMessageType.TEXT:
          const jsonObj: SessionConfig | AudioTranscriptionResult = JSON.parse(data as string);
          this.handleServerResult(jsonObj);
          break;
        case WebSocketMessageType.BINARY:
          break;
      }
    })
  }

  public setConnectSuccessCallback(callback: Callback<void> | undefined) {
    this.onConnectSuccessCallback = callback;
  }

  public setTranscriptionCallback(callback: Callback<string> | undefined) {
    this.onTranscriptionCallback = callback;
  }

  public connect() {
    this.websocketManager.connect('wss://ai-gateway.vei.volces.com/v1/realtime?model=bigmodel');
  }

  public startAudioCapture() {
    this.pcm.createPCMFile();
    this.audioProcessor.startAudioCapture();
  }

  public stopAudioCapture() {
    this.pcm.done();
    this.audioProcessor.stopAudioCapture();
  }

  public complete() {
    Logger.info(TAG, '结束此次语音识别...');
    let data = '{"type": "input_audio_buffer.commit"}';
    this.websocketManager.sendTextMessage(data);
  }

  public isRecordingAudio(): boolean {
    return this.audioProcessor.isRecordingAudio();
  }

  reset() {
    this.sessionChecked = false;
    this.websocketManager.close()
  }

  private handleServerResult(result: SessionConfig | AudioTranscriptionResult) {
    switch (result.type) {
      case 'transcription_session.updated':
        Logger.debug(TAG, `服务端确认session配置`)
        this.sessionChecked = true;
        this.onConnectSuccessCallback?.();
        break;
      case 'conversation.item.input_audio_transcription.result':
        let transcriptionResult = (result as AudioTranscriptionResult).transcript;
        // Logger.debug(TAG, `服务端语音识别结果: ${transcriptionResult}`)
        if (isBlank(transcriptionResult)) {
          return;
        }
        transcriptionResult = transcriptionResult.replaceAll(RegExp("[,，.。！]", "g"), '|')
        Logger.debug(TAG, `转化后结果: ${transcriptionResult}`)
        let text = transcriptionResult;
        if (transcriptionResult.indexOf('|') >= 0) {
          let splits = transcriptionResult.split('|');
          // Logger.debug(TAG, `splits length:${splits.length},splits: ${splits}`);
          text = splits[Math.max(splits.length - 1, 0)];
          // Logger.debug(TAG, `text: ${text}`);
        }
        if (text == 'undefined' || isBlank(text)) {
          return;
        }
        if (this.lastResultText == text) {
          return;
        }
        this.lastResultText = text;
        Logger.debug(TAG, `最终识别结果:${text}`)
        this.onTranscriptionCallback?.(text);
        break;
      case 'conversation.item.input_audio_transcription.completed':
        Logger.debug(TAG, `服务端确认完成此次语音识别`)
        break;
    }
  }

  private initAudioProcessor() {
    this.audioProcessor.setAudioParams();
    this.audioProcessor.setPcmDataCallback((buffer: ArrayBuffer, size: number) => {
      this.sendAudioData(buffer);
      this.pcm.writePCMData(buffer);
    })
  }

  private sendSessionConfig() {
    let config: SessionConfig = {
      "type": "transcription_session.update",
      "session": {
        "input_audio_format": "pcm",
        "input_audio_codec": "raw",
        "input_audio_sample_rate": 16000,
        "input_audio_bits": 16,
        "input_audio_channel": 1,
        "input_audio_transcription": {
          "model": "bigmodel"
        }
      }
    };
    let configStr = JSON.stringify(config)
    this.websocketManager.sendTextMessage(configStr)
  }

  public sendAudioData(audio: ArrayBuffer) {
    if (!this.sessionChecked) {
      Logger.error(TAG, '服务端未确认session配置!!!')
      return;
    }
    let audioData: AudioBuffer = {
      'type': 'input_audio_buffer.append',
      'audio': ByteUtil.base64EncodeToStringNoWrap(audio)
    };
    // Logger.debug(TAG, `发送文本消息: ${audio.byteLength}`);
    this.websocketManager.sendTextMessage(JSON.stringify(audioData));
  }
}
