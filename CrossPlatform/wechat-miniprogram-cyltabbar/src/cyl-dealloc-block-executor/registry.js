const { allTimings } = require('./types.js');

const registries = new WeakMap();

/**
 * One registry per owner: the lifecycle blocks and the teardown blocks.
 *
 * The iOS rules (see `docs/Lifecycle-Callbacks.md`): one identifier counter for
 * every block; blocks run in identifier order from a snapshot, so a block can
 * add or cancel blocks; adding with a key replaces the block added before under
 * that key (the new block starts unfired; keys are separate for lifecycle and
 * teardown blocks); keyed blocks belong to their key holder: cancel-all and
 * re-arm by event skip them. No lock: JavaScript runs one thread.
 */
class LifecycleRegistry {
  /** The registry of `owner`, created on first use. */
  static of(owner        )                    {
    let r = registries.get(owner);
    if (!r) {
      r = new LifecycleRegistry(owner);
      registries.set(owner, r);
    }
    return r;
  }

                   owner                 ;
          entries          = [];
          nextIdentifier = 1;
                   manual = new Set();
                   performDepth = new Map();

  /** Called when a block is added for `event` (the controller attaches its sources lazily). */
  onRegister                                               ;

  /** The controller sets this once its automatic hooks fire `beforeSuper` / `afterSuper`. */
  hookInstalled = false;

  constructor(owner        ) {
    // WeakRef is not guaranteed on every Mini Program JS engine: without it the owner is held strongly (the page's own lifetime ends it with onUnload).
    this.owner = typeof WeakRef === 'function' ? new WeakRef(owner) : { deref: () => owner };
  }

  hasBlocksFor(event                )          {
    return this.entries.some((e) => e.event === event && !e.cancelled);
  }

  get blockCount()         {
    return this.entries.filter((e) => !e.cancelled).length;
  }

  /** Removes the entries that match and marks them cancelled, so a running snapshot skips them. */
          drop(match                       )       {
    for (const e of this.entries) if (match(e)) e.cancelled = true;
    this.entries = this.entries.filter((e) => !e.cancelled);
  }

          removeKey(key                    , dealloc         )       {
    if (key === undefined) return;
    this.drop((e) => e.key === key && (e.event === null) === dealloc);
  }

  // lifecycle blocks

  /** Adds a block for `event`; returns its identifier. */
  addLifecycleCallback         (
    event                ,
    callback                      ,
    options             = {},
  )         {
    this.removeKey(options.key, false);
    const identifier = this.nextIdentifier++;
    this.entries.push({
      identifier,
      callback,
      event,
      timing: options.timing ?? 'afterSuper',
      invokeOnce: options.invokeOnce ?? false,
      key: options.key,
      fired: false,
      cancelled: false,
    });
    this.onRegister?.(event);
    return identifier;
  }

  /** Cancels one block by `identifier` or by `key`; true when one was removed. */
  cancelLifecycleCallback(target                                          )          {
    return this.cancelOne(target, false);
  }

  /** Cancels the blocks of `event` (and `timing` when given) that have no key. */
  cancelAllLifecycleCallbacks(event                , timing                  )       {
    this.drop((e) => e.event === event && e.key === undefined && (timing === undefined || e.timing === timing));
  }

  /** Lets the invoke-once blocks of `event` without a key run once more. */
  rearmLifecycleCallbacks(event                , timing                  )       {
    for (const e of this.entries) {
      if (e.event === event && e.key === undefined && (timing === undefined || e.timing === timing)) {
        e.fired = false;
      }
    }
  }

  /** Re-arms the one block added under `key`. */
  rearmLifecycleCallback(key        )       {
    for (const e of this.entries) {
      if (e.event !== null && e.key === key) e.fired = false;
    }
  }

  // teardown blocks

  /** Adds a teardown block: it runs once, when the owner is torn down. */
  addDeallocCallback         (callback                      , options                   = {})         {
    this.removeKey(options.key, true);
    const identifier = this.nextIdentifier++;
    this.entries.push({
      identifier,
      callback,
      event: null,
      timing: 'end',
      invokeOnce: false,
      key: options.key,
      fired: false,
      cancelled: false,
    });
    return identifier;
  }

