import fs from '@ohos.file.fs';
import preferences from '@ohos.data.preferences';
import { CMGDeviceInfo } from '../viewmodel/CMGDeviceInfo';
import { ValueType } from '@kit.ArkData';
import { TeleprompterConfig } from '../viewmodel/config/TeleprompterConfig';
import { isBlank } from '../utils/StringUtil';
import { plainToInstance } from 'class-transformer';

const KEY_DEVICE_INFO = 'DEVICE_INFO';
const KEY_TELEPROMPTER_CONFIG = 'TELEPROMPTER_CONFIG';

export class LocalDataManager {
  private preferences: preferences.Preferences | undefined

  public init(context: Context) {
    let option: preferences.Options = {
      name: 'cmg'
    }
    this.preferences = preferences.getPreferencesSync(context, option)
  }

  public getDeviceInfo(): CMGDeviceInfo | undefined {
    let jsonData = this.preferences?.getSync(KEY_DEVICE_INFO, '') as string;
    if (isBlank(jsonData)) {
      return undefined;
    }
    return plainToInstance(CMGDeviceInfo, JSON.parse(jsonData))
  }

  public getTeleprompterConfig(): TeleprompterConfig | undefined {
    let jsonData = this.preferences?.getSync(KEY_TELEPROMPTER_CONFIG, '') as string
    if (isBlank(jsonData)) {
      return undefined;
    }
    return plainToInstance(TeleprompterConfig, JSON.parse(jsonData))
  }

  public updateDeviceInfo(info: CMGDeviceInfo) {
    this.putSync(KEY_DEVICE_INFO, JSON.stringify(info));
  }

  public updateTeleprompterConfig(config: TeleprompterConfig) {
    this.putSync(KEY_TELEPROMPTER_CONFIG, JSON.stringify(config))
  }

  private putSync(key: string, value: ValueType) {
    this.preferences?.putSync(key, value);
    this.preferences?.flushSync();
  }
}