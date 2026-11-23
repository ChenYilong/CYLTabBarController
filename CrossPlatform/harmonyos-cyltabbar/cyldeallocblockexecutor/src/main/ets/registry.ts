import { LifecycleCenter } from './center';
import { LifecycleLog } from './log';
import { allTimings } from './types';
import type { LifecycleCallback, LifecycleEvent, LifecycleInfo, LifecycleTiming } from './types';

interface Entry {
  identifier: number;
  callback: LifecycleCallback<any>;
  event: LifecycleEvent | null; // null: a teardown block or a custom event
  custom: string | undefined; // set: a custom event block
  timing: LifecycleTiming;
  invokeOnce: boolean;
  key: string | undefined;
  fired: boolean;
  cancelled: boolean;
}

type Kind = 'lifecycle' | 'custom' | 'dealloc';
const kindOf = (e: Entry): Kind => (e.event !== null ? 'lifecycle' : e.custom !== undefined ? 'custom' : 'dealloc');

export interface AddOptions {
  timing?: LifecycleTiming;
  invokeOnce?: boolean;
  key?: string;
}

const registries = new WeakMap<object, LifecycleRegistry>();

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
export class LifecycleRegistry {
  /** The registry of `owner`, created on first use. */
  static of(owner: object): LifecycleRegistry {
    let r = registries.get(owner);
    if (!r) {
      r = new LifecycleRegistry(owner);
      registries.set(owner, r);
    }
    return r;
  }

  private readonly owner: WeakRef<object>;
  private entries: Entry[] = [];
  private nextIdentifier = 1;
  private readonly manual = new Set<string>();
  private readonly performDepth = new Map<LifecycleEvent, number>();
  private forwards: { target: WeakRef<LifecycleRegistry>; events: Set<LifecycleEvent> | undefined }[] = [];

  /** Called when a block is added for `event` (the controller attaches its sources lazily). */
  onRegister: ((event: LifecycleEvent) => void) | undefined;

  /** The controller sets this once its automatic hooks fire `beforeSuper` / `afterSuper`. */
  hookInstalled = false;

  constructor(owner: object) {
    this.owner = new WeakRef(owner);
  }

  hasBlocksFor(event: LifecycleEvent): boolean {
    return this.entries.some((e) => e.event === event && !e.cancelled);
  }

  get blockCount(): number {
    return this.entries.filter((e) => !e.cancelled).length;
  }

  /** Removes the entries that match and marks them cancelled, so a running snapshot skips them. */
  private drop(match: (e: Entry) => boolean): void {
    for (const e of this.entries) if (match(e)) e.cancelled = true;
    this.entries = this.entries.filter((e) => !e.cancelled);
  }

  private removeKey(key: string | undefined, kind: Kind): void {
    if (key === undefined) return;
    this.drop((e) => e.key === key && kindOf(e) === kind);
  }

  // lifecycle blocks

