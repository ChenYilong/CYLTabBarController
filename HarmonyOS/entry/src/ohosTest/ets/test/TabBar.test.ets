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
      const messages = await driver.findComponent(ON.id('CYLTabBarItem_messages'));
      expect(messages !== null).assertTrue();
      await messages.click();
      await driver.delayMs(500);
      expect(await messages.isSelected()).assertTrue();
      await driver.assertComponentExist(ON.id('CYLDemoPage_messages'));
      const me = await driver.findComponent(ON.id('CYLTabBarItem_me'));
      await me.click();
      await driver.delayMs(500);
      expect(await me.isSelected()).assertTrue();
      await driver.assertComponentExist(ON.id('CYLPlusButton'));
    });
  });
}
