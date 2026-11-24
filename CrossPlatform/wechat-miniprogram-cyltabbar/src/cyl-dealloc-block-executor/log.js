

/**
 * Debug log of the lifecycle moments (design v5). Off by default: turn it on while developing, read what fires on which owner,
 * in which order, and how many blocks ran. Every message is built lazily, so the disabled path costs one boolean check.
 *
 *   LifecycleLog.enabled = true;                       // prints through `sink`
 *   LifecycleLog.sink = (message) => myLogger(message); // your own destination
 */
class LifecycleLog {

  static log(message              )       {
    if (LifecycleLog.enabled) LifecycleLog.sink(`[CYLLifecycle] ${message()}`);
  }

  /** A short name for an owner: its class name, plus `name` or `id` when it has one. */
  static describe(owner         )         {
    if (owner === null || owner === undefined) return 'nil';
    const o = owner                                                                     ;
    const ctorName = o.constructor ? o.constructor.name : undefined;
    const type = ctorName != null ? ctorName : typeof owner;
    const tag = o.name != null ? o.name : o.id;
    return tag === undefined ? type : `${type}(${String(tag)})`;
  }
}

// Static fields are assigned here (no class-properties transform in WeChat DevTools' es6 compile).
LifecycleLog.enabled = false;
LifecycleLog.sink = (message) => console.log(message);

/** Well-known custom event names posted by the components (the library never posts them itself). */
const AnimationEvents = {
  didStart: 'cyl.animation.didStart',
  didPause: 'cyl.animation.didPause',
  didResume: 'cyl.animation.didResume',
  didStop: 'cyl.animation.didStop',
}         ;

const BadgeEvents = {
  didShow: 'cyl.badge.didShow',
  didClear: 'cyl.badge.didClear',
  didBecomeReady: 'cyl.badge.didBecomeReady',
  animationDidStart: 'cyl.badge.animationDidStart',
  animationDidStop: 'cyl.badge.animationDidStop',
}         ;

module.exports = { LifecycleLog, AnimationEvents, BadgeEvents };
