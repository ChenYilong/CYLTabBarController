import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { Configuration } from '@kit.AbilityKit';
import { cyl_updateColorMode, cyl_simulateMemoryWarning } from 'cyltabbar';

/**
 * [EN] The example's ability: one window showing pages/Index (the tab bar controller of the Objective-C Example).
 * [CN] 示例的 Ability：一个窗口显示 pages/Index（Objective-C Example 的 TabBarController）。
 */
export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    cyl_updateColorMode(this.context.config.colorMode);
  }

  /** [EN] Item 54: follow the system's dark / light mode. [CN] 第 54 项：跟随系统深色 / 浅色模式。 */
  onConfigurationUpdate(config: Configuration): void {
    cyl_updateColorMode(config.colorMode);
  }

  /** [EN] A real memory warning reaches every tab bar controller (#426). [CN] 真实内存警告传给所有 TabBarController。 */
  onMemoryLevel(level: AbilityConstant.MemoryLevel): void {
    if (level !== AbilityConstant.MemoryLevel.MEMORY_LEVEL_MODERATE) {
      cyl_simulateMemoryWarning();
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index');
  }
}
