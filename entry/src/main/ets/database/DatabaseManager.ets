import { TeleprompterEntity } from "./bean/TeleprompterEntity";
import TeleprompterTable from "./TeleprompterTable";
import { systemDateTime } from "@kit.BasicServicesKit";
import { Logger } from "../utils/Logger";
import call from "@ohos.telephony.call";

const TAG: string = '[DB]DatabaseManager'

export class DatabaseManager {
  private teleprompterTable: TeleprompterTable | undefined;

  constructor() {
  }

  init() {
    this.teleprompterTable = new TeleprompterTable()
    Logger.info(TAG, "init")
  }

  insertOrUpdate(data: TeleprompterEntity, callback: Function) {
    this.findTeleprompter(data, (result: Array<TeleprompterEntity>) => {
      if (result.length == 0) {
        this.insertTeleprompter(data, callback)
      } else {
        this.updateTeleprompter(data, callback)
      }
    })
  }

  insertTeleprompter(data: TeleprompterEntity, callback: Function) {
    Logger.debug(TAG, '插入数据, title:'+data.title)
    this.teleprompterTable?.insert(data, callback)
  }

  deleteTeleprompter(data: TeleprompterEntity, callback: Function) {
    this.teleprompterTable?.delete(data, callback)
  }

  updateTeleprompter(data: TeleprompterEntity, callback: Function) {
    Logger.debug(TAG, '更新数据, title:'+data.title)
    this.teleprompterTable?.update(data, callback)
  }

  getAllTeleprompter(callBack: Function) {
    this.teleprompterTable?.query(0, callBack)
  }

  findTeleprompter(data: TeleprompterEntity, callback: Function) {
    this.teleprompterTable?.query(data.timestamp, callback, false)
  }
}

let databaseManager = new DatabaseManager()

export default databaseManager as DatabaseManager