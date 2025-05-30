export class TimeUtil {

  static formatTimestamp(timestamp: number): string {
    // 创建一个 Date 对象，将时间戳转换为日期时间
    const date = new Date(timestamp);
    // 获取年份
    const year = date.getFullYear();
    // 获取月份，注意 getMonth() 返回的月份是从 0 开始的，所以要加 1
    const month = String(date.getMonth() + 1).padStart(2, '0');
    // 获取日期
    const day = String(date.getDate()).padStart(2, '0');
    // 获取小时
    const hours = String(date.getHours()).padStart(2, '0');
    // 获取分钟
    const minutes = String(date.getMinutes()).padStart(2, '0');
    // 获取秒数
    const seconds = String(date.getSeconds()).padStart(2, '0');

    // 按照 'YYYY/MM/DD HH:mm' 的格式拼接时间字符串
    return `${year}/${month}/${day} ${hours}:${minutes}`;
  }
}