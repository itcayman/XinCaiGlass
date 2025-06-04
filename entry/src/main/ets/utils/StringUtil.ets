/**
 * 判断字符串是否为空
 * @param str 字符串
 * @returns 判断结果
 */
export function isBlank(str: string): boolean {
  return (null == str) || (undefined == str) || (str.trim() === "");
}