const PREFIX = '[JVC]'
export class Logger {
  static debug(tag: string, message: string) {
    console.debug(PREFIX + tag, message);
  }

  static log(tag: string, message: string) {
    console.log(PREFIX + tag, message);
  }

  static info(tag: string, message: string) {
    console.info(PREFIX + tag, message);
  }

  static warn(tag: string, message: string) {
    console.warn(PREFIX + tag, message);
  }

  static error(tag: string, message: string) {
    console.error(PREFIX + tag, message);
  }
}