  /** Adds a block for `event`; returns its identifier. */
  addLifecycleCallback<T = any>(
    event: LifecycleEvent,
    callback: LifecycleCallback<T>,
    options: AddOptions = {},
  ): number {
    this.removeKey(options.key, 'lifecycle');
    const identifier = this.nextIdentifier++;
    this.entries.push({
      identifier,
      callback,
      event,
      custom: undefined,
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
  cancelLifecycleCallback(target: { identifier: number } | { key: string }): boolean {
    return this.cancelOne(target, false);
  }

  // custom events

  /** Adds a block for the custom event `name` (a name the app or the core posts); returns its identifier. */
  addCustomCallback<T = any>(name: string, callback: LifecycleCallback<T>, options: { invokeOnce?: boolean; key?: string } = {}): number {
    this.removeKey(options.key, 'custom');
    const identifier = this.nextIdentifier++;
    this.entries.push({
      identifier,
      callback,
      event: null,
      custom: name,
      timing: 'afterSuper',
      invokeOnce: options.invokeOnce ?? false,
      key: options.key,
      fired: false,
      cancelled: false,
    });
    return identifier;
  }

  /** Runs the blocks of the custom event `name` (the owner's, then the global observers'), in identifier order. */
  postLifecycleEvent(name: string, userInfo?: Record<string, unknown>): void {
    const owner = this.owner.deref();
    if (owner === undefined) return;
    const info: LifecycleInfo = { event: null, timing: 'afterSuper', customEvent: name, userInfo };
    const snapshot = this.entries
      .filter((e) => e.custom === name && !(e.invokeOnce && e.fired))
      .sort((a, b) => a.identifier - b.identifier);
    LifecycleLog.log(() => `${LifecycleLog.describe(owner)} posts ${name}: ${snapshot.length} block(s)`);
    for (const e of snapshot) {
      if (e.cancelled || (e.invokeOnce && e.fired)) continue;
      if (e.invokeOnce) e.fired = true;
      e.callback(owner, e.identifier, { ...info });
    }
    for (const f of this.liveForwards(undefined)) f.firePosted(name, userInfo);
    LifecycleCenter.dispatch(owner, null, name, 'afterSuper', info);
  }

  /** Runs a posted event that came through a forward (the target's own blocks and the global observers). */
  private firePosted(name: string, userInfo?: Record<string, unknown>): void {
    this.postLifecycleEvent(name, userInfo);
  }

  // forwarding

  /**
   * Forwards the events fired on this owner to `target`'s registry (all events, or the given set), as an object that is
   * not a view gets the events of the view that shows it. The target is held weakly; forwarding to the same target again
   * replaces the earlier forward. Posted custom events are forwarded too.
   */
  forwardLifecycleEvents(target: LifecycleRegistry, events?: readonly LifecycleEvent[]): void {
    this.forwards = this.forwards.filter((f) => {
      const t = f.target.deref();
      return t !== undefined && t !== target;
    });
    this.forwards.push({ target: new WeakRef(target), events: events ? new Set(events) : undefined });
  }

  private liveForwards(event: LifecycleEvent | undefined): LifecycleRegistry[] {
    const live: LifecycleRegistry[] = [];
    this.forwards = this.forwards.filter((f) => f.target.deref() !== undefined);
    for (const f of this.forwards) {
      const t = f.target.deref();
      if (t !== undefined && (event === undefined || f.events === undefined || f.events.has(event))) live.push(t);
    }
    return live;
  }

  /** Cancels the blocks of `event` (and `timing` when given) that have no key. */
  cancelAllLifecycleCallbacks(event: LifecycleEvent, timing?: LifecycleTiming): void {
    this.drop((e) => e.event === event && e.key === undefined && (timing === undefined || e.timing === timing));
  }

  /** Lets the invoke-once blocks of `event` without a key run once more. */
  rearmLifecycleCallbacks(event: LifecycleEvent, timing?: LifecycleTiming): void {
    for (const e of this.entries) {
      if (e.event === event && e.key === undefined && (timing === undefined || e.timing === timing)) {
        e.fired = false;
      }
    }
  }

  /** Re-arms the one block added under `key`. */
  rearmLifecycleCallback(key: string): void {
    for (const e of this.entries) {
      if (kindOf(e) !== 'dealloc' && e.key === key) e.fired = false;
    }
  }

  // teardown blocks

  /** Adds a teardown block: it runs once, when the owner is torn down. */
  addDeallocCallback<T = any>(callback: LifecycleCallback<T>, options: { key?: string } = {}): number {
    this.removeKey(options.key, 'dealloc');
    const identifier = this.nextIdentifier++;
    this.entries.push({
      identifier,
      callback,
      event: null,
      custom: undefined,
      timing: 'end',
      invokeOnce: false,
      key: options.key,
      fired: false,
      cancelled: false,
    });
    return identifier;
  }

  cancelDeallocCallback(target: { identifier: number } | { key: string }): boolean {
    return this.cancelOne(target, true);
  }

  /** Cancels the teardown blocks that have no key. */
  cancelAllDeallocCallbacks(): void {
    this.drop((e) => kindOf(e) === 'dealloc' && e.key === undefined);
  }

  private cancelOne(target: { identifier: number } | { key: string }, dealloc: boolean): boolean {
    const hit = this.entries.find(
      (e) =>
        (kindOf(e) === 'dealloc') === dealloc &&
        ('identifier' in target ? e.identifier === target.identifier : e.key === target.key),
    );
    if (!hit) return false;
    hit.cancelled = true;
    this.entries = this.entries.filter((e) => e !== hit);
    return true;
  }

  /** Runs the teardown blocks in identifier order, once. The owner calls this when it is torn down. */
  runDealloc(): void {
    const owner = this.owner.deref();
    if (owner === undefined) return;
    const snapshot = this.entries.filter((e) => kindOf(e) === 'dealloc').sort((a, b) => a.identifier - b.identifier);
    this.entries = this.entries.filter((e) => kindOf(e) !== 'dealloc');
    LifecycleLog.log(() => `teardown ${LifecycleLog.describe(owner)}: ${snapshot.length} block(s)`);
    for (const e of snapshot) {
      if (e.cancelled) continue;
      e.callback(owner, e.identifier, { event: null, timing: 'end', isDealloc: true });
    }
    LifecycleCenter.dispatchDealloc(LifecycleLog.describe(owner));
  }

  // dispatch

  /** Declares that the owner dispatches `events` itself, for `timings` (all by default). */
  setManualLifecycleDispatch(
    manual: boolean,
    events: readonly LifecycleEvent[],
    timings: readonly LifecycleTiming[] = allTimings,
  ): void {
    for (const e of events) {
      for (const t of timings) {
        if (manual) this.manual.add(`${e}/${t}`);
        else this.manual.delete(`${e}/${t}`);
      }
    }
  }

  isManual(event: LifecycleEvent, timing: LifecycleTiming): boolean {
    return this.manual.has(`${event}/${timing}`);
  }

  /** True when the controller's automatic hook fires this (event, timing). */
  isAutomatic(event: LifecycleEvent, timing: LifecycleTiming): boolean {
    return this.hookInstalled && timing !== 'end' && !this.isManual(event, timing);
  }

  /** Fires the blocks of one (event, timing) for the automatic hooks; skips a timing declared manual. */
  fireAutomatic(event: LifecycleEvent, timing: LifecycleTiming, info: Partial<LifecycleInfo> = {}): void {
    if (this.isManual(event, timing)) return;
    this.fire(event, timing, info);
  }

  /** Fires the blocks of one (event, timing) by hand. The event must be declared manual first. */
  invokeLifecycleCallbacks(event: LifecycleEvent, timing: LifecycleTiming, info: Partial<LifecycleInfo> = {}): void {
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
    event: LifecycleEvent,
    parts: { callSuper: () => void; body: () => void; info?: Partial<LifecycleInfo> },
  ): void {
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

  private fire(event: LifecycleEvent, timing: LifecycleTiming, info: Partial<LifecycleInfo>): void {
    const owner = this.owner.deref();
    if (owner === undefined) return;
    const snapshot = this.entries
      .filter((e) => e.event === event && e.timing === timing && !(e.invokeOnce && e.fired))
      .sort((a, b) => a.identifier - b.identifier);
    LifecycleLog.log(() => `${LifecycleLog.describe(owner)} ${event}/${timing}: ${snapshot.length} block(s)`);
    for (const e of snapshot) {
      if (e.cancelled || (e.invokeOnce && e.fired)) continue;
      if (e.invokeOnce) e.fired = true;
      e.callback(owner, e.identifier, { ...info, event, timing });
    }
    const full: LifecycleInfo = { ...info, event, timing };
    for (const t of this.liveForwards(event)) t.fire(event, timing, info);
    LifecycleCenter.dispatch(owner, event, undefined, timing, full);
  }
}
