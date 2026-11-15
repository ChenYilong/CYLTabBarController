import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

/**
 * [EN] The example's ability: one window showing pages/Index (the tab bar controller of the Objective-C Example).
 * [CN] 示例的 Ability：一个窗口显示 pages/Index（Objective-C Example 的 TabBarController）。
 */
export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index');
  }
}
