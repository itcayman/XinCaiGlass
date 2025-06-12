import audio from '@ohos.multimedia.audio';
import common from '@ohos.app.ability.common';
import { Logger } from '../utils/Logger';
import { Options } from '@kit.CoreFileKit';

const TAG = '[AudioProcessor]'

export class AudioProcessor {
  private context: common.UIAbilityContext | null = null;
  private audioCapturer: audio.AudioCapturer | null = null;
  private audioStreamInfo: audio.AudioStreamInfo = {
    samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
    channels: audio.AudioChannel.CHANNEL_2,
    sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
    encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
  };
  private pcmDataCallback: ((data: ArrayBuffer, size: number) => void) | null = null;
  private isCapturing: boolean = false;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  public isRecordingAudio(): boolean {
    return this.isCapturing;
  }

  /**
   * 设置音频采集参数
   * @param sampleRate 采样率
   * @param channelCount 声道数
   * @param sampleFormat 采样格式
   */
  public setAudioParams(
    sampleRate: audio.AudioSamplingRate = audio.AudioSamplingRate.SAMPLE_RATE_16000,
    channelCount: audio.AudioChannel = audio.AudioChannel.CHANNEL_1,
    sampleFormat: audio.AudioSampleFormat = audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
    encodingType: audio.AudioEncodingType = audio.AudioEncodingType.ENCODING_TYPE_RAW
  ): void {
    this.audioStreamInfo = {
      samplingRate: sampleRate,
      channels: channelCount,
      sampleFormat: sampleFormat,
      encodingType: encodingType
    };
  }

  /**
   * 设置PCM数据回调函数
   * @param callback 回调函数，接收PCM数据和数据大小作为参数
   */
  public setPcmDataCallback(callback: (data: ArrayBuffer, size: number) => void): void {
    this.pcmDataCallback = callback;
  }

  /**
   * 开始音频采集
   */
  public async startAudioCapture(): Promise<void> {
    if (this.isCapturing) {
      Logger.info(TAG, 'AudioProcessor: 音频采集已在进行中');
      return;
    }

    try {
      // 创建音频采集器配置信息
      const audioCapturerInfo: audio.AudioCapturerInfo = {
        source: audio.SourceType.SOURCE_TYPE_MIC,
        capturerFlags: 0
      };

      const audioCapturerOptions: audio.AudioCapturerOptions = {
        streamInfo: this.audioStreamInfo,
        capturerInfo: audioCapturerInfo
      };

      // 创建音频采集器
      this.audioCapturer = await audio.createAudioCapturer(audioCapturerOptions);
      this.audioCapturer?.on("readData", (buffer: ArrayBuffer) => {
        if (this.pcmDataCallback != null) {
          this.pcmDataCallback(buffer, buffer.byteLength);
        }
      })
      if (!this.audioCapturer) {
        Logger.error(TAG, 'AudioProcessor: 创建音频采集器失败');
        return;
      }

      // 开始采集
      await this.audioCapturer.start();

      this.isCapturing = true;
      Logger.info(TAG, 'AudioProcessor: 音频采集已启动');

      // // 开始读取PCM数据
      // this.readAudioData();
    } catch (error) {
      Logger.error(TAG, `AudioProcessor: 启动音频采集时出错: ${JSON.stringify(error)}`);
      await this.releaseAudioCapturer();
    }
  }

  /**
   * 停止音频采集
   */
  public async stopAudioCapture(): Promise<void> {
    if (!this.isCapturing || !this.audioCapturer) {
      Logger.info(TAG, 'AudioProcessor: 音频采集未在进行中');
      return;
    }

    try {
      await this.audioCapturer.stop();
      this.isCapturing = false;
      Logger.info(TAG, 'AudioProcessor: 音频采集已停止');
    } catch (error) {
      Logger.error(TAG, `AudioProcessor: 停止音频采集时出错: ${JSON.stringify(error)}`);
    } finally {
      await this.releaseAudioCapturer();
    }
  }

