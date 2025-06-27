import fs, { Options, WriteOptions } from '@ohos.file.fs';
import { TimeUnit } from '@ohos/httpclient';
import { Logger } from '../utils/Logger';
import { TimeUtil } from '../utils/TimeUtil';
import { systemShare } from '@kit.ShareKit';
import systemDateTime from '@ohos.systemDateTime';

const TAG = '[PCM]'

export class PCMManager {
  private audioBuffer: ArrayBuffer = new ArrayBuffer(1280 * 10);
  private bufferSize: number = 0;
  private file: fs.File | undefined;

  public createPCMFile() {
    Logger.error(TAG, `创建pcm文件}`)
    let path = getContext().cacheDir;
    let filePath = path + '/' + TimeUtil.getFileName(systemDateTime.getTime()) + '.pcm';
    this.file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
  }

  public writePCMData(buffer: ArrayBuffer) {
    if (this.file == undefined) {
      return;
    }
    // Logger.debug(TAG, `采集到音频数据，size:${buffer.byteLength}, 总size: ${this.bufferSize}}`)
    let options: WriteOptions = {
      offset: this.bufferSize,
      length: buffer.byteLength
    }
    fs.writeSync(this.file?.fd, buffer, options);
    this.bufferSize += buffer.byteLength;
  }

  public done() {
    if (this.file == undefined) {
      return;
    }
    Logger.error(TAG, `完成pcm数据写入}`)
    try {
      fs.closeSync(this.file?.fd);
    } catch (err) {
    }
    this.file = undefined;
  }
}