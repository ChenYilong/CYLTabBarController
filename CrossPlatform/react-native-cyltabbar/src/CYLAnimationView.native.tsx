import { useImperativeHandle, useRef, type ComponentRef, type Ref } from 'react';
import type { ColorValue, ViewProps } from 'react-native';
import NativeAnimationView, { Commands } from './CyltabbarAnimationViewNativeComponent';

/**
 * Options of an animation file, e.g. Rive's `artboard`, `stateMachine`, `input`, `duration`.
 */
export type CYLAnimationOptions = Record<string, string | number>;

/**
 * The URL of `file` with `options` in its fragment, sorted by name, like `CYLTabBarAnimationURLWithOptions()`.
 */
/**
 * [EN] Code-unit order, as Android's `toSortedMap()`, so both platforms build the same URL (`localeCompare` would not).
 * [CN] 按 UTF-16 码元排序，与 Android 的 `toSortedMap()` 相同，两个平台生成同样的 URL（`localeCompare` 做不到）。
 */
function compareCodeUnits(a: string, b: string): number {
  if (a === b) {
    return 0;
  }
  return a < b ? -1 : 1;
}

export function animationURLWithOptions(file: string, options: CYLAnimationOptions = {}): string {
  const base = file.split('#')[0]!;
  const pairs = Object.keys(options)
    .filter((name) => String(options[name]).length > 0)
    .sort(compareCodeUnits)
    .map((name) => `${encodeURIComponent(name)}=${encodeURIComponent(String(options[name]))}`);
  return pairs.length > 0 ? `${base}#${pairs.join('&')}` : base;
}

/**
 * [EN] The named constant of the capsule (1000 points): pass it to `itemCornerRadius` instead of a literal; the view treats it as
 *      exactly half the height. [CN] 胶囊的命名常量（1000 点）：传给 `itemCornerRadius`，视图把它当作恰好半高。
 */
export const cylAnimatedItemCornerRadiusCapsule = 1000;

/**
 * [EN] The commands of the native view, for a `CYLAnimationView` whose `drivesAnimationPlayback` is false (the cross-platform
 *      engine contract, docs/Animated-Item.md): `play()`, `stopAtProgress(progress)` and `restart()`.
 * [CN] 原生视图的命令，用于 `drivesAnimationPlayback` 为 false 的 `CYLAnimationView`（跨端引擎契约，见 docs/Animated-Item.md）：
 *      `play()`、`stopAtProgress(progress)`、`restart()`。
 */
export type CYLAnimationViewHandle = {
  /** Plays from the current progress. */
  play: () => void;
  /** Stops and shows the frame at `progress`, 0 (the first frame) to 1 (the last). */
  stopAtProgress: (progress: number) => void;
  /** Plays again from the start. */
  restart: () => void;
};

export type CYLAnimationViewProps = ViewProps & {
  /**
   * A file name in the app (iOS main bundle, Android assets), a path or a URL: `.riv`, `.json` (Lottie), `.pag`, `.gif`, `.svga`.
   */
  file: string;
  options?: CYLAnimationOptions;
  playing?: boolean;
  /** Whether the item is selected: a selected item rests on its last frame, an unselected one on its first. */
  selected?: boolean;
  /** The playback rate, 1 is the file's own speed. */
  animationSpeed?: number;
  /** Whether the animation plays again after each pass. */
  animationLoops?: boolean;
  /** Plays again from the start when it changes (the value at creation is not a restart). */
  animationRestartToken?: number;
  /** true (default): the view applies the default playback rules; false: the host plays through `ref`. */
  drivesAnimationPlayback?: boolean;
  /** Shows `image` instead of the last frame when a play-once pass ends (default false); the next play shows the animation again. */
  showsImageWhenAnimationEnds?: boolean;
  /**
   * The still image `showsImageWhenAnimationEnds` shows: a file name in the app (iOS main bundle, Android assets), a path or a
   * URL, resolved like `file`. Without it the end shows the library's placeholder (the HarmonyOS rule).
   */
  image?: string;
  /** The icon's side in points; unset fills the view. */
  iconSize?: number;
  /** Tints the icon and an animation that takes a tint. */
  tintColor?: ColorValue;
  /**
   * The background: `flat` (default) fills with `itemBackgroundColor`; `liquidGlass` draws Liquid Glass tinted with it, where the
   * platform draws Liquid Glass (iOS 26 and later, Android 12 and later with the glass available); elsewhere the view stays flat.
   */
  itemBackgroundStyle?: 'flat' | 'liquidGlass';
  /** The solid fill when flat, the glass tint when `liquidGlass`; unset for none. */
  itemBackgroundColor?: ColorValue;
  /**
   * The corner radius in points, limited to half the height; 0 is square, `cylAnimatedItemCornerRadiusCapsule` (1000) a capsule.
   * Unset: a capsule for `liquidGlass`, square for `flat`.
   */
  itemCornerRadius?: number;
  /** The border width in points; default 0. */
  itemBorderWidth?: number;
  /** The border color; unset for none. */
  itemBorderColor?: ColorValue;
  /** The animation is in place (a local file once parsed, a download once it arrived). */
  onAnimationLoaded?: () => void;
  /** The animation cannot play: a missing or corrupted file, a parse error, a failed download. */
  onAnimationFailed?: () => void;
  /** A play-once pass ended (not on a stop, not while looping). */
  onAnimationEnd?: () => void;
  /** The commands `play`, `stopAtProgress` and `restart`. */
  ref?: Ref<CYLAnimationViewHandle>;
};

/**
 * An animation played by CYLTabBarController's own engine (the one of the tab icons), whatever its library: Rive, Lottie,
 * PAG, GIF or SVGA, when the app has that library (iOS subspec, Android dependency). 由 CYLTabBarController 自己的引擎（Tab 图标所用）播放的动画。
 *
 * The names follow the cross-platform engine contract (docs/Animated-Item.md, "Engine API across platforms"); both native
 * halves wrap `CYLAnimatedItemView`, there is no engine logic in JavaScript.
 * 名称遵循跨端引擎契约（docs/Animated-Item.md「跨端引擎 API」）；两个原生半边都封装 `CYLAnimatedItemView`，JavaScript 中没有引擎逻辑。
 */
export function CYLAnimationView({
  file,
  options,
  playing,
  onAnimationLoaded,
  onAnimationFailed,
  onAnimationEnd,
  ref,
  ...rest
}: CYLAnimationViewProps) {
  const native = useRef<ComponentRef<typeof NativeAnimationView>>(null);
  useImperativeHandle(
    ref,
    () => ({
      play: () => native.current && Commands.play(native.current),
      stopAtProgress: (progress: number) => native.current && Commands.stopAtProgress(native.current, progress),
      restart: () => native.current && Commands.restart(native.current),
    }),
    []
  );
  return (
    <NativeAnimationView
      {...rest}
      ref={native}
      source={animationURLWithOptions(file, options)}
      playing={playing ?? false}
      onAnimationLoaded={onAnimationLoaded ? () => onAnimationLoaded() : undefined}
      onAnimationFailed={onAnimationFailed ? () => onAnimationFailed() : undefined}
      onAnimationEnd={onAnimationEnd ? () => onAnimationEnd() : undefined}
    />
  );
}
