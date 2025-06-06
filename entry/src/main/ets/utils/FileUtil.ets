import { Logger } from "./Logger";
import fs from '@ohos.file.fs';

const TAG: string = '[FileUtil]';

export class FileUtil {
  static getFileNameFromUri(uri: string): string {
    try {
      // 处理file://格式的URI，提取实际文件路径
      let filePath = uri;
      if (uri.startsWith('file://')) {
        filePath = uri.substring(7); // 移除"file://"前缀
      }

      // 获取路径中的最后一部分作为文件名
      const segments = filePath.split('/');
      let file = segments.pop() || null;
      if (file != null && file.indexOf('.') > 0) {
        const fileSegments = file.split('.');
        fileSegments.pop();
        return fileSegments.pop() || uri;
      }
      return uri;
    } catch (error) {
      Logger.error(TAG, `获取文件名失败: ${JSON.stringify(error)}`);
      return uri;
    }
  }

  static getPathFromUri(uri: string): string {
    let filePath = uri;
    if (uri.startsWith('file://docs')) {
      return uri.substring(11); // 移除"file://docs"前缀
    }
    return uri;
  }

}