/**
 * [EN] cyl-dealloc-block-executor: the WeChat Mini Program (JavaScript) port of the Kotlin `CYLLifecycleCallbacks` and of the iOS
 *      `CYLCallbackModel`. Lifecycle callbacks (addCallback) and dealloc callbacks (willDealloc) share one identifier sequence and
 *      one key space. Identifiers ascend from 1 (0 is illegal). Callbacks run in identifier order over a snapshot, so a callback
 *      can add or cancel callbacks. Nothing here observes the garbage collector: dealloc runs from the `detached` lifetime
 *      (cylLifecycleBehavior does it) or when the owner calls dealloc(). No dependencies; ES2017.
 * [CN] cyl-dealloc-block-executor：Kotlin 版 `CYLLifecycleCallbacks`（以及 iOS 的 `CYLCallbackModel`）的微信小程序（JavaScript）移植。
 *      生命周期回调（addCallback）与 dealloc 回调（willDealloc）共用一个标识符序列和一个 key 空间。标识符从 1 递增（0 非法）。
 *      回调按标识符顺序在快照上运行，因此回调中可以添加或取消回调。不监听垃圾回收：dealloc 在 `detached` 生命周期运行
 *      （由 cylLifecycleBehavior 完成），或由拥有者调用 dealloc()。无依赖；ES2017。
 */
'use strict';

/**
 * [EN] The identifier no callback ever gets (0). [CN] 任何回调都不会得到的标识符（0）。
 */
const cylDeallocCallbackIllegalIdentifier = 0;

/**
 * [EN] The events a callback can wait for, as numbers so that rearm(event) and rearm(key) share one method. CREATED, ATTACHED,
 *      READY, MOVED, DETACHED are Component lifetimes; SHOW, HIDE, RESIZE are pageLifetimes; LAYOUT is manual only (the owner
 *      calls perform(LAYOUT) after it laid out). DETACHED is followed by the willDealloc callbacks.
 * [CN] 回调可以等待的事件，用数字表示，这样 rearm(event) 与 rearm(key) 共用一个方法。CREATED、ATTACHED、READY、MOVED、DETACHED 是组件
 *      生命周期；SHOW、HIDE、RESIZE 是页面生命周期；LAYOUT 仅手动分发。DETACHED 之后运行 willDealloc 回调。
 */
const CYLLifecycleEvent = Object.freeze({
  CREATED: 1,
  ATTACHED: 2,
  READY: 3,
  MOVED: 4,
  DETACHED: 5,
  SHOW: 6,
  HIDE: 7,
  RESIZE: 8,
  LAYOUT: 9,
});

/**
 * [EN] The name of an event, for logs. [CN] 事件名称，用于日志。
 */
function cylLifecycleEventName(event) {
  const name = Object.keys(CYLLifecycleEvent).find((key) => CYLLifecycleEvent[key] === event);
  return name || 'UNKNOWN';
}

/**
 * [EN] What a callback is told about the event: event (0 for an explicit dealloc without an event), isDealloc (true for a
 *      willDealloc callback) and extras (a Map of the arguments of a manual dispatch).
 * [CN] 回调得到的事件信息：event（没有事件的显式 dealloc 为 0）、isDealloc（willDealloc 回调为 true）与 extras（手动分发参数的 Map）。
 */
class CYLLifecycleInfo {
  constructor(event = 0, isDealloc = false, extras = new Map()) {
    this.event = event;
    this.isDealloc = isDealloc;
    this.extras = extras;
  }
}

/**
 * [EN] The callbacks of one owner (a component instance, a page). The owner is held strongly: the registry is a field of its
 *      owner. A callback receives (owner, id, info).
 * [CN] 一个拥有者（组件实例、页面）的回调集合。拥有者被强引用：注册表是拥有者的字段。回调的参数为 (owner, id, info)。
 */
class CYLLifecycleCallbacks {
  /**
   * [EN] owner: the object the callbacks belong to. [CN] owner：回调所属的对象。
   */
  constructor(owner) {
    this.owner = owner;
    // Ids ascend and a Map iterates in insertion order, so the iteration order is the identifier order.
    this.entries = new Map();
    this.keys = new Map();
    this.lastId = 0;
    this.deallocated = false;
  }

  /**
   * [EN] Adds a callback run at event; several per event run in the order they were added. options.invokeOnce: run once until
   *      rearm (or a replacement under the same key). options.key: replaces the callback added before under the same key; the
   *      replacement starts armed. Returns the identifier, or cylDeallocCallbackIllegalIdentifier after dealloc.
   * [CN] 添加在 event 时运行的回调；同一事件的多个回调按添加顺序运行。options.invokeOnce：运行一次，直到 rearm（或同 key 的替换）。
   *      options.key：替换此前同 key 的回调，替换者处于待命状态。返回标识符，dealloc 之后返回 0。
   */
  addCallback(event, callback, options = {}) {
    return this._add(event, false, options.invokeOnce === true, options.key, callback);
  }

  /**
   * [EN] Adds a callback run once when the owner is deallocated, in identifier order. options.key replaces the callback added
   *      before under the same key. Returns the identifier, or cylDeallocCallbackIllegalIdentifier after dealloc.
   * [CN] 添加拥有者 dealloc 时运行一次的回调，按标识符顺序。options.key 替换此前同 key 的回调。返回标识符，dealloc 之后返回 0。
   */
  willDealloc(callback, options = {}) {
    return this._add(0, true, false, options.key, callback);
  }