  cancelDeallocCallback(target                                          )          {
    return this.cancelOne(target, true);
  }

  /** Cancels the teardown blocks that have no key. */
  cancelAllDeallocCallbacks()       {
    this.drop((e) => e.event === null && e.key === undefined);
  }

          cancelOne(target                                          , dealloc         )          {
    const hit = this.entries.find(
      (e) =>
        (e.event === null) === dealloc &&
        ('identifier' in target ? e.identifier === target.identifier : e.key === target.key),
    );
    if (!hit) return false;
    hit.cancelled = true;
    this.entries = this.entries.filter((e) => e !== hit);
    return true;
  }

  /** Runs the teardown blocks in identifier order, once. The owner calls this when it is torn down. */
  runDealloc()       {
    const owner = this.owner.deref();
    if (owner === undefined) return;
    const snapshot = this.entries.filter((e) => e.event === null).sort((a, b) => a.identifier - b.identifier);
    this.entries = this.entries.filter((e) => e.event !== null);
    for (const e of snapshot) {
      if (e.cancelled) continue;
      e.callback(owner, e.identifier, { event: null, timing: 'end', isDealloc: true });
    }
  }

  // dispatch

  /** Declares that the owner dispatches `events` itself, for `timings` (all by default). */
  setManualLifecycleDispatch(
    manual         ,
    events                           ,
    timings                             = allTimings,
  )       {
    for (const e of events) {
      for (const t of timings) {
        if (manual) this.manual.add(`${e}/${t}`);
        else this.manual.delete(`${e}/${t}`);
      }
    }
  }

  isManual(event                , timing                 )          {
    return this.manual.has(`${event}/${timing}`);
  }

  /** True when the controller's automatic hook fires this (event, timing). */
  isAutomatic(event                , timing                 )          {
    return this.hookInstalled && timing !== 'end' && !this.isManual(event, timing);
  }

  /** Fires the blocks of one (event, timing) for the automatic hooks; skips a timing declared manual. */
  fireAutomatic(event                , timing                 , info                         = {})       {
    if (this.isManual(event, timing)) return;
    this.fire(event, timing, info);
  }

  /** Fires the blocks of one (event, timing) by hand. The event must be declared manual first. */
  invokeLifecycleCallbacks(event                , timing                 , info                         = {})       {
    if (!this.isManual(event, timing)) {
      throw new Error(`declare ${event} / ${timing} manual with setManualLifecycleDispatch first`);
    }
    this.fire(event, timing, info);
  }

  /**
   * Runs `callSuper`, then `body`, with the timings around them. With the
   * controller's hook the automatic timings come from the hook; this method
   * adds `end` after `body`, at the outermost level only and not when `end` is
   * declared manual. For an owner without a hook all three timings fire from
   * the outermost call.
   */
  performLifecycle(
    event                ,
    parts                                                                            ,
  )       {
    const depth = this.performDepth.get(event) ?? 0;
    const outermost = depth === 0;
    this.performDepth.set(event, depth + 1);
    try {
      if (!this.hookInstalled && outermost) this.fireAutomatic(event, 'beforeSuper', parts.info);
      parts.callSuper();
      if (!this.hookInstalled && outermost) this.fireAutomatic(event, 'afterSuper', parts.info);
      parts.body();
      if (outermost) this.fireAutomatic(event, 'end', parts.info);
    } finally {
      this.performDepth.set(event, depth);
    }
  }

          fire(event                , timing                 , info                        )       {
    const owner = this.owner.deref();
    if (owner === undefined) return;
    const snapshot = this.entries
      .filter((e) => e.event === event && e.timing === timing && !(e.invokeOnce && e.fired))
      .sort((a, b) => a.identifier - b.identifier);
    for (const e of snapshot) {
      if (e.cancelled || (e.invokeOnce && e.fired)) continue;
      if (e.invokeOnce) e.fired = true;
      e.callback(owner, e.identifier, { ...info, event, timing });
    }
  }
}

module.exports = { LifecycleRegistry };
