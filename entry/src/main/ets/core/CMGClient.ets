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
import { TeleprompterConfig } from "../viewmodel/config/TeleprompterConfig";
import { plainToInstance } from "class-transformer";
import { Logger } from "../utils/Logger";

const TAG = '[CMGClient]'
const DEVICE_NAME_FILTER = 'CMG_Y01_0001'

export class CMGClient {
  private glassDevice: CMGDeviceInfo = new CMGDeviceInfo();
  private teleprompterConfig: TeleprompterConfig = new TeleprompterConfig();
  private localData: LocalDataManager = new LocalDataManager();
  private bluetooth: BluetoothManager = new BluetoothManager();
  private realtimeASR = new RealtimeAsrManager();
  private gattClient: GattClientManager = new GattClientManager();
  private command: CommandManager = new CommandManager(this.gattClient);
  private ai: AIManager = new AIManager(this.command, this.realtimeASR, this.gattClient);

  init(context: Context) {
    this.localData.init(context)
    this.bluetooth.init()

    this.initDeviceAndAutoConnect()
    this.initTeleprompterConfig()
    this.initSoftwareInfo()
    this.initListeners()
  }

  public bluetoothM(): BluetoothManager {
    return this.bluetooth
  }

  public realtimeAsrM(): RealtimeAsrManager {
    return this.realtimeASR
  }

  public commandM(): CommandManager {
    return this.command
  }

  public aiM(): AIManager {
    return this.ai
  }

  public gattClientM(): GattClientManager {
    return this.gattClient
  }

  public teleprompterC(): TeleprompterConfig {
    return this.teleprompterConfig
  }

  public updateTeleprompterConfig() {
    this.localData.updateTeleprompterConfig(this.teleprompterConfig)
  }

  public findDevice() {
    emitter.on({ eventId: BLE_SCAN_ID }, (eventData: emitter.EventData) => {
      let findDevice: BleScanItem = eventData?.data?.BleScanItem
      if (findDevice.deviceName.startsWith(DEVICE_NAME_FILTER)) {

      }
    })
    this.bluetooth.startBLEScan()
  }

  private initDeviceAndAutoConnect() {
    let localData = this.localData.getDeviceInfo()
    if (!localData) {
      return
    }
    this.glassDevice = localData
    Logger.info(TAG, `眼镜设备信息: ${this.glassDevice.toString()}`)
    if (this.glassDevice && !isBlank(this.glassDevice.deviceName) && !isBlank(this.glassDevice.deviceId)) {
      let device = new BleScanItem(this.glassDevice.deviceId, 0, this.glassDevice.deviceName, false, false, false)
      this.gattClient.startConnect(device)
    }
  }

  private initTeleprompterConfig() {
    let localData = this.localData.getTeleprompterConfig()
    if (!localData) {
      return
    }
    this.teleprompterConfig = localData
  }

  private initSoftwareInfo() {
    bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION).then((bundleInfo) => {
      this.glassDevice.softwareVersion = bundleInfo.versionName
      this.localData.updateDeviceInfo(this.glassDevice)
    })
  }

  private initListeners() {
    emitter.on({ eventId: BLE_DEVICE_DISCONNECT }, (eventData: emitter.EventData) => {
    })
    emitter.on({ eventId: BLE_DEVICE_CONNECTING }, (eventData: emitter.EventData) => {
    })
    emitter.on({ eventId: BLE_DEVICE_CONNECTED }, (eventData: emitter.EventData) => {
      let device: BleScanItem = eventData?.data?.device as BleScanItem;
      if (this.glassDevice.deviceId != device.deviceId) {
        this.glassDevice.deviceId = device.deviceId
        this.glassDevice.deviceName = device.deviceName
        Logger.warn(TAG, `更新眼镜设备信息: ${this.glassDevice.toString()}`)
        this.localData.updateDeviceInfo(this.glassDevice)
      }
    })
  }
}

let cmgClient = new CMGClient();

export default cmgClient as CMGClient;