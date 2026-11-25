/**
 * [EN] The options of a Rive file (after "#" or "?" in its path, parsed by CYLAnimatedItemSource) and the pure helpers of the
 *      Rive engine (unit tested with Node: cylanimateditem/test/CYLAnimatedItemRiveOptions.test.mjs). The names are the
 *      iOS ones; cyltabbar's CYLTabBarAnimationOptionRive... keys have the same values.
 * [CN] Rive 文件的选项（路径中 "#" 或 "?" 之后，由 CYLAnimatedItemSource 解析）以及 Rive 引擎的纯函数（用 Node 做单元测试）。名称与 iOS 相同；
 *      cyltabbar 的 CYLTabBarAnimationOptionRive... 键取值相同。
 */
export class CYLAnimatedItemRiveOption {
  /** [EN] The artboard. [CN] 画板。 */
  static readonly ARTBOARD: string = 'artboard';
  /** [EN] The state machine. [CN] 状态机。 */
  static readonly STATE_MACHINE: string = 'stateMachine';
  /** [EN] The view model boolean set while the item plays ("active"). [CN] 播放期间设为 true 的 view model 布尔属性（"active"）。 */
  static readonly ACTIVE_PROPERTY: string = 'active';
  /** [EN] Seconds the boolean stays true ("1"); "0" keeps it until stop. [CN] 布尔值保持 true 的秒数（"1"）；"0" 表示保持到停止。 */
  static readonly ACTIVE_DURATION: string = 'duration';
  /** [EN] A view model trigger fired instead. [CN] 改为触发的 view model trigger。 */
  static readonly TRIGGER_PROPERTY: string = 'trigger';
  /**
   * [EN] "#RRGGBB" or "#RRGGBBAA" (as iOS) set on the view model color property "color" when the file loads (iOS / Android
   *      CYLTabBarAnimationOptionRiveColor); applyColors overrides it, and restoring returns to it.
   * [CN] 文件加载时设置到 view model 颜色属性 "color" 的 "#RRGGBB" 或 "#RRGGBBAA"（与 iOS 相同）（iOS / Android 的 CYLTabBarAnimationOptionRiveColor）；
   *      applyColors 可覆盖它，恢复时回到它。
   */
  static readonly COLOR: string = 'color';
  /** [EN] A state machine boolean input (legacy files). [CN] 状态机布尔输入（旧版文件）。 */
  static readonly INPUT: string = 'input';
  /** [EN] A state machine trigger input (legacy files). [CN] 状态机 trigger 输入（旧版文件）。 */
  static readonly TRIGGER_INPUT: string = 'triggerInput';
  /** [EN] A linear animation played instead of a state machine. [CN] 改为播放的线性动画。 */
  static readonly ANIMATION: string = 'animation';
  /** [EN] "1" plays the file with no view model. [CN] "1" 表示不使用 view model 播放。 */
  static readonly LEGACY_RUNTIME: string = 'legacy';
  /** [EN] A number input set to the next of `values` on each play (house.riv: "Rooms"). [CN] 每次播放设为 `values` 中下一个值的数字输入。 */
  static readonly NUMBER_INPUT: string = 'numberInput';
  /** [EN] The values the number input steps through, "3,4,5,6", cycling; without it, +1. [CN] 数字输入依次使用的值，循环；没有时 +1。 */
  static readonly NUMBER_VALUES: string = 'values';
}

/** [EN] The view model color property the `color` option sets. [CN] `color` 选项设置的 view model 颜色属性。 */
export const CYL_RIVE_COLOR_PROPERTY_PATH: string = 'color';

/**
 * [EN] The color the `color` option asks for as Rive's ARGB integer: "#RRGGBB" (opaque) or "#RRGGBBAA", the "#" optional
 *      (iOS CYLRiveTabBarItemAnimationView `color(hex:)`); undefined when there is none, it does not parse, or the file
 *      plays without its view model (legacy runtime), as on iOS.
 * [CN] `color` 选项要求的颜色（Rive 的 ARGB 整数）："#RRGGBB"（不透明）或 "#RRGGBBAA"，"#" 可省略（与 iOS 相同）；没有该选项、
 *      无法解析或文件不使用 view model（旧版运行时）时为 undefined。
 */
