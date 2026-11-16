import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { Configuration } from '@kit.AbilityKit';
import { cyl_updateColorMode, cyl_simulateMemoryWarning, cyl_setLocalizationContext } from 'cyltabbar';

/**
 * [EN] The example's ability: one window showing pages/Index (the tab bar controller of the Objective-C Example).
 * [CN] 示例的 Ability：一个窗口显示 pages/Index（Objective-C Example 的 TabBarController）。
 */
export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    cyl_updateColorMode(this.context.config.colorMode);
    cyl_setLocalizationContext(this.context);
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
