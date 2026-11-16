import { describe, it, expect } from '@ohos/hypium';
import { abilityDelegatorRegistry, Driver, ON } from '@kit.TestKit';
import { Want } from '@kit.AbilityKit';

const delegator = abilityDelegatorRegistry.getAbilityDelegator();

/**
 * [EN] UI test: controls are found by their id and accessibility text first (AGENTS.md), never by coordinates.
 * [CN] UI 测试：先通过 id 与无障碍文本查找控件（AGENTS.md），不使用坐标。
 */
export default function tabBarTest() {
  describe('CYLTabBarTest', () => {
    it('selectsTabsFoundByTheirIds', 0, async () => {
      const want: Want = { bundleName: 'com.cyl.tabbar.harmony.example', abilityName: 'EntryAbility' };
      await delegator.startAbility(want);
      const driver = Driver.create();
      await driver.delayMs(1500);
      // [EN] Each tab is found again after a tap: the UI may have changed. [CN] 每次点击后重新查找 Tab：界面可能已变化。
      for (const identifier of ['messages', 'me', 'nearby', 'home']) {
        const tab = await driver.findComponent(ON.id(`CYLTabBarItem_${identifier}`));
        expect(tab !== null).assertTrue();
        await tab.click();
        await driver.delayMs(800);
        const selected = await driver.findComponent(ON.id(`CYLTabBarItem_${identifier}`));
        expect(await selected.isSelected()).assertTrue();
        await driver.assertComponentExist(ON.id(`CYLDemoPage_${identifier}`));
      }
      await driver.assertComponentExist(ON.id('CYLPlusButton'));
    });
  });
}
