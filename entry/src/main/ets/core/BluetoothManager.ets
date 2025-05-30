import { access } from "@kit.ConnectivityKit";

export class BluetoothManager {
  private static instance: BluetoothManager
  private serviceUUID:string = 'F48A23C0-F69A-11E8-8EB2-F2801F1B9FD1'
  private characteristic1UUID:string = 'F48A24C1-F69A-11E8-8EB2-F2801F1B9FD1'
  private characteristic2UUID:string = 'F48A25C2-F69A-11E8-8EB2-F2801F1B9FD1'

  public static getInstance(): BluetoothManager {
    if (!BluetoothManager.instance) {
      BluetoothManager.instance = new BluetoothManager()
    }
    return BluetoothManager.instance
  }

  public start() {
    access.on('stateChange', (data) => {
      let btStateMessage = '';
      switch (data) {
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
      if (btStateMessage == 'STATE_ON') {
        access.off('stateChange');
      }
      console.info('bluetooth statues: ' + btStateMessage);
    })
  }
}