export class StringChecker {
  /**
   * 检查长字符串是否包含短字符串中至少两个连续匹配的字符
   * @param shortText 短字符串
   * @param longText 长字符串
   * @returns 是否满足条件
   */
  static hasConsecutiveChars(shortText: string, longText: string): boolean {
    const COUNT = 3;
    if (shortText.length < COUNT || longText.length < COUNT) {
      return false;
    }

    // 创建短字符串中所有连续字符对的集合
    const pairs = new Set<string>();
    for (let i = 0; i < shortText.length - COUNT + 1; i++) {
      pairs.add(shortText[i] + shortText[i + 1] + shortText[i + 2]);
    }

    // 检查长字符串中是否存在这些字符对
    for (let i = 0; i < longText.length - COUNT + 1; i++) {
      const currentPair = longText[i] + longText[i + 1] + longText[i + 2];
      if (pairs.has(currentPair)) {
        return true;
      }
    }

    return false;
  }
}    