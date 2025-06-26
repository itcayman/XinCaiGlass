import fs from '@ohos.file.fs';
import preferences from '@ohos.data.preferences';
import { CMGDeviceInfo } from '../viewmodel/CMGDeviceInfo';
import { ValueType } from '@kit.ArkData';

const KEY_DEVICE_INFO = 'DEVICE_INFO';

export class LocalDataManager {
  private preferences: preferences.Preferences | undefined

  public init(context: Context) {
    let option: preferences.Options = {
      name: 'cmg'
    }
    this.preferences = preferences.getPreferencesSync(context, option)
  }

  public getDeviceInfo(): string {
    return this.preferences?.getSync(KEY_DEVICE_INFO, '') as string;
  }

  public updateDeviceInfo(info: CMGDeviceInfo) {
    this.putSync(KEY_DEVICE_INFO, JSON.stringify(info));
  }

  private putSync(key: string, value: ValueType) {
    this.preferences?.putSync(key, value);
    this.preferences?.flushSync();
  }
}