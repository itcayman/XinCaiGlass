import { TeleprompterEntity } from "./bean/TeleprompterEntity";
import Rdb from "./Rdb";
import { TableConstants } from "./TableConstants";
import { relationalStore } from "@kit.ArkData";
import { Logger } from "../utils/Logger";

const TABLE_NAME = TableConstants.TELEPROMPTER.tableName;
const TAG: string = '[DB][Teleprompter]'

export default class TeleprompterTable {
  private teleprompterTable = new Rdb(TABLE_NAME, TableConstants.TELEPROMPTER.sqlCreate,
    TableConstants.TELEPROMPTER.columns);

  constructor(callback: Function = () => {
  }) {
    this.teleprompterTable.getRdbStore(callback);
  }

  insert(data: TeleprompterEntity, callback: Function) {
    const valueBucket: relationalStore.ValuesBucket = this.generateBucket(data);
    this.teleprompterTable.insertData(valueBucket, callback);
  }

  delete(data: TeleprompterEntity, callback: Function) {
    let predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.equalTo('id', data.id);
    this.teleprompterTable.deleteData(predicates, callback);
  }

  update(data: TeleprompterEntity, callback: Function) {
    const valueBucket: relationalStore.ValuesBucket = this.generateBucket(data);
    let predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.equalTo('id', data.id);
    this.teleprompterTable.updateData(predicates, valueBucket, callback);
  }

  // 查(查询的字段，回调，是否查询全部)
  query(id: number, callback: Function, isAll: boolean = true) {
    let predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    // if (!isAll) {
    //   predicates.equalTo('id', id);
    // }
    this.teleprompterTable.query(predicates, (resultSet: relationalStore.ResultSet) => {
      let count: number = resultSet.rowCount;
      if (count === 0 || typeof count === 'string') {
        Logger.debug(TAG, 'Query no results!');
        callback([]);
      } else {
        let result: Array<TeleprompterEntity> = new Array();
        while (resultSet.goToNextRow()) {
          const id = resultSet.getLong(resultSet.getColumnIndex('ID'));
          const title = resultSet.getString(resultSet.getColumnIndex('TITLE'));
          const content = resultSet.getString(resultSet.getColumnIndex('CONTENT'));
          const timestamp = resultSet.getLong(resultSet.getColumnIndex('TIMESTAMP'));
          Logger.log(TAG, `id:${id}, title:${title}, content:${content}, timestamp:${timestamp}`);
          result.push(new TeleprompterEntity(id, title, content, timestamp))
        }
        // 释放数据集的内存
        resultSet.close();
        callback(result);
      }
    });
  }

  private generateBucket(data: TeleprompterEntity): relationalStore.ValuesBucket {
    let obj: relationalStore.ValuesBucket = {};
    obj.TITLE = data.title;
    obj.CONTENT = data.content;
    obj.TIMESTAMP = data.timestamp;
    return obj;
  }
}