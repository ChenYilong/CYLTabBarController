import { CYLLocalizedString, cyl_addTabBarControllerDeallocCallback } from 'cyltabbar';

/**
 * [EN] The teardown demo (iOS `CYLDemoTeardown`, Android `DemoTeardown`; docs/Lifecycle-Library.md, step 21): the row "Release the tab
 *      bar controller (in 3 s)" arms a dealloc callback on the tab bar controller on screen (CYLDeallocBlockExecutor, ArkTS port),
 *      counts down 3 s, then replaces the page with `pages/Released`. The page disappears, so `aboutToDisappear()` runs the
 *      controller's teardown blocks, and "dealloc callbacks ran: N / M" is the library's own evidence that the controller was released.
 * [CN] 销毁演示（iOS 的 `CYLDemoTeardown`、Android 的 `DemoTeardown`；docs/Lifecycle-Library.md，第 21 步）：「Release the tab bar
 *      controller (in 3 s)」行在当前显示的 TabBarController 上登记 dealloc 回调（CYLDeallocBlockExecutor 的 ArkTS 移植），倒计时 3 秒，
 *      然后把页面替换为 `pages/Released`。页面消失，`aboutToDisappear()` 运行控制器的销毁块，因此「dealloc callbacks ran: N / M」
 *      是库本身给出的「控制器已释放」的证据。
 */
export class DemoTeardown {
  private static armed: string[] = [];
  private static ran: string[] = [];
  private static listeners: (() => void)[] = [];

  static get armedCount(): number {
    return DemoTeardown.armed.length;
  }

  static get ranCount(): number {
    return DemoTeardown.ran.length;
  }

  /** [EN] Registers the dealloc callback on the controller on screen, named `name` in the report; false without a controller. [CN] 在当前控制器上登记 dealloc 回调，报告中名为 `name`；没有控制器时返回 false。 */
  static arm(name: string): boolean {
    const armed = cyl_addTabBarControllerDeallocCallback('cyl.demo.teardown', () => DemoTeardown.record(name));
    if (armed) {
      DemoTeardown.armed.push(name);
    }
    return armed;
  }

  /** [EN] A dealloc callback ran. [CN] 一个 dealloc 回调已执行。 */
  static record(name: string): void {
    DemoTeardown.ran.push(name);
    DemoTeardown.listeners.slice().forEach((listener: () => void) => listener());
  }

  static reset(): void {
    DemoTeardown.armed = [];
    DemoTeardown.ran = [];
  }

  static addListener(listener: () => void): void {
    DemoTeardown.listeners.push(listener);
  }

  static removeListener(listener: () => void): void {
    DemoTeardown.listeners = DemoTeardown.listeners.filter((item: () => void) => item !== listener);
  }

  /** [EN] "dealloc callbacks ran: 1 / 1 (CYLTabBarController)". [CN] 「dealloc callbacks ran: 1 / 1 (CYLTabBarController)」。 */
  static summary(): string {
    return DemoTeardown.ran.length === 0
      ? CYLLocalizedString('dealloc callbacks ran: %d / %d', DemoTeardown.ran.length, DemoTeardown.armed.length)
      : CYLLocalizedString('dealloc callbacks ran: %d / %d (%@)', DemoTeardown.ran.length, DemoTeardown.armed.length,
        DemoTeardown.ran.join(', '));
  }

  /** [EN] The row's status line for `remaining` seconds left (0: not running). [CN] 剩余 `remaining` 秒时该行的状态文字（0：未运行）。 */
  static status(remaining: number): string {
    return remaining > 0 ? CYLLocalizedString('teardown: releasing in %d s', remaining) : CYLLocalizedString('teardown: not run');
  }
}
