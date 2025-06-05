import { Table } from "./bean/Table";

export class TableConstants {
  static readonly TELEPROMPTER: Table = {
    tableName: 'TELEPROMPTER',
    sqlCreate: 'CREATE TABLE IF NOT EXISTS TELEPROMPTER (ID INTEGER PRIMARY KEY AUTOINCREMENT, TITLE TEXT, CONTENT TEXT, TIMESTAMP LONG)',
    columns: ['ID', 'TITLE', 'CONTENT', 'TIMESTAMP']
  };
}