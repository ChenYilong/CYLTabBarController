import { describe, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@kit.TestKit';
import { display } from '@kit.ArkUI';
import { CYLTabBarDefaultHeight } from 'cyltabbar';

/**
 * [EN] The default tab bar height equals the system tab bar's (docs/Cross-Platform-Components.md, "default tab bar height
 *      = the system tab bar's"): the test page holds an ArkUI Tabs with a bottom bar and its default barHeight; its item
 *      fills the bar, so the item's height on screen is the system bar's height. CYLTabBarDefaultHeight (what a
 *      CYLTabBarController without tabBarHeight uses) must match it, on every device and system version this runs on.
 * [CN] 默认 TabBar 高度等于系统 TabBar 的高度：测试页面包含一个底部 TabBar、默认 barHeight 的 ArkUI Tabs；其 Tab 项填满 TabBar，因此其屏幕
 *      高度就是系统 TabBar 的高度。CYLTabBarDefaultHeight（未设置 tabBarHeight 的 CYLTabBarController 使用的值）必须与之相同。
 */
export default function cylTabBarHeightTest() {
  describe('CYLTabBarHeight', () => {
    it('CYLTabBarDefaultHeight is 56 vp', 0, () => {
      expect(CYLTabBarDefaultHeight).assertEqual(56);
    });

    it('the system tab bar on this device is CYLTabBarDefaultHeight tall', 0, async (done: Function) => {
      const driver = Driver.create();
      await driver.delayMs(1000);
      const item = await driver.findComponent(ON.id('cyl-test-system-bar-item-0'));
      expect(item !== null && item !== undefined).assertTrue();
      const bounds = await item.getBounds();
      const density = display.getDefaultDisplaySync().densityPixels;
      const heightVp = (bounds.bottom - bounds.top) / density;
      console.info(`[CYLTabBarHeight] system tab bar: ${bounds.bottom - bounds.top} px = ${heightVp} vp (density ${density})`);
      expect(Math.abs(heightVp - CYLTabBarDefaultHeight) <= 1).assertTrue();
      done();
    });
  });
}
