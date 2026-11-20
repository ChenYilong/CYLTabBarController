/**
 * [EN] The countdown of `CYLAnimatedItemView` (`itemStyle` `CYLAnimatedItemStyle.Countdown`), the HarmonyOS counterpart of iOS
 *      `CYLAnimatedItemView.style = .countdown` and Android `CYLAnimatedItemStyle.Countdown`: the "Get code" button of an SMS
 *      login. A state machine without any ArkUI or system API (the clock and the storage are given), tested in Node
 *      (test/CYLAnimatedItemCountdown.test.mjs). The same rules as on the other platforms:
 *      - the end is a time, not a counter: the seconds spent in the background count, because the time left is read from the
 *        local clock on every tick and when the app comes to the foreground (FIX: issue #1 of SMSCodeButton);
 *      - the start, the end and the longest duration are recorded; when the local clock is past the end, or was set back to
 *        before the start (a time left longer than the longest duration, one second of tolerance), the countdown is closed:
 *        the state is `finished` and a new countdown can start;
 *      - with a cache key the running countdown is kept in the storage, so a new item with the same key takes it up again
 *        after the app was ended in the background (no start callback).
 * [CN] `CYLAnimatedItemView` 的倒计时（`itemStyle` 为 `CYLAnimatedItemStyle.Countdown`），对应 iOS 的 `CYLAnimatedItemView.style = .countdown` 与
 *      Android 的 `CYLAnimatedItemStyle.Countdown`：短信登录的「获取验证码」按钮。不使用任何 ArkUI 或系统 API 的状态机（时钟与存储由外部传入），
 *      在 Node 中测试（test/CYLAnimatedItemCountdown.test.mjs）。规则与其他平台相同：
 *      - 结束是一个时间点，而不是计数器：后台度过的秒数计入，因为每次 tick 与 App 回到前台时都从本地时钟读取剩余时间（修复 SMSCodeButton 的 issue #1）；
 *      - 记录开始时间、结束时间与最长时长；本地时钟超过结束时间，或被调回到开始之前（剩余时间超过最长时长，允许 1 秒误差）时关闭倒计时：
 *        状态为 `finished`，可以重新开始；
 *      - 有缓存 key 时，运行中的倒计时保存到存储，App 在后台被结束后，相同 key 的新条目接续倒计时（不触发开始回调）。
 */

/** [EN] Not started. [CN] 未开始。 */
export const CYLCountdownIdle: number = 0;
/** [EN] Counting down. [CN] 倒计时中。 */
export const CYLCountdownRunning: number = 1;
/** [EN] The time is up. [CN] 时间到。 */
export const CYLCountdownFinished: number = 2;

/** [EN] The clock tolerance in ms. [CN] 时钟允许误差（毫秒）。 */
export const CYLCountdownToleranceMillis: number = 1000;
/** [EN] How often a running countdown reads the clock (ms). [CN] 运行中的倒计时读取时钟的间隔（毫秒）。 */
export const CYLCountdownTickIntervalMillis: number = 250;

/**
 * [EN] Where a running countdown is kept across a restart (the preferences of the app in the view). Values are strings.
 * [CN] 运行中的倒计时在重启之间的保存位置（视图中为 App 的 preferences）。值为字符串。
 */
export interface CYLAnimatedItemCountdownStorage {
  get(name: string): string | undefined;
  set(name: string, value: string): void;
  remove(name: string): void;
}

/**
 * [EN] What a countdown reports. [CN] 倒计时的报告。
 */
export interface CYLAnimatedItemCountdownListener {
  /** [EN] The state or the seconds shown changed: render. [CN] 状态或显示的秒数变化：重新渲染。 */
  onChanged(): void;
  /** [EN] The countdown started (not when a cached one is taken up again). [CN] 倒计时开始（接续缓存的倒计时时不触发）。 */
  onStarted(): void;
  /** [EN] The whole seconds left changed, once per second. [CN] 剩余整秒数变化，每秒一次。 */
  onTicked(remainingSeconds: number): void;
  /** [EN] The time is up, or the clock made the countdown invalid. [CN] 时间到，或时钟使倒计时失效。 */
  onFinished(): void;
}

