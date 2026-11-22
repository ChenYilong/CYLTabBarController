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
    this.around('willMoveToParent', { parentAttached: true });
    this.around('viewDidLoad');
    this.around('didMoveToParent', { parentAttached: true });
  }

  onShow() {
    if (this.shown || this.detached) return;
    this.shown = true;
    this.around('viewWillAppear', { animated: false });
    this.around('viewIsAppearing');
    if (this.ready) this.around('viewDidAppear', { animated: false });
  }

  onReady() {
    if (this.ready || this.detached) return;
    this.ready = true;
    if (this.shown) this.around('viewDidAppear', { animated: false });
  }

  onHide() {
    if (!this.shown) return;
    this.shown = false;
    this.around('viewWillDisappear', { animated: false });
    this.around('viewDidDisappear', { animated: false });
  }

  onUnload() {
    if (this.detached) return;
    this.onHide();
    this.detached = true;
    this.around('willMoveToParent', { parentAttached: false });
    this.around('didMoveToParent', { parentAttached: false });
    this.registry.runDealloc();
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
  return out;
}

module.exports = { LifecycleController, withLifecycle };
