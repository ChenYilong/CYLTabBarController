import { abilityDelegatorRegistry, TestRunner } from '@kit.TestKit';
import { Want } from '@kit.AbilityKit';

/** [EN] Starts TestAbility in the app under test. [CN] 在被测 App 中启动 TestAbility。 */
export default class OpenHarmonyTestRunner implements TestRunner {
  onPrepare() {
  }

  async onRun() {
    const args = abilityDelegatorRegistry.getArguments();
    const delegator = abilityDelegatorRegistry.getAbilityDelegator();
    const want: Want = { bundleName: args.bundleName, abilityName: 'TestAbility' };
    await delegator.startAbility(want);
  }
}
