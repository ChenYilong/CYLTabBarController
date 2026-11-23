import type { LifecycleCallback, LifecycleEvent, LifecycleInfo, LifecycleTiming } from './types';

interface GlobalEntry {
  identifier: number;
  callback: LifecycleCallback<any>;
  event: LifecycleEvent | null;
  custom: string | undefined;
  timing: LifecycleTiming;
  ownerType: (abstract new (...args: any[]) => object) | undefined;
  key: string | undefined;
}

export interface CenterOptions {
  timing?: LifecycleTiming;
  /** Only owners that are instances of this class are observed. */
  ownerType?: abstract new (...args: any[]) => object;
  key?: string;
}

/**
 * Global observers: one block that observes an event on every object, for
 * behavior that must not know its owners ("pause every animation while the user
 * scrolls"). Per-owner blocks run first, then the global ones, each group in
 * identifier order. Global observers never receive teardown events: the owner is
 * going away. A key replaces the observer added before under it.
 */
export class LifecycleCenter {
  private static entries: GlobalEntry[] = [];
  private static nextIdentifier = 1;
  private static readonly scrolling = new Set<WeakRef<object>>();

  /** True while any observed scroll source is dragging or decelerating. */
  static get isUserScrolling(): boolean {
    for (const ref of [...LifecycleCenter.scrolling]) {
      if (ref.deref() === undefined) LifecycleCenter.scrolling.delete(ref);
    }
    return LifecycleCenter.scrolling.size > 0;
  }

  static addCallback<T = any>(event: LifecycleEvent, callback: LifecycleCallback<T>, options: CenterOptions = {}): number {
    return LifecycleCenter.add(event, undefined, callback, options);
  }

  static addCustomCallback<T = any>(name: string, callback: LifecycleCallback<T>, options: CenterOptions = {}): number {
    return LifecycleCenter.add(null, name, callback, options);
  }

  private static add(event: LifecycleEvent | null, custom: string | undefined, callback: LifecycleCallback<any>, options: CenterOptions): number {
    if (options.key !== undefined) LifecycleCenter.entries = LifecycleCenter.entries.filter((e) => e.key !== options.key);
    const identifier = LifecycleCenter.nextIdentifier++;
    LifecycleCenter.entries.push({
      identifier,
      callback,
      event,
      custom,
      timing: options.timing ?? 'afterSuper',
      ownerType: options.ownerType,
      key: options.key,
    });
    return identifier;
  }

  /** Cancels one observer by `identifier` or by `key`; true when one was removed. */
  static cancelCallback(target: { identifier: number } | { key: string }): boolean {
    const before = LifecycleCenter.entries.length;
    LifecycleCenter.entries = LifecycleCenter.entries.filter((e) =>
      'identifier' in target ? e.identifier !== target.identifier : e.key !== target.key,
    );
    return LifecycleCenter.entries.length < before;
  }

  /** For tests: removes every observer and forgets the scroll state. */
  static reset(): void {
    LifecycleCenter.entries = [];
    LifecycleCenter.scrolling.clear();
  }

  /** Called by a registry after the owner's own blocks of (event, timing) ran. */
  static dispatch(owner: object, event: LifecycleEvent | null, custom: string | undefined, timing: LifecycleTiming, info: LifecycleInfo): void {
    if (event === 'scrollWillBeginDragging') LifecycleCenter.scrolling.add(new WeakRef(owner));
    if (event === 'scrollDidEndScrolling') {
      for (const ref of [...LifecycleCenter.scrolling]) {
        const o = ref.deref();
        if (o === undefined || o === owner) LifecycleCenter.scrolling.delete(ref);
      }
    }
    if (LifecycleCenter.entries.length === 0) return;
    const snapshot = LifecycleCenter.entries
      .filter((e) => e.event === event && e.custom === custom && (custom !== undefined || e.timing === timing))
      .sort((a, b) => a.identifier - b.identifier);
    for (const e of snapshot) {
      if (!LifecycleCenter.entries.includes(e)) continue;
      if (e.ownerType !== undefined && !(owner instanceof e.ownerType)) continue;
      e.callback(owner, e.identifier, { ...info, event, timing, customEvent: custom });
    }
  }
}
