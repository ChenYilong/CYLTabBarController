import { CYLLocalizedString } from 'cyltabbar';

/**
 * [EN] Item 20: scroll hiding, simulated interruptions (iOS UIViewController+CYLScrollHideSimulation, Android
 *      DemoScrollHide.kt): 39 cases in the iOS / Android order. Each automatic case fires 1.5 s after the tap; scroll down
 *      first so the tab bar hides. Restore: the bar must come back at once; Keep: the bar's state must not change because
 *      of it; NotApplicable: HarmonyOS has no such event; Manual: do what the title says; SelfTest: run every automatic case.
 * [CN] 第 20 项：滚动隐藏的模拟意外情况：39 个用例，顺序与 iOS / Android 相同。自动用例在点击 1.5 秒后触发；请先向下滚动隐藏 TabBar。
 *      Restore：TabBar 应立即恢复；Keep：TabBar 状态不应因此改变；NotApplicable：鸿蒙没有此事件；Manual：按标题手动操作；SelfTest：运行所有自动用例。
 */
export enum DemoScrollKind {
  Restore = 0,
  Keep,
  NotApplicable,
  Manual,
  SelfTest,
}

/**
 * [EN] The action a case performs (Index runs it): dialog, actionMenu, push, pushHidden, nextTab, memoryWarning,
 *      scrollUp, scrollDown, hideApp, toggleHidesOnScroll, sameTab, hidesOnScrollAgain, showApp, or '' for none.
 * [CN] 用例执行的动作（由 Index 运行）。
 */
export interface DemoScrollSimulation {
  title: string;
  kind: DemoScrollKind;
  action: string;
  /** [EN] The bar's expected visibility after the case (Keep cases that keep it hidden: false). [CN] 用例后 TabBar 的预期可见性。 */
  expectsVisible: boolean;
}

const R = DemoScrollKind.Restore;
const K = DemoScrollKind.Keep;
const N = DemoScrollKind.NotApplicable;
const M = DemoScrollKind.Manual;

export const DEMO_SCROLL_SIMULATIONS: DemoScrollSimulation[] = [
  { title: 'AlertDialog (alert)', kind: R, action: 'dialog', expectsVisible: true },
  { title: 'Action menu (action sheet)', kind: R, action: 'actionMenu', expectsVisible: true },
  { title: 'A full screen page (full screen modal), then back', kind: R, action: 'push', expectsVisible: true },
  { title: 'A dialog with a page (page sheet)', kind: R, action: 'dialog', expectsVisible: true },
  { title: 'cyl_pushViewController, then pop', kind: R, action: 'push', expectsVisible: true },
  { title: 'Push a page that hides the tab bar, then pop', kind: R, action: 'pushHidden', expectsVisible: true },
  { title: 'selectedIndex + 1, then back', kind: R, action: 'nextTab', expectsVisible: true },
  { title: 'Manual: the app goes to the background (onBackground / onForeground), come back', kind: M, action: '', expectsVisible: true },
  { title: 'Manual: a system dialog covers the app (a call, low battery)', kind: M, action: '', expectsVisible: true },
  { title: 'Notification tap: come back, then push', kind: N, action: '', expectsVisible: true },
  { title: 'onMemoryLevel (memory warning)', kind: R, action: 'memoryWarning', expectsVisible: true },
  { title: 'A popup over the page (another window)', kind: R, action: 'dialog', expectsVisible: true },
  { title: 'Manual: focus a text field (keyboard)', kind: M, action: '', expectsVisible: true },
  { title: 'Share sheet', kind: N, action: '', expectsVisible: true },
  { title: 'Scroll to top in code', kind: R, action: 'scrollUp', expectsVisible: true },
  { title: 'Scroll down in code', kind: K, action: 'scrollDown', expectsVisible: false },
  { title: 'App: setTabBarHidden(true) for 4 s', kind: K, action: 'hideApp', expectsVisible: false },
  { title: 'cyl_hidesTabBarOnScroll = false, then true', kind: R, action: 'toggleHidesOnScroll', expectsVisible: true },
  { title: 'Screen reader turned on or off', kind: N, action: '', expectsVisible: true },
  { title: 'Manual: keyboard up, scroll; the bar must not hide', kind: M, action: '', expectsVisible: true },
  { title: 'Reduce motion changed', kind: N, action: '', expectsVisible: true },
  { title: 'Battery saver turned on', kind: N, action: '', expectsVisible: true },
  { title: 'Manual: rotate the device (the bar starts shown)', kind: M, action: '', expectsVisible: true },
  { title: 'A translucent page over the current one, then back', kind: R, action: 'push', expectsVisible: true },
  { title: 'A menu (popover)', kind: R, action: 'actionMenu', expectsVisible: true },
  { title: 'A side drawer slides in and away', kind: R, action: 'dialog', expectsVisible: true },
  { title: 'Status bar height change', kind: N, action: '', expectsVisible: true },
  { title: 'Manual: split screen, tap the other app (this window loses the focus)', kind: M, action: '', expectsVisible: true },
  { title: 'Manual: long press a row (context menu)', kind: M, action: '', expectsVisible: true },
  { title: 'Manual: tap a navigation bar button', kind: M, action: '', expectsVisible: true },
  { title: 'Manual: after a restore, fling on without lifting; only a new drag hides it', kind: M, action: '', expectsVisible: true },
  { title: 'Manual: open Settings (the app really goes to the background), come back', kind: M, action: '', expectsVisible: true },
  { title: 'Manual: a real system dialog (the dialer), press Back', kind: M, action: '', expectsVisible: true },
  { title: 'Keyboard of another app', kind: N, action: '', expectsVisible: true },
  { title: 'Screen pinning (guided access)', kind: N, action: '', expectsVisible: true },
  { title: 'selectedIndex = the same tab (no change)', kind: K, action: 'sameTab', expectsVisible: false },
  { title: 'cyl_hidesTabBarOnScroll = true again (no change)', kind: K, action: 'hidesOnScrollAgain', expectsVisible: false },
  { title: 'App: setTabBarHidden(false)', kind: R, action: 'showApp', expectsVisible: true },
  { title: 'Self-test: run every automatic simulation, report PASS / FAIL', kind: DemoScrollKind.SelfTest, action: '', expectsVisible: true },
];

/** [EN] The kind's label, localized as on iOS and Android. [CN] 类型名，与 iOS、Android 一样本地化。 */
export function demoScrollKindName(kind: DemoScrollKind): string {
  return [CYLLocalizedString('恢复'), CYLLocalizedString('保持'), CYLLocalizedString('不适用'), CYLLocalizedString('手动'),
    CYLLocalizedString('自测')][kind];
}

/**
 * [EN] The case's title as shown: the "Manual:" / "Real:" prefix and the self-test title are localized; the API or event
 *      it names stays English, as on iOS and Android.
 * [CN] 显示的用例标题：「手动：」「实测：」前缀与自测标题已本地化；所触发的 API 或事件保持英文，与 iOS、Android 相同。
 */
export function demoScrollTitle(simulation: DemoScrollSimulation): string {
  const title = simulation.title;
  if (simulation.kind === DemoScrollKind.SelfTest) {
    return CYLLocalizedString('自测：依次运行所有自动模拟，报告 PASS / FAIL');
  }
  if (title.startsWith('Manual: ')) {
    return CYLLocalizedString('手动：%@', title.substring('Manual: '.length));
  }
  if (title.startsWith('Real: ')) {
    return CYLLocalizedString('实测：%@', title.substring('Real: '.length));
  }
  return title;
}