/**
 * [EN] `format` with its `%d` (or `%ld`) replaced by `seconds`. [CN] 把 `format` 中的 `%d`（或 `%ld`）替换为 `seconds`。
 */
export function cylCountdownText(format: string, seconds: number): string {
  return format.split('%ld').join(seconds.toString()).split('%d').join(seconds.toString());
}

/**
 * [EN] The widest title a countdown shows (idle, finished, the running one with the widest digits of the duration), in vp,
 *      estimated from the font size (a CJK character is one em wide, any other 0.6 em), so the item keeps its width while the
 *      digits change. [CN] 倒计时会显示的最宽标题（待机、结束、以时长位数的最宽数字组成的倒计时），单位 vp，按字号估算
 *      （中日韩字符宽 1 em，其他字符 0.6 em），使条目在数字变化时保持宽度。
 */
export function cylCountdownTitleWidth(idle: string, running: string, finished: string, durationSeconds: number, fontSize: number): number {
  let digits: number = Math.max(1, Math.ceil(durationSeconds)).toString().length;
  let widest: number = Number('8'.repeat(digits));
  let width = (text: string): number => {
    let sum: number = 0;
    for (const ch of text) {
      let code: number = ch.codePointAt(0) ?? 0;
      let wide: boolean = (code >= 0x2e80 && code <= 0x9fff) || (code >= 0xac00 && code <= 0xd7af) || (code >= 0xff00 && code <= 0xffef);
      sum += wide ? 1 : 0.6;
    }
    return sum * fontSize;
  };
  return Math.ceil(Math.max(width(idle), width(finished), width(cylCountdownText(running, widest))));
}

export class CYLAnimatedItemCountdown {
  /** [EN] Where the countdown is. [CN] 倒计时所处的阶段。 */
  state: number = CYLCountdownIdle;
  /** [EN] The cache key; set it with `setCacheKey`. [CN] 缓存 key；通过 `setCacheKey` 设置。 */
  cacheKey: string = '';
  storage?: CYLAnimatedItemCountdownStorage;
  private now: () => number;
  private listener: CYLAnimatedItemCountdownListener;
  private startMillis: number = 0;
  private endMillis: number = 0;
  private durationMillis: number = 0;
  private shown: number = -1;

  constructor(now: () => number, storage: CYLAnimatedItemCountdownStorage | undefined, listener: CYLAnimatedItemCountdownListener) {
    this.now = now;
    this.storage = storage;
    this.listener = listener;
  }

  /** [EN] The whole seconds the title shows. [CN] 标题显示的整秒数。 */
  get shownSeconds(): number {
    return Math.max(this.shown, 0);
  }

  /** [EN] The whole seconds left (rounded up): 0 when it is not running. [CN] 剩余整秒数（向上取整）：未运行时为 0。 */
  get remainingSeconds(): number {
    if (this.state !== CYLCountdownRunning) {
      return 0;
    }
    let left: number = this.endMillis - this.now();
    return left > 0 ? Math.ceil(left / 1000) : 0;
  }

  /**
   * [EN] Sets the cache key: the old cache is dropped, the running countdown is kept under the new key, otherwise a cached
   *      one is taken up. [CN] 设置缓存 key：丢弃旧缓存；运行中的倒计时保存到新 key，否则接续缓存的倒计时。
   */
  setCacheKey(key: string): void {
    if (key === this.cacheKey) {
      return;
    }
    this.removeCache();
    this.cacheKey = key;
    if (this.state === CYLCountdownRunning) {
      this.saveCache();
    } else {
      this.restore();
    }
  }

  /** [EN] Starts (or restarts) for `seconds`; 0 or less resets. [CN] 开始（或重新开始）`seconds` 秒；0 或更小则重置。 */
  start(seconds: number): void {
    let duration: number = seconds * 1000;
    if (!(duration > 0)) {
      this.reset();
      return;
    }
    let begin: number = this.now();
    this.begin(begin, begin + duration, duration, true);
  }

