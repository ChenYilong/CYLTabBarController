import { LifecycleRegistry } from './registry';
import type { Insets, LifecycleEvent, LifecycleInfo } from './types';

export interface Rect {
  width: number;
  height: number;
}

/**
 * Fires the lifecycle events of an ArkUI page or component from the callbacks
 * ArkUI already calls (push model, like the Android controller): the page's
 * handlers forward to this controller, so no event needs code in the handler
 * itself beyond one call.
 *
 * Mapping (iOS event: ArkUI source):
 * - `willMoveToParent`, `viewDidLoad`, `didMoveToParent`: `aboutToAppear()`;
 * - `viewWillAppear`, `viewIsAppearing`, `viewDidAppear`: `onPageShow()`
 *   (ArkUI has no separate transition end, so the three fire back to back,
 *   `animated` false);
 * - `viewWillDisappear`, `viewDidDisappear`: `onPageHide()`;
 * - `viewDidLayoutSubviews`: `onAreaChange(old, new)` of the root component;
 *   `viewWillTransition`: the same call when the size changed;
 * - `viewSafeAreaInsetsDidChange`: `avoidAreaChanged(insets)` (window avoid
 *   areas, system bars and cutout);
 * - `traitCollectionDidChange`: `colorModeChanged(mode)`;
 * - `didReceiveMemoryWarning`: `memoryLevel(level)` from `UIAbility.onMemoryLevel`;
 * - teardown blocks: `aboutToDisappear()`.
 * - `viewWillLayoutSubviews`, `viewLayoutMarginsDidChange`: no source.
 * - design v5: `windowAttached()` / `windowDetached()` (`onAttach` / `onDetach`) fire the window moves;
 *   `visibleAreaChanged(visible)` (`onVisibleAreaChange`) and `onPageShow` / `onPageHide` fire
 *   `didEnterScreen` / `didLeaveScreen` on transitions; `scrollStarted()` / `scrollStopped()`
 *   (`onScrollStart` / `onScrollStop`) fire the scroll events (ArkUI has no drag-end event, so a stop
 *   is a drag end without deceleration and the end of scrolling).
 */
export class LifecycleController<T extends object> {
  readonly registry: LifecycleRegistry;
  private readonly owner: T;
  private attached = false;
  private detached = false;
  private shown = false;
  private lastSize: Rect | undefined;
  private lastInsets: Insets | undefined;
  private lastColorMode: string | undefined;
  private onScreen = false;

  constructor(owner: T) {
    this.owner = owner;
    this.registry = LifecycleRegistry.of(owner);
    this.registry.hookInstalled = true;
  }

  /** True once `aboutToDisappear()` ran: the teardown blocks are done and new ones never run. */
  get isDetached(): boolean {
    return this.detached;
  }

  private around(event: LifecycleEvent, info: Partial<LifecycleInfo> = {}): void {
    this.registry.fireAutomatic(event, 'beforeSuper', info);
    this.registry.fireAutomatic(event, 'afterSuper', info);
  }

  /** `onAttach()` of the component: it joined the window. */
  windowAttached(window?: unknown): void {
    this.around('willMoveToWindow', { window: window ?? null });
    this.around('didMoveToWindow', { window: window ?? null });
  }

  /** `onDetach()` of the component: it left the window. */
  windowDetached(): void {
    this.around('willMoveToWindow', { window: null });
    this.around('didMoveToWindow', { window: null });
    this.setScreenVisible(false);
  }

  /** `onVisibleAreaChange`: the component is (not) visible enough on screen. */
  visibleAreaChanged(visible: boolean): void {
    this.setScreenVisible(visible);
  }

  /** Fires `didEnterScreen` / `didLeaveScreen` on transitions only. */
  setScreenVisible(visible: boolean): void {
    if (this.onScreen === visible || this.detached) return;
    this.onScreen = visible;
    this.around(visible ? 'didEnterScreen' : 'didLeaveScreen');
  }

  /** `onScrollStart` of the scrollable component. */
  scrollStarted(scrollView?: unknown): void {
    this.around('scrollWillBeginDragging', { scrollView });
  }

  /** `onScrollStop` of the scrollable component. */
  scrollStopped(scrollView?: unknown): void {
    this.around('scrollDidEndDragging', { scrollView, willDecelerate: false });
    this.around('scrollDidEndScrolling', { scrollView });
  }

  /** `aboutToAppear()` of the page or component. */
  aboutToAppear(): void {
    if (this.attached) return;
    this.attached = true;
    this.around('willMoveToParent', { parentAttached: true });
    this.around('viewDidLoad');
    this.around('didMoveToParent', { parentAttached: true });
  }

  /** `onPageShow()`. Fires only when the page was hidden or never shown. */
  onPageShow(): void {
    if (this.shown || this.detached) return;
    this.shown = true;
    this.around('viewWillAppear', { animated: false });
    this.around('viewIsAppearing');
    this.around('viewDidAppear', { animated: false });
    this.setScreenVisible(true);
  }

  /** `onPageHide()`. */
  onPageHide(): void {
    if (!this.shown) return;
    this.shown = false;
    this.around('viewWillDisappear', { animated: false });
    this.around('viewDidDisappear', { animated: false });
    this.setScreenVisible(false);
  }

  /** `aboutToDisappear()`: move events, then the teardown blocks. */
  aboutToDisappear(): void {
    if (this.detached) return;
    this.onPageHide();
    this.detached = true;
    this.around('willMoveToParent', { parentAttached: false });
    this.around('didMoveToParent', { parentAttached: false });
    this.registry.runDealloc();
  }

  /** `onAreaChange(oldValue, newValue)` of the root component. */
  onAreaChange(_old: Rect, area: Rect): void {
    const size = { width: area.width, height: area.height };
    const resized = !this.lastSize || this.lastSize.width !== size.width || this.lastSize.height !== size.height;
    this.lastSize = size;
    if (resized) this.around('viewWillTransition', { size });
    this.around('viewDidLayoutSubviews');
  }

  /** The window avoid areas changed (system bars, cutout, keyboard excluded). */
  avoidAreaChanged(insets: Insets): void {
    const p = this.lastInsets;
    if (p && p.top === insets.top && p.left === insets.left && p.bottom === insets.bottom && p.right === insets.right) return;
    this.lastInsets = insets;
    this.around('viewSafeAreaInsetsDidChange', { previousInsets: p });
  }

  /** The color mode changed (`light` / `dark`), for example from `onConfigurationUpdate`. */
  colorModeChanged(mode: string): void {
    const previousColorScheme = this.lastColorMode;
    if (previousColorScheme === mode) return;
    this.lastColorMode = mode;
    if (previousColorScheme !== undefined) this.around('traitCollectionDidChange', { previousColorScheme });
  }

  /** `UIAbility.onMemoryLevel(level)`: only the critical level is a memory warning. */
  memoryLevel(level: number, criticalLevel = 2): void {
    if (level >= criticalLevel) this.around('didReceiveMemoryWarning');
  }
}
