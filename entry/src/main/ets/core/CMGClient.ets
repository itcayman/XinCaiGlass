import { CMGDeviceInfo } from "../viewmodel/CMGDeviceInfo";
import { LocalDataManager } from "./LocalDataManager";
import { bundleManager, Context } from "@kit.AbilityKit";
import { BluetoothManager } from "./BluetoothManager";
import { isBlank } from "../utils/StringUtil";
import { emitter } from "@kit.BasicServicesKit";
import { BLE_SCAN_ID } from "../constants/EventIds";
import { BleScanItem } from "../viewmodel/BleScanItem";
import { CommandManager } from "./CommandManager";
import { AIManager } from "./AIManager";
import { RealtimeAsrManager } from "./RealtimeAsrClient";
import { GattClientManager } from "./GattClientManager";
import {
  BLE_DEVICE_CONNECTED,
  BLE_DEVICE_CONNECTING,
  BLE_DEVICE_DISCONNECTED as BLE_DEVICE_DISCONNECT
} from "../constants/EventIds";

const DEVICE_NAME_FILTER = 'CMG_Y01_0001'

export class CMGClient {
  private glassDevice: CMGDeviceInfo = new CMGDeviceInfo();
  private localData: LocalDataManager = new LocalDataManager();
  private bluetooth: BluetoothManager = new BluetoothManager();
  private realtimeASR = new RealtimeAsrManager();
  private gattClient: GattClientManager = new GattClientManager();
  private command: CommandManager = new CommandManager(this.gattClient);
  private ai: AIManager = new AIManager(this.command, this.realtimeASR, this.gattClient);

  init(context: Context) {
    this.localData.init(context);
    this.bluetooth.init();

    this.initMac();
    this.initSoftwareInfo();
  }

  public bluetoothM(): BluetoothManager {
    return this.bluetooth;
  }

  public realtimeAsrM(): RealtimeAsrManager {
    return this.realtimeASR;
  }

  public commandM(): CommandManager {
    return this.command;
  }

  public aiM(): AIManager {
    return this.ai;
  }

  public gattClientM(): GattClientManager {
    return this.gattClient;
  }

  public findDevice() {
    emitter.on({ eventId: BLE_SCAN_ID }, (eventData: emitter.EventData) => {
      let findDevice: BleScanItem = eventData?.data?.BleScanItem;
      if (findDevice.deviceName.startsWith(DEVICE_NAME_FILTER)) {

      }
    })
    this.bluetooth.startBLEScan();
  }

  private initMac() {
    this.glassDevice.mac = this.localData.getMac();
    // 本地没有存设备信息，则需要本地自动连接最近的CMG设备
    if (isBlank(this.glassDevice.mac)) {

    }
  }

  private initSoftwareInfo() {
    bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION).then((bundleInfo) => {
      this.glassDevice.softwareVersion = bundleInfo.versionName;
    })
  }

  private initListeners() {
    emitter.on({ eventId: BLE_DEVICE_DISCONNECT }, () => {
    })
    emitter.on({ eventId: BLE_DEVICE_CONNECTING }, () => {
    })
    emitter.on({ eventId: BLE_DEVICE_CONNECTED }, () => {
    })
  }
}

let cmgClient = new CMGClient();

export default cmgClient as CMGClient;