import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { Configuration } from '@kit.AbilityKit';
import { cyl_updateColorMode, cyl_simulateMemoryWarning, cyl_setLocalizationContext, CYLSetLocalizationLanguage } from 'cyltabbar';

/**
 * [EN] The example's ability: one window showing pages/Index (the tab bar controller of the Objective-C Example).
 * [CN] 示例的 Ability：一个窗口显示 pages/Index（Objective-C Example 的 TabBarController）。
 */
export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    cyl_updateColorMode(this.context.config.colorMode);
    cyl_setLocalizationContext(this.context);
    this.cylApplyLaunchLanguage(want);
    this.cylApplyLaunchColorMode(want);
    this.cylStoreLaunchOptions(want);
  }

  /**
   * [EN] Launch parameter cylColorMode (`dark` or `light`, as ClassifyMenu's example) sets the app's color mode instead of the system's,
   *      for dark mode checks and screenshots: `aa start -b com.cyl.tabbar.harmony -a EntryAbility --ps cylColorMode dark`.
   * [CN] 启动参数 cylColorMode（`dark` 或 `light`，与 ClassifyMenu 示例一致）设置应用的颜色模式而不是系统的，用于深色模式检查与截图。
   */
  private cylApplyLaunchColorMode(want: Want): void {
    const mode = want.parameters?.['cylColorMode'];
    if (mode === 'dark' || mode === 'light') {
      this.context.getApplicationContext().setColorMode(mode === 'dark' ? ConfigurationConstant.ColorMode.COLOR_MODE_DARK
        : ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
      cyl_updateColorMode(mode === 'dark' ? ConfigurationConstant.ColorMode.COLOR_MODE_DARK : ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    }
  }

  /** [EN] A relaunch with new launch options while the app runs. [CN] 应用运行时以新的启动参数再次启动。 */
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.cylApplyLaunchLanguage(want);
    this.cylStoreLaunchOptions(want);
  }

  /**
   * [EN] Launch options for automated checks and screenshots (pages/Index applies them once it appears):
   *      cylScreen <row id> runs a demo row as if tapped (e.g. configuration-svga, system-tab-bar-plus, any id of the
   *      demo lists); cylTheme <skin name or title> picks a skin; cylStyle flat|glass rebuilds the tab bar in that style.
   *      `aa start -b com.cyl.tabbar.harmony -a EntryAbility --ps cylStyle flat --ps cylTheme 太空 --ps cylScreen skin`.
   * [CN] 自动化检查与截图用的启动参数（pages/Index 出现后应用）：cylScreen <行 id> 如同点击该演示行；cylTheme <皮肤名或标题> 选择皮肤；
   *      cylStyle flat|glass 以该样式重建 TabBar。
   */
  private cylStoreLaunchOptions(want: Want): void {
    const text = (key: string): string => {
      const value = want.parameters?.[key];
      return typeof value === 'string' ? value as string : '';
    };
    const options = [text('cylStyle'), text('cylTheme'), text('cylScreen')];
    if (options.some((value: string) => value !== '')) {
      AppStorage.setOrCreate('cylLaunchOptions', options.join('|'));
    }
  }

  /**
   * [EN] Launch parameter CYLDemoLanguage (a language tag such as zh-Hant, de, ar; '' follows the system), for automated UI tests
   *      and screenshots, like the iOS demos' launch arguments: `aa start -b com.cyl.tabbar.harmony -a EntryAbility
   *      --ps CYLDemoLanguage zh-Hant`. It sets the app's language through CYLSetLocalizationLanguage before the page loads.
   * [CN] 启动参数 CYLDemoLanguage（语言标签，如 zh-Hant、de、ar；'' 跟随系统），用于自动化 UI 测试与截图，与 iOS 示例的启动参数相同。在页面加载前
   *      通过 CYLSetLocalizationLanguage 设置应用语言。
   */
  private cylApplyLaunchLanguage(want: Want): void {
    // [EN] cylLanguage is an alias (as ClassifyMenu's example). [CN] cylLanguage 为别名（与 ClassifyMenu 示例一致）。
    const language = want.parameters?.['CYLDemoLanguage'] ?? want.parameters?.['cylLanguage'];
    if (typeof language === 'string') {
      CYLSetLocalizationLanguage(language as string);
    }
  }

  /** [EN] Item 54: follow the system's dark / light mode. [CN] 第 54 项：跟随系统深色 / 浅色模式。 */
  onConfigurationUpdate(config: Configuration): void {
    cyl_updateColorMode(config.colorMode);
    this.cylUpdateSystemBars(config.colorMode);
  }

  /** [EN] A real memory warning reaches every tab bar controller (#426). [CN] 真实内存警告传给所有 TabBarController。 */
  onMemoryLevel(level: AbilityConstant.MemoryLevel): void {
    if (level !== AbilityConstant.MemoryLevel.MEMORY_LEVEL_MODERATE) {
      cyl_simulateMemoryWarning();
    }
  }

  private windowStage?: window.WindowStage;

  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.windowStage = windowStage;
    windowStage.loadContent('pages/Index');
    this.cylUpdateSystemBars(this.context.config.colorMode);
  }

  /**
   * [EN] The status bar takes the navigation bar's color (cyl_bar_background), dark text in light mode and light text in
   *      dark mode (issue list #4). [CN] 状态栏使用导航栏颜色；浅色模式深色文字，深色模式浅色文字（问题 #4）。
   */
  private cylUpdateSystemBars(colorMode: number | undefined): void {
    const dark = colorMode === 0;
    this.windowStage?.getMainWindow().then((main: window.Window) => {
      main.setWindowSystemBarProperties({
        statusBarColor: dark ? '#121212' : '#F8F8F8',
        statusBarContentColor: dark ? '#FFFFFF' : '#000000',
      }).catch(() => {});
    }).catch(() => {});
  }
}
