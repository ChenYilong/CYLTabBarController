export type LogSink = (message: string) => void;

/**
 * Debug log of the lifecycle moments (design v5). Off by default: turn it on while developing, read what fires on which owner,
 * in which order, and how many blocks ran. Every message is built lazily, so the disabled path costs one boolean check.
 *
 *   LifecycleLog.enabled = true;                       // prints through `sink`
 *   LifecycleLog.sink = (message) => myLogger(message); // your own destination
 */
export class LifecycleLog {
  static enabled = false;
  static sink: LogSink = (message) => console.log(message);

  static log(message: () => string): void {
    if (LifecycleLog.enabled) LifecycleLog.sink(`[CYLLifecycle] ${message()}`);
  }

  /** A short name for an owner: its class name, plus `name` or `id` when it has one. */
  static describe(owner: unknown): string {
    if (owner === null || owner === undefined) return 'nil';
    const o = owner as { constructor?: { name?: string }; name?: unknown; id?: unknown };
    const type = o.constructor?.name ?? typeof owner;
    const tag = o.name ?? o.id;
    return tag === undefined ? type : `${type}(${String(tag)})`;
  }
}

/** Well-known custom event names posted by the components (the library never posts them itself). */
export const AnimationEvents = {
  didStart: 'cyl.animation.didStart',
  didPause: 'cyl.animation.didPause',
  didResume: 'cyl.animation.didResume',
  didStop: 'cyl.animation.didStop',
} as const;

export const BadgeEvents = {
  didShow: 'cyl.badge.didShow',
  didClear: 'cyl.badge.didClear',
  didBecomeReady: 'cyl.badge.didBecomeReady',
  animationDidStart: 'cyl.badge.animationDidStart',
  animationDidStop: 'cyl.badge.animationDidStop',
} as const;
