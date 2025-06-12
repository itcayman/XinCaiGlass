import { access } from "@kit.ConnectivityKit";
import { Logger } from "../utils/Logger";
import bleScanManager, { BleScanManager } from "./BleScanManager";

const TAG = '[Bluetooth]'

export class BluetoothManager {
  private bleScanManager: BleScanManager = new BleScanManager();
  private bluetoothState: access.BluetoothState = access.BluetoothState.STATE_OFF;

  public init() {
    this.bluetoothState = access.getState()
    Logger.info(TAG, `bluetooth statues: ${this.getStateStr(this.bluetoothState)}`);
    access.on('stateChange', (data) => {
      this.bluetoothState = data;
      Logger.info(TAG, `bluetooth statues: ${this.getStateStr(data)}`);
    })
  }


  public isBluetoothOff(): boolean {
    return this.bluetoothState == access.BluetoothState.STATE_OFF;
  }

  public startBLEScan() {
    this.bleScanManager.startScan();
  }

  private getStateStr(state: access.BluetoothState): string {
    let btStateMessage = '';
    switch (state) {
      case 0:
        btStateMessage += 'STATE_OFF';
        break;
      case 1:
        btStateMessage += 'STATE_TURNING_ON';
        break;
      case 2:
        btStateMessage += 'STATE_ON';
        break;
      case 3:
        btStateMessage += 'STATE_TURNING_OFF';
        break;
      case 4:
        btStateMessage += 'STATE_BLE_TURNING_ON';
        break;
      case 5:
        btStateMessage += 'STATE_BLE_ON';
        break;
      case 6:
        btStateMessage += 'STATE_BLE_TURNING_OFF';
        break;
      default:
        btStateMessage += 'unknown status';
        break;
    }
    return btStateMessage;
  }
}