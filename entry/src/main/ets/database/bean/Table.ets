/**
 * 表配置信息
 * tableName：表名称
 * sqlCreate：创建表的语句
 * columns：表的列项目
 */
export class Table {
  public tableName: string = '';
  public sqlCreate: string = '';
  public columns: Array<string> = [];
}