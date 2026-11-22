/**
 * [EN] The callbacks of one owner, the HarmonyOS (ArkTS) port of the Kotlin `CYLLifecycleCallbacks` (and of the iOS `CYLCallbackModel`):
 *      lifecycle callbacks (addCallback) and dealloc callbacks (willDealloc) share one identifier sequence and one key space.
 *      Identifiers ascend from 1 (0 is illegal). Callbacks run in identifier order over a snapshot, so a callback can add or
 *      cancel callbacks. Nothing here observes ArkUI or the garbage collector: the owner dispatches with perform() and calls
 *      dealloc() from aboutToDisappear().
 * [CN] 一个拥有者的回调集合，是 Kotlin 版 `CYLLifecycleCallbacks`（以及 iOS 的 `CYLCallbackModel`）的鸿蒙（ArkTS）移植：生命周期回调（addCallback）与
 *      dealloc 回调（willDealloc）共用一个标识符序列和一个 key 空间。标识符从 1 递增（0 非法）。回调按标识符顺序在快照上运行，因此回调中可以添加或取消回调。
 *      这里不监听 ArkUI 也不监听垃圾回收：拥有者用 perform() 分发，并在 aboutToDisappear() 中调用 dealloc()。
 * This file is plain TypeScript without ArkUI imports, so Node runs it in test/ (type stripping, Node 22.18+).
 */

/**
 * [EN] The identifier no callback ever gets (0). [CN] 任何回调都不会得到的标识符（0）。
 */
export const cylDeallocCallbackIllegalIdentifier: number = 0;

/**
 * [EN] The events a callback can wait for, the ArkUI custom component lifecycle. They are numbers, so that rearm(event) and
 *      rearm(key) can share one method. Use cylLifecycleEventName() for the name.
 *      ABOUT_TO_APPEAR: aboutToAppear (Android CREATE). PAGE_SHOW: onPageShow of an @Entry component (RESUME). PAGE_HIDE:
 *      onPageHide (PAUSE). BACK_PRESS: onBackPress (no Android event). ABOUT_TO_DISAPPEAR: aboutToDisappear (DESTROY); dealloc()
 *      runs the willDealloc callbacks after it. LAYOUT: manual only (the owner calls perform(LAYOUT) after it laid out).
 * [CN] 回调可以等待的事件，即 ArkUI 自定义组件的生命周期。事件是数字，这样 rearm(event) 与 rearm(key) 可以共用一个方法。名称见 cylLifecycleEventName()。
 */
export class CYLLifecycleEvent {
  static readonly ABOUT_TO_APPEAR: number = 1;
  static readonly PAGE_SHOW: number = 2;
  static readonly PAGE_HIDE: number = 3;
  static readonly BACK_PRESS: number = 4;
  static readonly ABOUT_TO_DISAPPEAR: number = 5;
  static readonly LAYOUT: number = 6;
}

/**
 * [EN] The name of an event, for logs. [CN] 事件名称，用于日志。
 */
export function cylLifecycleEventName(event: number): string {
  switch (event) {
    case CYLLifecycleEvent.ABOUT_TO_APPEAR: return 'ABOUT_TO_APPEAR';
    case CYLLifecycleEvent.PAGE_SHOW: return 'PAGE_SHOW';
    case CYLLifecycleEvent.PAGE_HIDE: return 'PAGE_HIDE';
    case CYLLifecycleEvent.BACK_PRESS: return 'BACK_PRESS';
    case CYLLifecycleEvent.ABOUT_TO_DISAPPEAR: return 'ABOUT_TO_DISAPPEAR';
    case CYLLifecycleEvent.LAYOUT: return 'LAYOUT';
    default: return 'UNKNOWN';
  }
}

/**
 * [EN] What a callback is told about the event. event: the event of this run (0 for an explicit dealloc without an event);
 *      isDealloc: true for a willDealloc callback; extras: arguments of a manual dispatch, free for the owner to define.
 * [CN] 回调得到的事件信息。event：本次运行的事件（没有事件的显式 dealloc 为 0）；isDealloc：willDealloc 回调为 true；extras：手动分发的参数，由拥有者定义。
 */
export class CYLLifecycleInfo {
  event: number;
  isDealloc: boolean;
  extras: Map<string, Object>;

  constructor(event: number = 0, isDealloc: boolean = false, extras: Map<string, Object> = new Map<string, Object>()) {
    this.event = event;
    this.isDealloc = isDealloc;
    this.extras = extras;
  }
}

