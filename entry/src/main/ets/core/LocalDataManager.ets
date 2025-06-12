import fs from '@ohos.file.fs';
import preferences from '@ohos.data.preferences';
import { CMGDeviceInfo } from '../viewmodel/CMGDeviceInfo';
import { ValueType } from '@kit.ArkData';

const KEY_MAC = 'MAC';

export class LocalDataManager {
  private preferences: preferences.Preferences | undefined

  public init(context: Context) {
    let option: preferences.Options = {
      name: 'cmg'
    }
    this.preferences = preferences.getPreferencesSync(context, option)
  }

  public getMac(): string {
    return this.preferences?.getSync(KEY_MAC, '') as string;
  }

  public putMac(mac: string) {
    this.putSync(KEY_MAC, mac);
  }

  private putSync(key: string, value: ValueType) {
    this.preferences?.putSync(key, value);
    this.preferences?.flushSync();
  }
}