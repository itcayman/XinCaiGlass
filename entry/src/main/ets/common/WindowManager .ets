import window from '@ohos.window';

export class WindowManager {
  static fullScreen(windowStage: window.WindowStage) {
    try {
      const win = windowStage.getMainWindowSync();
      // 开启沉浸式模式
      win.setWindowLayoutFullScreen(true);

      // 获取状态栏区域
      let systemArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      // 获取顶部状态栏高度并转换为vp单位
      let statusBarHeight = px2vp(systemArea.topRect.height);

      // 获取导航条区域
      let navigationArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      // 获取底部导航条高度并转换为vp单位
      let navigationBarHeight = px2vp(navigationArea.bottomRect.height);

      // 将高度值持久化存储
      AppStorage.setOrCreate('statusBarHeight', statusBarHeight);
      AppStorage.setOrCreate('navigationBarHeight', navigationBarHeight);

      // 同时进行持久化存储
      PersistentStorage.persistProp('statusBarHeight', statusBarHeight);
      PersistentStorage.persistProp('navigationBarHeight', navigationBarHeight);
    } catch (error) {
      console.error('设置沉浸式状态失败:', error);
    }
  }

  // 设置系统栏颜色
  static setSystemBarColor(win: window.Window) {
    try {
      win.setWindowSystemBarProperties({
        statusBarContentColor: '#23282C', // 状态栏文字颜色
        navigationBarContentColor: '#23282C', // 导航栏文字颜色
        statusBarColor: '#FFF1F3F5', // 状态栏背景色
        navigationBarColor: '#FFF1F3F5', // 导航栏背景色
        isStatusBarLightIcon: true, // 状态栏图标是否使用浅色
        isNavigationBarLightIcon: true  // 导航栏图标是否使用浅色
      });
    } catch (error) {
      console.error('设置系统栏颜色失败:', error);
    }
  }
}