/**
 * [EN] A callback with the owner's own type, the identifier of the callback and the info of the event.
 * [CN] 回调：拥有者（自己的类型）、回调的标识符与事件信息。
 */
export type CYLLifecycleCallback<T> = (owner: T, id: number, info: CYLLifecycleInfo) => void;

class CYLCallbackEntry<T> {
  id: number;
  event: number;
  isDealloc: boolean;
  invokeOnce: boolean;
  key: string | null;
  callback: CYLLifecycleCallback<T>;
  fired: boolean = false;

  constructor(id: number, event: number, isDealloc: boolean, invokeOnce: boolean, key: string | null, callback: CYLLifecycleCallback<T>) {
    this.id = id;
    this.event = event;
    this.isDealloc = isDealloc;
    this.invokeOnce = invokeOnce;
    this.key = key;
    this.callback = callback;
  }
}

/**
 * [EN] The callbacks of one owner. The owner is held strongly: the registry is a field of its owner, so there is no cycle with
 *      anything else. [CN] 一个拥有者的回调集合。拥有者被强引用：注册表是拥有者的字段，不会与其他对象形成环。
 */
export class CYLLifecycleCallbacks<T> {
  private readonly owner: T;
  // Ids ascend and a Map iterates in insertion order, so the iteration order is the identifier order.
  private readonly entries: Map<number, CYLCallbackEntry<T>> = new Map<number, CYLCallbackEntry<T>>();
  private readonly keys: Map<string, number> = new Map<string, number>();
  private lastId: number = 0;
  private deallocated: boolean = false;

  /**
   * [EN] owner: the object the callbacks belong to. [CN] owner：回调所属的对象。
   */
  constructor(owner: T) {
    this.owner = owner;
  }

  /**
   * [EN] Adds a callback run at event; several per event run in the order they were added. invokeOnce: run once until rearm
   *      (or a replacement under the same key). key: replaces the callback added before under the same key; the replacement
   *      starts armed. Returns the identifier, or cylDeallocCallbackIllegalIdentifier after dealloc. (Kotlin puts the callback
   *      last; ArkTS has no trailing lambda and optional parameters come last.)
   * [CN] 添加在 event 时运行的回调；同一事件的多个回调按添加顺序运行。invokeOnce：运行一次，直到 rearm（或同 key 的替换）。key：替换此前同 key 的回调，
   *      替换者处于待命状态。返回标识符，dealloc 之后返回 cylDeallocCallbackIllegalIdentifier。
   */
  addCallback(event: number, callback: CYLLifecycleCallback<T>, invokeOnce: boolean = false, key: string | null = null): number {
    return this.add(event, false, invokeOnce, key, callback);
  }

  /**
   * [EN] Adds a callback run once when the owner is deallocated (dealloc()), in identifier order. key replaces the callback
   *      added before under the same key. Returns the identifier, or cylDeallocCallbackIllegalIdentifier after dealloc.
   * [CN] 添加拥有者 dealloc() 时运行一次的回调，按标识符顺序。key 替换此前同 key 的回调。返回标识符，dealloc 之后返回 0。
   */
  willDealloc(callback: CYLLifecycleCallback<T>, key: string | null = null): number {
    return this.add(0, true, false, key, callback);
  }

  private add(event: number, isDealloc: boolean, invokeOnce: boolean, key: string | null, callback: CYLLifecycleCallback<T>): number {
    if (this.deallocated) {
      return cylDeallocCallbackIllegalIdentifier;
    }
    this.lastId += 1;
    const id: number = this.lastId;
    if (key !== null) {
      const previous: number | undefined = this.keys.get(key);
      if (previous !== undefined) {
        this.entries.delete(previous);
      }
      this.keys.set(key, id);
    }
    this.entries.set(id, new CYLCallbackEntry<T>(id, event, isDealloc, invokeOnce, key, callback));
    return id;
  }

  /**
   * [EN] Cancels one callback by identifier (number) or by key (string). Returns true once, false when nothing has this
   *      identifier or key (never added, cancelled, or 0). [CN] 按标识符（数字）或 key（字符串）取消一个回调。成功返回一次 true，之后返回 false。
   */
  cancel(idOrKey: number | string): boolean {
    let id: number | undefined;
    if (typeof idOrKey === 'string') {
      id = this.keys.get(idOrKey);
    } else {
      id = idOrKey;
    }
    if (id === undefined) {
      return false;
    }
    const entry: CYLCallbackEntry<T> | undefined = this.entries.get(id);
    if (entry === undefined) {
      return false;
    }
    this.entries.delete(id);
    if (entry.key !== null && this.keys.get(entry.key) === id) {
      this.keys.delete(entry.key);
    }
    return true;
  }

