import { TeleprompterEntity } from "./bean/TeleprompterEntity";
import TeleprompterTable from "./TeleprompterTable";
import { systemDateTime } from "@kit.BasicServicesKit";
import { Logger } from "../utils/Logger";

const TAG: string = '[DB]DatabaseManager'

export class DatabaseManager {
  private teleprompterTable: TeleprompterTable | undefined;

  constructor() {
  }

  init() {
    this.teleprompterTable = new TeleprompterTable()
    Logger.info(TAG, "init")
  }

  insertTeleprompter(data: TeleprompterEntity, callback: Function) {
    this.teleprompterTable?.insert(data, callback)
  }

  getAllTeleprompter(callBack: Function) {
    this.teleprompterTable?.query(0, callBack)
  }

}

let databaseManager = new DatabaseManager()

export default databaseManager as DatabaseManager