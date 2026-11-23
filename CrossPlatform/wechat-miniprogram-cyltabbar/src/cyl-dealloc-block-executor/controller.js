const { LifecycleRegistry } = require('./registry.js');

/**
 * Fires the lifecycle events of a Mini Program Page or Component from the
 * callbacks the framework already calls (push model).
 *
 * Mapping (iOS event: Mini Program source):
 * - willMoveToParent, viewDidLoad, didMoveToParent: onLoad;
 * - viewWillAppear, viewIsAppearing: onShow; viewDidAppear: onReady the first
 *   time, straight after onShow later (onReady fires once per page);
 * - viewWillDisappear, viewDidDisappear: onHide;
 * - viewWillTransition: onResize(size); traitCollectionDidChange:
 *   themeChanged(theme) from wx.onThemeChange;
 * - didReceiveMemoryWarning: memoryWarning() from wx.onMemoryWarning;
 * - teardown blocks: onUnload.
 * - design v5: onLoad / onUnload fire the window moves; onShow / onHide and screenVisible(visible) (observeScreen(selector) wires an
 *   IntersectionObserver) fire didEnterScreen / didLeaveScreen on transitions; onPageScroll(event) fires the scroll events
 *   (no drag-end event exists: the first scroll event begins, a quiet period of scrollEndDelay ms ends);
 * - viewWillLayoutSubviews, viewDidLayoutSubviews, viewSafeAreaInsetsDidChange,
 *   viewLayoutMarginsDidChange: no source (the framework has no layout event
 *   and no insets event; safe area is read once with wx.getWindowInfo).
 */
class LifecycleController {
  constructor(owner) {
    this.owner = owner;
    this.registry = LifecycleRegistry.of(owner);
    this.registry.hookInstalled = true;
    this.shown = false;
    this.ready = false;
    this.detached = false;
    this.lastTheme = undefined;
    this.onScreen = false;
    this.scrolling = false;
    this.scrollTimer = undefined;
    /** Milliseconds without a scroll event that end scrolling. */
    this.scrollEndDelay = 150;
  }

  /** True once `onUnload()` ran: the teardown blocks are done and new ones never run. */
  get isDetached() {
    return this.detached;
  }

  around(event, info = {}) {
    this.registry.fireAutomatic(event, 'beforeSuper', info);
    this.registry.fireAutomatic(event, 'afterSuper', info);
  }

  onLoad() {
    if (this.loaded) return;
    this.loaded = true;
    this.around('willMoveToWindow', { window: this.owner });
    this.around('didMoveToWindow', { window: this.owner });
    this.around('willMoveToParent', { parentAttached: true });
    this.around('viewDidLoad');
    this.around('didMoveToParent', { parentAttached: true });
  }

  onShow() {
    if (this.shown || this.detached) return;
    this.shown = true;
    this.around('viewWillAppear', { animated: false });
    this.around('viewIsAppearing');
    if (this.ready) {
      this.around('viewDidAppear', { animated: false });
      this.screenVisible(true);
    }
  }

  onReady() {
    if (this.ready || this.detached) return;
    this.ready = true;
    if (this.shown) {
      this.around('viewDidAppear', { animated: false });
      this.screenVisible(true);
    }
  }

  onHide() {
    if (!this.shown) return;
    this.shown = false;
    this.around('viewWillDisappear', { animated: false });
    this.around('viewDidDisappear', { animated: false });
    this.screenVisible(false);
  }

  onUnload() {
    if (this.detached) return;
    this.onHide();
    this.detached = true;
    if (this.scrollTimer !== undefined) clearTimeout(this.scrollTimer);
    this.around('willMoveToWindow', { window: null });
    this.around('didMoveToWindow', { window: null });
    this.around('willMoveToParent', { parentAttached: false });
    this.around('didMoveToParent', { parentAttached: false });
    this.registry.runDealloc();
  }

  /** Fires didEnterScreen / didLeaveScreen on transitions only (also from a wx.createIntersectionObserver callback). */
  screenVisible(visible) {
    if (this.onScreen === visible || this.detached) return;
    this.onScreen = visible;
    this.around(visible ? 'didEnterScreen' : 'didLeaveScreen');
  }

  /**
   * Reports the screen events of the node `selector` (inside the owner, like `createSelectorQuery`) from a `wx.createIntersectionObserver`:
   * `didEnterScreen` when any part of it is inside the viewport, `didLeaveScreen` when none is. `options.thresholds` (default `[0, 0.01]`)
   * and `options.margins` go to the observer. Returns a function that stops observing. `api` is `wx` (injected for tests).
   */
  observeScreen(selector, options = {}, api = typeof wx !== 'undefined' ? wx : undefined) {
    if (!api || typeof api.createIntersectionObserver !== 'function') return () => {}
    const observer = api.createIntersectionObserver(this.owner, { thresholds: options.thresholds || [0, 0.01] });
    observer.relativeToViewport(options.margins || {}).observe(selector, (result) => this.screenVisible(result.intersectionRatio > 0));
    return () => observer.disconnect();
  }

  /** The page or component `onPageScroll(event)`; there is no drag-end event, so a quiet period of `scrollEndDelay` ms ends scrolling. */
  onPageScroll(event) {
    if (this.detached) return;
    if (!this.scrolling) {
      this.scrolling = true;
      this.around('scrollWillBeginDragging', { scrollView: event });
    }
    if (this.scrollTimer !== undefined) clearTimeout(this.scrollTimer);
    this.scrollTimer = setTimeout(() => this.endScrolling(event), this.scrollEndDelay);
  }

  endScrolling(event) {
    if (!this.scrolling) return;
    this.scrolling = false;
    this.around('scrollDidEndDragging', { scrollView: event, willDecelerate: false });
    this.around('scrollDidEndScrolling', { scrollView: event });
  }

  onResize(size) {
    this.around('viewWillTransition', { size: { width: size.windowWidth ?? size.width, height: size.windowHeight ?? size.height } });
  }

  themeChanged(theme) {
    const previousColorScheme = this.lastTheme;
    if (previousColorScheme === theme) return;
    this.lastTheme = theme;
    if (previousColorScheme !== undefined) this.around('traitCollectionDidChange', { previousColorScheme });
  }

  memoryWarning() {
    this.around('didReceiveMemoryWarning');
  }
}

/**
 * Wraps the options of `Page({...})` (Page only: a Component's `lifetimes` and
 * `pageLifetimes` are not wrapped, forward them to a controller by hand) so the controller sees every handler, then calls the original.
 * Returns the options with `cyl` (the controller) added after onLoad.
 */
function withLifecycle(options) {
  const out = { ...options };
  const controllerOf = (page) => (page.cylController ??= new LifecycleController(page));
  const wrap = (name, call) => {
    const original = options[name];
    out[name] = function (...args) {
      const controller = controllerOf(this);
      if (name === 'onLoad') call(controller, args);
      const result = original?.apply(this, args);
      if (name !== 'onLoad') call(controller, args);
      return result;
    };
  };
  wrap('onLoad', (c) => c.onLoad());
  wrap('onShow', (c) => c.onShow());
  wrap('onReady', (c) => c.onReady());
  wrap('onHide', (c) => c.onHide());
  wrap('onUnload', (c) => c.onUnload());
  wrap('onResize', (c, a) => c.onResize(a[0] ?? {}));
  wrap('onPageScroll', (c, a) => c.onPageScroll(a[0] ?? {}));
  return out;
}

module.exports = { LifecycleController, withLifecycle };