export function cylRiveOptionColor(option: (name: string) => string | undefined): number | undefined {
  const digits = (option(CYLAnimatedItemRiveOption.COLOR) ?? '').trim().replace(/^#/, '');
  if (!/^([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(digits) || cylRiveUsesLegacyRuntime(option)) {
    return undefined;
  }
  const rgba = digits.length === 6 ? digits + 'FF' : digits;
  const unsigned = Number.parseInt(rgba.substring(6, 8) + rgba.substring(0, 6), 16);
  return unsigned > 0x7FFFFFFF ? unsigned - 0x100000000 : unsigned;
}

/**
 * [EN] The value after `current` in `values` ("3,4,5,6"), cycling (an unknown value starts the list); without values,
 *      `current + 1`. As on iOS, Android and the WeChat Mini Program.
 * [CN] `values`（"3,4,5,6"）中 `current` 之后的值，循环（未知值从列表开头开始）；没有值时为 `current + 1`。与 iOS、Android、微信小程序一致。
 */
export function cylRiveNextNumber(values: string | undefined, current: number | undefined): number {
  const list: number[] = (values ?? '').split(',').map((value: string) => value.trim()).filter((value: string) => value !== '')
    .map(Number).filter((value: number) => Number.isFinite(value));
  if (list.length === 0) {
    return (current ?? 0) + 1;
  }
  const index = current === undefined ? -1 : list.indexOf(current);
  return list[(index + 1) % list.length];
}

/**
 * [EN] Whether a file plays without its view model: "legacy=1", or any state machine input or linear animation option.
 * [CN] 文件是否不使用 view model 播放："legacy=1"，或任一状态机输入或线性动画选项。
 */
export function cylRiveUsesLegacyRuntime(option: (name: string) => string | undefined): boolean {
  return option(CYLAnimatedItemRiveOption.LEGACY_RUNTIME) === '1'
    || option(CYLAnimatedItemRiveOption.INPUT) !== undefined
    || option(CYLAnimatedItemRiveOption.TRIGGER_INPUT) !== undefined
    || option(CYLAnimatedItemRiveOption.ANIMATION) !== undefined
    || option(CYLAnimatedItemRiveOption.NUMBER_INPUT) !== undefined;
}

/** [EN] Seconds the boolean stays true (the `duration` option, "1" by default). [CN] 布尔值保持 true 的秒数（`duration` 选项，默认 "1"）。 */
export function cylRiveActiveDuration(value: string | undefined): number {
  const seconds = Number(value ?? '1');
  return Number.isFinite(seconds) && seconds >= 0 ? seconds : 1;
}

/** [EN] The NO window of a restart lasts at least this long (a frame), ... [CN] 重新播放的 NO 窗口至少持续这么久（一帧），…… */
export const CYL_RIVE_MINIMUM_OFF_MS: number = 50;
/** [EN] ... and at most this long, for a machine that never settles. [CN] ……至多这么久，用于永不稳定的状态机。 */
export const CYL_RIVE_MAXIMUM_OFF_MS: number = 1500;

/**
 * [EN] The cap of the NO window of a restart: 1500 ms for an input held true (`activeDuration` 0), otherwise the input's
 *      duration (seconds) between 50 ms and 1500 ms, so a machine that never settles does not delay a 0.3 s pass by the full
 *      1.5 s. As iOS `CYLRiveInputPass.offWindowCap` and Android `CYLRiveInputPass.offWindowCapMilliseconds`.
 * [CN] 重新播放的 NO 窗口的上限：保持为 true 的输入（`activeDuration` 为 0）为 1500 ms，否则为输入的时长（秒）折算的毫秒数，范围在 50 ms 与
 *      1500 ms 之间，永不稳定的状态机不会让 0.3 秒的一遍白等 1.5 秒。与 iOS `CYLRiveInputPass.offWindowCap`、Android
 *      `CYLRiveInputPass.offWindowCapMilliseconds` 相同。
 */
export function cylRiveOffWindowCapMs(activeDuration: number = 0): number {
  if (activeDuration <= 0 || Number.isNaN(activeDuration)) {
    return CYL_RIVE_MAXIMUM_OFF_MS;
  }
  return Math.min(CYL_RIVE_MAXIMUM_OFF_MS, Math.max(CYL_RIVE_MINIMUM_OFF_MS, Math.round(activeDuration * 1000)));
}

/**
 * [EN] Does the NO window of a restart end now? It lasts until the state machine has settled, so its NO pass is seen
 *      (menu_button.riv shows its X for about 0.5 s), within the minimum and `cylRiveOffWindowCapMs(activeDuration)`. As iOS
 *      `CYLRiveInputPass.offWindowEnds`.
 * [CN] 重新播放的 NO 窗口现在是否结束？它持续到状态机稳定，使 NO 的那一遍被看到（menu_button.riv 约 0.5 秒显示 X），范围在最小值与
 *      `cylRiveOffWindowCapMs(activeDuration)` 之间。与 iOS `CYLRiveInputPass.offWindowEnds` 相同。
 */
export function cylRiveOffWindowEnds(elapsedMs: number, isSettled: boolean, activeDuration: number = 0): boolean {
  return elapsedMs >= cylRiveOffWindowCapMs(activeDuration) || (elapsedMs >= CYL_RIVE_MINIMUM_OFF_MS && isSettled);
}
