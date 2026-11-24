import { describe, it, expect } from '@ohos/hypium';
import { DemoTeardown } from '../../../main/ets/demo/DemoTeardown';

/**
 * [EN] The teardown row's counters (docs/Lifecycle-Library.md, step 21): the summary counts the dealloc callbacks that ran, and arming
 *      needs a tab bar controller on screen. Written statically; to be run once in the test batch on the Windows machine.
 * [CN] 销毁行的计数（docs/Lifecycle-Library.md，第 21 步）：摘要统计已执行的 dealloc 回调，登记需要有显示中的 TabBarController。
 *      静态编写；等测试批次在 Windows 机器上一次运行。
 */
export default function demoTeardownTest() {
  describe('DemoTeardown', () => {
    it('counts the callbacks that ran and listeners hear them', 0, () => {
      DemoTeardown.reset();
      let heard = 0;
      const listener: () => void = (): void => {
        heard += 1;
      };
      DemoTeardown.addListener(listener);
      DemoTeardown.record('CYLTabBarController');
      expect(DemoTeardown.ranCount).assertEqual(1);
      expect(heard).assertEqual(1);
      DemoTeardown.removeListener(listener);
      DemoTeardown.record('x');
      expect(heard).assertEqual(1);
      DemoTeardown.reset();
      expect(DemoTeardown.ranCount).assertEqual(0);
    });

    it('the status line follows the countdown', 0, () => {
      expect(DemoTeardown.status(0).length > 0).assertTrue();
      expect(DemoTeardown.status(3).indexOf('3') >= 0).assertTrue();
    });
  });
}
