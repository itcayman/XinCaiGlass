import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { PermissionUtil } from '../utils/PermissionUtil';
import { BusinessError } from '@kit.BasicServicesKit';
import { WriteOptions } from '@kit.CoreFileKit';

@Entry
@Component
struct PcmFileWriter {
  @State filePath: string = '';
  private context = getContext(this) as common.UIAbilityContext;

  aboutToAppear(): void {
    PermissionUtil.init(getContext(this))
      .addPermissions('ohos.permission.READ_WRITE_USER_FILE')
      .request()
      .then((result) => {
      })
      .catch((error: BusinessError) => {
        console.error(JSON.stringify(error))
      })
  }

  build() {
    Column() {
      Button('保存PCM文件')
        .onClick(() => this.savePcmData(this.generateSamplePcmData(44100, 5)))

      Text(this.filePath)
        .margin(10)
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }

  // 生成示例PCM数据（5秒的正弦波）
  private generateSamplePcmData(sampleRate: number, duration: number): ArrayBuffer {
    const sampleCount = sampleRate * duration;
    const pcmData = new Int16Array(sampleCount);
    const frequency = 440; // 440Hz 标准A音

    for (let i = 0; i < sampleCount; i++) {
      const amplitude = 32767 * 0.5; // 50%音量
      const time = i / sampleRate;
      pcmData[i] = Math.floor(amplitude * Math.sin(2 * Math.PI * frequency * time));
    }

    return pcmData.buffer;
  }

  // 保存PCM数据到沙盒文件
  savePcmData(pcmBuffer: ArrayBuffer) {
    try {
      // 检查并申请权限

      // 创建唯一文件名
      const fileName = `audio_${new Date().getTime()}.pcm`;
      const filePath = `${this.context.filesDir}/${fileName}`;

      // 打开文件流
      const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);

      // 写入PCM数据
      const uint8Array = new Uint8Array(pcmBuffer);
      let options: WriteOptions = {
        offset: 0,
        length: pcmBuffer.byteLength
      }
      fs.writeSync(file.fd, pcmBuffer, options);
      // fs.writeSync(file.fd, 'adfasdfasdfasdfadf');

      // 关闭文件
      fs.closeSync(file);

      // 更新UI显示文件路径
      this.filePath = `文件已保存: ${fileName}`;
      promptAction.showToast({ message: '保存成功' });

      console.info(`PCM文件已保存至: ${filePath}`);
    } catch (error) {
      console.error(`保存PCM文件失败: ${JSON.stringify(error)}`);
      promptAction.showToast({ message: `保存失败: ${error.message}` });
    }
  }
}