  /**
   * [EN] Cancels the lifecycle callbacks of event added without a key. Keyed callbacks belong to whoever holds the key.
   * [CN] 取消 event 下没有 key 的生命周期回调。有 key 的回调属于持有该 key 的一方。
   */
  cancelAll(event: number): void {
    this.entries.forEach((entry: CYLCallbackEntry<T>, id: number) => {
      if (entry.key === null && !entry.isDealloc && entry.event === event) {
        this.entries.delete(id);
      }
    });
  }

  /**
   * [EN] Cancels the willDealloc callbacks added without a key. [CN] 取消没有 key 的 willDealloc 回调。
   */
  cancelAllWillDealloc(): void {
    this.entries.forEach((entry: CYLCallbackEntry<T>, id: number) => {
      if (entry.key === null && entry.isDealloc) {
        this.entries.delete(id);
      }
    });
  }

  /**
   * [EN] Lets an invokeOnce callback run once more: by key (string; returns true when a callback has this key) or, for an
   *      event (number), the callbacks of that event added without a key (returns true). Keyed callbacks are re-armed by key.
   * [CN] 让 invokeOnce 回调再运行一次：按 key（字符串；有该 key 的回调时返回 true），或按事件（数字）重新待命该事件下没有 key 的回调（返回 true）。
   */
  rearm(keyOrEvent: string | number): boolean {
    if (typeof keyOrEvent === 'string') {
      const id: number | undefined = this.keys.get(keyOrEvent);
      const entry: CYLCallbackEntry<T> | undefined = id === undefined ? undefined : this.entries.get(id);
      if (entry === undefined) {
        return false;
      }
      entry.fired = false;
      return true;
    }
    this.entries.forEach((entry: CYLCallbackEntry<T>) => {
      if (entry.key === null && !entry.isDealloc && entry.event === keyOrEvent) {
        entry.fired = false;
      }
    });
    return true;
  }

  /**
   * [EN] Runs the callbacks waiting for event now, in identifier order, over a snapshot. A callback cancelled by an earlier
   *      one of the same run does not run. info.event is filled in. [CN] 立即按标识符顺序在快照上运行等待 event 的回调；同一次运行中被前面回调取消的回调不会运行。
   */
  perform(event: number, info: CYLLifecycleInfo = new CYLLifecycleInfo()): void {
    const run: CYLCallbackEntry<T>[] = [];
    this.entries.forEach((entry: CYLCallbackEntry<T>) => {
      if (!entry.isDealloc && entry.event === event && !(entry.invokeOnce && entry.fired)) {
        run.push(entry);
      }
    });
    for (const entry of run) {
      if (entry.invokeOnce) {
        entry.fired = true;
      }
    }
    const runInfo: CYLLifecycleInfo = new CYLLifecycleInfo(event, false, info.extras);
    for (const entry of run) {
      if (this.entries.get(entry.id) === entry) {
        entry.callback(this.owner, entry.id, runInfo);
      }
    }
  }

  /**
   * [EN] Runs the willDealloc callbacks once, in identifier order, then clears everything. A second call does nothing; cancel
   *      calls made by the callbacks have no effect. Call it from aboutToDisappear(); event (optional) is what the callbacks
   *      see in info.event. [CN] 按标识符顺序运行一次 willDealloc 回调，然后清空。再次调用无效；回调中的 cancel 无效。在 aboutToDisappear() 中调用；event 为回调在 info.event 中看到的值。
   */
  dealloc(event: number = 0): void {
    if (this.deallocated) {
      return;
    }
    this.deallocated = true;
    const run: CYLCallbackEntry<T>[] = [];
    this.entries.forEach((entry: CYLCallbackEntry<T>) => {
      if (entry.isDealloc) {
        run.push(entry);
      }
    });
    this.entries.clear();
    this.keys.clear();
    const info: CYLLifecycleInfo = new CYLLifecycleInfo(event, true);
    for (const entry of run) {
      entry.callback(this.owner, entry.id, info);
    }
  }
}