  /**
   * 释放音频采集器资源
   */
  private async releaseAudioCapturer(): Promise<void> {
    if (this.audioCapturer) {
      try {
        await this.audioCapturer.release();
      } catch (error) {
        Logger.error(TAG, `AudioProcessor: 释放音频采集器时出错: ${JSON.stringify(error)}`);
      } finally {
        this.audioCapturer = null;
      }
    }
  }

  /**
   * 读取音频数据并通过回调传递给上层
   */
  private async readAudioData(): Promise<void> {
    if (!this.isCapturing || !this.audioCapturer) {
      return;
    }

    try {
      // 获取缓冲区大小
      // const bufferSize = await this.audioCapturer.getBufferSize();
      // const audioBuffer = new ArrayBuffer(bufferSize);

      const readSize = await this.getMinBufferSize();
      // 读取音频数据
      await this.audioCapturer.read(readSize, false).then((audioBuffer) => {
        if (this.pcmDataCallback) {
          // 调用回调函数传递PCM数据
          this.pcmDataCallback(audioBuffer, audioBuffer.byteLength);
        }
      });

      // 继续读取下一块数据
      this.readAudioData();
    } catch (error) {
      Logger.error(TAG, `AudioProcessor: 读取音频数据时出错: ${JSON.stringify(error)}`);
      if (this.isCapturing) {
        // 发生错误时停止采集
        await this.stopAudioCapture();
      }
    }
  }

  /**
   * 计算音频录制的最小缓冲区大小
   * @param sampleRate - 采样率，例如44100Hz
   * @param channelCount - 声道数，1为单声道，2为立体声
   * @param sampleFormat - 采样格式，例如audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE
   * @returns 最小缓冲区大小（字节）
   */
  private async getMinBufferSize(
    sampleRate: audio.AudioSamplingRate = audio.AudioSamplingRate.SAMPLE_RATE_16000,
    channelCount: audio.AudioChannel = audio.AudioChannel.CHANNEL_2,
    sampleFormat: audio.AudioSampleFormat = audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE) {
    // 创建音频采集器实例
    // 创建音频采集器配置信息
    const audioCapturerInfo: audio.AudioCapturerInfo = {
      source: audio.SourceType.SOURCE_TYPE_MIC,
      capturerFlags: 0
    };

    const audioCapturerOptions: audio.AudioCapturerOptions = {
      streamInfo: this.audioStreamInfo,
      capturerInfo: audioCapturerInfo
    };

    const audioCapturer = await audio.createAudioCapturer(audioCapturerOptions);

    // 获取音频帧大小（字节）
    const frameSize = await audioCapturer.getBufferSize();

    // 获取缓冲区持续时间（毫秒）
    const bufferDuration = 20; // 通常使用20ms作为缓冲区持续时间

    // 计算最小缓冲区大小：每秒采样点数 × 每样本字节数 × 缓冲区持续时间（秒）
    const bytesPerSample = this.getBytesPerSample(sampleFormat);
    const minBufferSize = Math.ceil((sampleRate * bytesPerSample * channelCount * bufferDuration) / 1000);

    // 确保缓冲区大小是帧大小的整数倍
    const alignedBufferSize = Math.ceil(minBufferSize / frameSize) * frameSize;

    // 释放资源
    audioCapturer.release();

    return alignedBufferSize;
  }

  /**
   * 获取每个采样的字节数
   */
  private getBytesPerSample(sampleFormat: audio.AudioSampleFormat): number {
    switch (sampleFormat) {
      case audio.AudioSampleFormat.SAMPLE_FORMAT_U8:
        return 1;
      case audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE:
        return 2;
      case audio.AudioSampleFormat.SAMPLE_FORMAT_S24LE:
        return 3;
      case audio.AudioSampleFormat.SAMPLE_FORMAT_S32LE:
      case audio.AudioSampleFormat.SAMPLE_FORMAT_F32LE:
        return 4;
      default:
        return 0;
    }
  }
}