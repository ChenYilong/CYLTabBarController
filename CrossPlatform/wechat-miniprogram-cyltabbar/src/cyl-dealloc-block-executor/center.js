const { LifecycleLog } = require('./log.js');

/** Options of `whileUserScrolls` and `addDeallocObserver`. */

/**
 * Global observers: one block that observes an event on every object, for
 * behavior that must not know its owners ("pause every animation while the user
 * scrolls"). Per-owner blocks run first, then the global ones, each group in
 * identifier order. Global observers never receive teardown events: the owner is
 * going away. A key replaces the observer added before under it.
 */
// WeakRef is not guaranteed on every Mini Program JS engine: without it the owner is held strongly.
const cylWeakRef = (o) => (typeof WeakRef === 'function' ? new WeakRef(o) : { deref: () => o });

class LifecycleCenter {
          static entries                = [];
          static nextIdentifier = 1;
          static          scrolling = new Set();

  /** True while any observed scroll source is dragging or decelerating. */
  static get isUserScrolling()          {
    for (const ref of [...LifecycleCenter.scrolling]) {
      if (ref.deref() === undefined) LifecycleCenter.scrolling.delete(ref);
    }
    return LifecycleCenter.scrolling.size > 0;
  }

  static addCallback         (event                , callback                      , options                = {})         {
    return LifecycleCenter.add(event, undefined, callback, options);
  }

  static addCustomCallback         (name        , callback                      , options                = {})         {
    return LifecycleCenter.add(null, name, callback, options);
  }

          static add(event                       , custom                    , callback                        , options               )         {
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

  /**
   * The ready-made version of "pause every animation while the user scrolls, resume afterwards": `pause` runs when any observed scroll
   * source starts to be dragged, `resume` when it stopped for good. Returns a function that removes both observers. The two
   * observers use the keys `<key>.pause` and `<key>.resume` (default key `cyl.scroll`), so calling it again replaces the earlier pair.
   */
  static whileUserScrolls(pause            , resume            , options             = {})             {
    const key = options.key ?? 'cyl.scroll';
    LifecycleCenter.addCallback('scrollWillBeginDragging',() => pause(), { key: `${key}.pause` });
    LifecycleCenter.addCallback('scrollDidEndScrolling',() => resume(), { key: `${key}.resume` });
    return() => {
      LifecycleCenter.cancelCallback({ key: `${key}.pause` });
      LifecycleCenter.cancelCallback({ key: `${key}.resume` });
    };
  }

  /** Cancels one observer by `identifier` or by `key`; true when one was removed. */
  static cancelCallback(target                                          )          {
    const before = LifecycleCenter.entries.length;
    LifecycleCenter.entries = LifecycleCenter.entries.filter((e) =>
      'identifier' in target ? e.identifier !== target.identifier : e.key !== target.key,
    );
    return LifecycleCenter.entries.length < before;
  }

          static deallocObservers                                                                                                                  = [];

  /**
   * Observes the teardown of every owner that has a registry, to know when any object goes away. The callback gets a description
   * (class name and `name` / `id`), never the owner: it is being destroyed. For logging and bookkeeping, not for cleanup.
   */
  static addDeallocObserver(callback                                                    , options             = {})         {
    if (options.key !== undefined) LifecycleCenter.deallocObservers = LifecycleCenter.deallocObservers.filter((o) => o.key !== options.key);
    const identifier = LifecycleCenter.nextIdentifier++;
    LifecycleCenter.deallocObservers.push({ identifier, key: options.key, callback });
    return identifier;
  }

  static cancelDeallocObserver(target                                          )          {
    const before = LifecycleCenter.deallocObservers.length;
    LifecycleCenter.deallocObservers = LifecycleCenter.deallocObservers.filter((o) =>
      'identifier' in target ? o.identifier !== target.identifier : o.key !== target.key,
    );
    return LifecycleCenter.deallocObservers.length < before;
  }

  /** Called by a registry when its owner's teardown blocks ran. */
  static dispatchDealloc(description        )       {
    const info                = { event: null, timing: 'end', isDealloc: true };
    LifecycleLog.log(() => `dealloc ${description}`);
    for (const o of [...LifecycleCenter.deallocObservers]) o.callback(description, info);
  }

  /** For tests: removes every observer and forgets the scroll state. */
  static reset()       {
    LifecycleCenter.entries = [];
    LifecycleCenter.deallocObservers = [];
    LifecycleCenter.scrolling.clear();
  }

  /** Called by a registry after the owner's own blocks of (event, timing) ran. */
  static dispatch(owner        , event                       , custom                    , timing                 , info               )       {
    if (event === 'scrollWillBeginDragging') LifecycleCenter.scrolling.add(cylWeakRef(owner));
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

module.exports = { LifecycleCenter };