  _add(event, isDealloc, invokeOnce, key, callback) {
    if (this.deallocated) {
      return cylDeallocCallbackIllegalIdentifier;
    }
    const hasKey = typeof key === 'string';
    this.lastId += 1;
    const id = this.lastId;
    if (hasKey) {
      if (this.keys.has(key)) {
        this.entries.delete(this.keys.get(key));
      }
      this.keys.set(key, id);
    }
    this.entries.set(id, { id, event, isDealloc, invokeOnce, key: hasKey ? key : null, callback, fired: false });
    return id;
  }

  /**
   * [EN] Cancels one callback by identifier (number) or by key (string). Returns true once, false when nothing has this
   *      identifier or key (never added, cancelled, or 0). [CN] 按标识符（数字）或 key（字符串）取消一个回调。成功返回一次 true，之后返回 false。
   */
  cancel(idOrKey) {
    const id = typeof idOrKey === 'string' ? this.keys.get(idOrKey) : idOrKey;
    const entry = this.entries.get(id);
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
  cancelAll(event) {
    this.entries.forEach((entry, id) => {
      if (entry.key === null && !entry.isDealloc && entry.event === event) {
        this.entries.delete(id);
      }
    });
  }

  /**
   * [EN] Cancels the willDealloc callbacks added without a key. [CN] 取消没有 key 的 willDealloc 回调。
   */
  cancelAllWillDealloc() {
    this.entries.forEach((entry, id) => {
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
  rearm(keyOrEvent) {
    if (typeof keyOrEvent === 'string') {
      const entry = this.entries.get(this.keys.get(keyOrEvent));
      if (entry === undefined) {
        return false;
      }
      entry.fired = false;
      return true;
    }
    this.entries.forEach((entry) => {
      if (entry.key === null && !entry.isDealloc && entry.event === keyOrEvent) {
        entry.fired = false;
      }
    });
    return true;
  }

  /**
   * [EN] Runs the callbacks waiting for event now, in identifier order, over a snapshot. A callback cancelled by an earlier one
   *      of the same run does not run. info.event is filled in. [CN] 立即按标识符顺序在快照上运行等待 event 的回调；同一次运行中被前面回调取消的回调不会运行。
   */
  perform(event, info = new CYLLifecycleInfo()) {
    const run = [];
    this.entries.forEach((entry) => {
      if (!entry.isDealloc && entry.event === event && !(entry.invokeOnce && entry.fired)) {
        run.push(entry);
      }
    });
    run.forEach((entry) => {
      if (entry.invokeOnce) {
        entry.fired = true;
      }
    });
    const runInfo = new CYLLifecycleInfo(event, false, info.extras);
    run.forEach((entry) => {
      if (this.entries.get(entry.id) === entry) {
        entry.callback(this.owner, entry.id, runInfo);
      }
    });
  }

  /**
   * [EN] Runs the willDealloc callbacks once, in identifier order, then clears everything. A second call does nothing; cancel
   *      calls made by the callbacks have no effect. event (optional) is what the callbacks see in info.event.
   * [CN] 按标识符顺序运行一次 willDealloc 回调，然后清空。再次调用无效；回调中的 cancel 无效。event（可选）为回调在 info.event 中看到的值。
   */
  dealloc(event = 0) {
    if (this.deallocated) {
      return;
    }
    this.deallocated = true;
    const run = [];
    this.entries.forEach((entry) => {
      if (entry.isDealloc) {
        run.push(entry);
      }
    });
    this.entries.clear();
    this.keys.clear();
    const info = new CYLLifecycleInfo(event, true);
    run.forEach((entry) => entry.callback(this.owner, entry.id, info));
  }
}

/**
 * [EN] A Behavior that gives every component a registry in `this.cylLifecycle` (property name configurable): created in
 *      `created`, dispatches the Component lifetimes (created, attached, ready, moved, detached) and the pageLifetimes (show,
 *      hide, resize, with extras.size), and runs dealloc after the detached callbacks. Pass the global `Behavior`:
 *      `Component({ behaviors: [cylLifecycleBehavior(Behavior)] })`.
 * [CN] 为每个组件在 `this.cylLifecycle`（属性名可配置）上提供注册表的 Behavior：在 `created` 中创建，分发组件生命周期（created、attached、
 *      ready、moved、detached）与页面生命周期（show、hide、resize，extras.size 为尺寸），并在 detached 回调之后运行 dealloc。传入全局 `Behavior`。
 */
function cylLifecycleBehavior(behaviorFunction, property = 'cylLifecycle') {
  const dispatch = (component, event, extras) => {
    const registry = component[property];
    if (registry) {
      registry.perform(event, new CYLLifecycleInfo(event, false, extras));
    }
  };
  return behaviorFunction({
    lifetimes: {
      created() {
        this[property] = new CYLLifecycleCallbacks(this);
        dispatch(this, CYLLifecycleEvent.CREATED);
      },
      attached() {
        dispatch(this, CYLLifecycleEvent.ATTACHED);
      },
      ready() {
        dispatch(this, CYLLifecycleEvent.READY);
      },
      moved() {
        dispatch(this, CYLLifecycleEvent.MOVED);
      },
      detached() {
        dispatch(this, CYLLifecycleEvent.DETACHED);
        if (this[property]) {
          this[property].dealloc(CYLLifecycleEvent.DETACHED);
        }
      },
    },
    pageLifetimes: {
      show() {
        dispatch(this, CYLLifecycleEvent.SHOW);
      },
      hide() {
        dispatch(this, CYLLifecycleEvent.HIDE);
      },
      resize(size) {
        dispatch(this, CYLLifecycleEvent.RESIZE, new Map([['size', size]]));
      },
    },
  });
}

module.exports = {
  CYLLifecycleCallbacks,
  CYLLifecycleEvent,
  CYLLifecycleInfo,
  cylLifecycleEventName,
  cylLifecycleBehavior,
  cylDeallocCallbackIllegalIdentifier,
};
