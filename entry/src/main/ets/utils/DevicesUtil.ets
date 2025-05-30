
import window from '@ohos.window';
import { common } from '@kit.AbilityKit';
import display from '@ohos.display';
import deviceInfo from '@ohos.deviceInfo';
import i18n from '@ohos.i18n';

export class DevicesUtil {

  /// 物理像素转虚拟像素
  private static pxToVp(px: number): number {
    const dis = display.getDefaultDisplaySync();
    return px / (dis.densityDPI / 160); // 标准转换公式
  }

  /// 同步获取屏幕信息
  static getScreenDisplaySync(): display.Display {
    return display.getDefaultDisplaySync(); // 返回的宽度和高度单位为物理像素(px）
  }

  /// 获取屏幕宽度(vp)
  static getScreenWidthVP(): number {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      return DevicesUtil.pxToVp(displayInfo.width);
    } catch {
      return 360; // 默认宽度(vp)
    }
  }

  /// 获取屏幕高度(vp)
  static getScreenHeightVP(): number {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      return DevicesUtil.pxToVp(displayInfo.height);
    } catch {
      return 780; // 默认高度(vp)
    }
  }

  /// 状态栏高度
  static async getStatusBarHeight(context: common.UIAbilityContext, isVP: boolean = true): Promise<number> {
    try {
      const win = await window.getLastWindow(context);
      /*
      getWindowAvoidArea返回的物理像素，需要转换为虚拟像素返回，便于布局
      TYPE_SYSTEM：获取状态栏区域（推荐使用）
      TYPE_NAVIGATION_INDICATOR：获取导航栏区域
      TYPE_CUTOUT：获取刘海屏区域
      */
      const avoidArea = await win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      if (isVP) {
        return DevicesUtil.pxToVp(avoidArea.topRect.height);
      } else {
        return avoidArea.topRect.height;
      }
    } catch {
      return isVP ? 24 : 96; // 默认安全高度 // 96 假设480dpi设备
    }
  }

  /// 底部导航栏高度
  /// 不包含状态栏高度‌，仅包含屏幕底部导航栏自身的像素高度
  static async getNavigationBarHeight(context: common.UIAbilityContext, isVP: boolean = true): Promise<number> {
    try {
      const win = await window.getLastWindow(context);
      const avoidArea = await win.getWindowAvoidArea(
        window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR
      );
      if (isVP) {
        return DevicesUtil.pxToVp(avoidArea.bottomRect.height);
      } else {
        return avoidArea.bottomRect.height;
      }
    } catch {
      return isVP ? 48 : 192; // 默认导航栏高度 // 192 假设480dpi设备
    }
  }

  /// 刘海屏高度
  /// 获取的 avoidArea.topRect.height ‌不包含导航栏高度‌，仅表示刘海屏（或挖孔屏）区域的高度
  // 特殊说明：刘海屏高度通常位于状态栏区域内部，可能与状态栏存在重叠区域
  static async getCutoutHeight(context: common.UIAbilityContext, isVP: boolean = true): Promise<number> {
    try {
      const win = await window.getLastWindow(context);
      const avoidArea = await win.getWindowAvoidArea(
        window.AvoidAreaType.TYPE_CUTOUT
      );
      if (isVP) {
        return DevicesUtil.pxToVp(avoidArea.topRect.height);
      } else {
        return avoidArea.topRect.height;
      }
    } catch {
      return 0; // 刘海屏默认高度无论单位都返回0
    }
  }

  /// 获取设备类型 (如: "phone")
  static getDeviceType(): string {
    try {
      return deviceInfo.deviceType;
    } catch {
      return '';
    }
  }

  /// 获取设备显示型号（如："emulator"、"P50 Pro"）
  static getDisplayModel(): string {
    return deviceInfo.marketName || deviceInfo.productModel
  }

  /// 获取设备品牌（如："HUAWEI"）
  static getDeviceBrand(): string {
    return deviceInfo.brand
  }

  /// 获取系统版本号 (如: "OpenHarmony-5.0.1")
  static getSystemVersion(): string {
    try {
      return deviceInfo.osFullName;
    } catch {
      return '';
    }
  }

  /// 获取系统语言 (如: "zh-Hans-CN")
  static getSystemLanguage(): string {
    try {
      return i18n.System.getSystemLanguage();
    } catch {
      return 'en-US'; // 默认返回英文
    }
  }

  /// 获取格式化语言名称 (如: "简体中文")
  /// 获取语言显示名称 en/zh/fr...
  static getLanguageDisplayName(langCode: string): string {
    try {
      return i18n.System.getDisplayLanguage(
        langCode,
        DevicesUtil.getSystemLanguage()
      )
    } catch {
      return langCode
    }
  }
}