  /** [EN] Stops and goes idle, with no finish callback. [CN] 停止并回到待机，不触发结束回调。 */
  reset(): void {
    this.state = CYLCountdownIdle;
    this.startMillis = 0;
    this.endMillis = 0;
    this.removeCache();
    this.listener.onChanged();
  }

  /**
   * [EN] Reads the clock: ticks when the whole seconds left changed, closes the countdown when the time is up or the clock is
   *      no longer plausible. Called by the timer and when the app comes to the foreground. [CN] 读取时钟：剩余整秒数变化时 tick；
   *      时间到或时钟不再合理时关闭倒计时。由定时器与 App 回到前台时调用。
   */
  refresh(): void {
    if (this.state !== CYLCountdownRunning) {
      return;
    }
    let current: number = this.now();
    let left: number = this.endMillis - current;
    if (left <= 0 || current - this.startMillis < -CYLCountdownToleranceMillis || left > this.durationMillis + CYLCountdownToleranceMillis) {
      this.finish();
      return;
    }
    let seconds: number = Math.min(Math.ceil(left / 1000), Math.ceil(this.durationMillis / 1000));
    if (seconds === this.shown) {
      return;
    }
    this.shown = seconds;
    this.listener.onChanged();
    this.listener.onTicked(seconds);
  }

  /**
   * [EN] Takes up a cached countdown that is still valid by the local clock (not over, not from the future, not longer than
   *      the longest duration it recorded); an invalid one is dropped. [CN] 接续按本地时钟仍然有效的缓存倒计时（未结束、不是来自未来、
   *      不超过其记录的最长时长）；无效的缓存被丢弃。
   */
  restore(): void {
    if (this.cacheKey.length === 0 || !this.storage || this.state === CYLCountdownRunning) {
      return;
    }
    let name: string = CYLAnimatedItemCountdown.cacheName(this.cacheKey);
    let text: string | undefined = this.storage.get(name);
    if (text === undefined) {
      return;
    }
    let parts: number[] = text.split(',').map((part: string) => Number(part));
    if (parts.length !== 3 || parts.some((part: number) => !Number.isFinite(part))) {
      this.storage.remove(name);
      return;
    }
    let start: number = parts[0];
    let end: number = parts[1];
    let duration: number = parts[2];
    let current: number = this.now();
    let valid: boolean = duration > 0 && end - current > 0 && current - start >= -CYLCountdownToleranceMillis &&
      end - current <= duration + CYLCountdownToleranceMillis;
    if (!valid) {
      this.storage.remove(name);
      return;
    }
    this.begin(start, end, duration, false);
  }

  private begin(start: number, end: number, duration: number, announcesStart: boolean): void {
    this.startMillis = start;
    this.endMillis = end;
    this.durationMillis = duration;
    this.state = CYLCountdownRunning;
    this.shown = -1;
    this.saveCache();
    this.listener.onChanged();
    if (announcesStart) {
      this.listener.onStarted();
    }
    this.refresh();
  }

  private finish(): void {
    this.state = CYLCountdownFinished;
    this.startMillis = 0;
    this.endMillis = 0;
    this.removeCache();
    this.listener.onChanged();
    this.listener.onFinished();
  }

  private saveCache(): void {
    if (this.cacheKey.length > 0 && this.storage) {
      this.storage.set(CYLAnimatedItemCountdown.cacheName(this.cacheKey), `${this.startMillis},${this.endMillis},${this.durationMillis}`);
    }
  }

  private removeCache(): void {
    if (this.cacheKey.length > 0 && this.storage) {
      this.storage.remove(CYLAnimatedItemCountdown.cacheName(this.cacheKey));
    }
  }

  private static cacheName(key: string): string {
    return `CYLAnimatedItemCountdown.${key}`;
  }
}
