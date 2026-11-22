import { forwardRef, useImperativeHandle, useRef, type ElementRef } from 'react';
import type { ColorValue, ViewProps } from 'react-native';
import NativeAnimationView, { Commands, type NativeProps } from './CyltabbarAnimationViewNativeComponent';

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

export type CYLAnimationViewProps = ViewProps & {
  /**
   * A file name in the app (iOS main bundle, Android assets), a path or a URL: `.riv`, `.json` (Lottie), `.pag`, `.gif`, `.svga`.
   */
  file: string;
  options?: CYLAnimationOptions;
  playing?: boolean;
  /**
   * Whether the item is selected: with `drivesAnimationPlayback`, selected plays once from the start, unselected rests.
   */
  selected?: boolean;
  /**
   * The speed, 1 by default; 0 or less keeps the file's own speed.
   */
  animationSpeed?: number;
  /**
   * Whether the animation loops.
   */
  animationLoops?: boolean;
  /**
   * Restarts the animation from the start whenever it changes.
   */
  animationRestartToken?: number;
  /**
   * Default true. False: the view applies none of the default rules and the host plays through the ref commands.
   */
  drivesAnimationPlayback?: boolean;
  /**
   * The icon size in points; omitted fills the view.
   */
  iconSize?: number;
  tintColor?: ColorValue;
  onAnimationLoaded?: () => void;
  onAnimationFailed?: () => void;
  onAnimationEnd?: () => void;
};

/**
 * The commands of a `CYLAnimationView`, through its ref.
 */
export type CYLAnimationViewHandle = {
  /**
   * Plays from the current progress.
   */
  play(): void;
  /**
   * Stops and shows `progress` (0 to 1) as a still frame.
   */
  stopAtProgress(progress: number): void;
  /**
   * Plays again from the start.
   */
  restart(): void;
};

/**
 * The props of the native view for the props of a `CYLAnimationView`: `source` is the file with its options, the end,
 * load and failure callbacks lose their (empty) event, `drivesAnimationPlayback` defaults to true.
 */
export function nativeAnimationProps({
  file,
  options,
  playing,
  onAnimationLoaded,
  onAnimationFailed,
  onAnimationEnd,
  drivesAnimationPlayback,
  ...rest
}: CYLAnimationViewProps): NativeProps {
  return {
    ...rest,
    source: animationURLWithOptions(file, options),
    playing: playing ?? false,
    drivesAnimationPlayback: drivesAnimationPlayback ?? true,
    onAnimationLoaded: onAnimationLoaded && (() => onAnimationLoaded()),
    onAnimationFailed: onAnimationFailed && (() => onAnimationFailed()),
    onAnimationEnd: onAnimationEnd && (() => onAnimationEnd()),
  };
}

/**
 * The ref commands over the native view `getNative()` returns (nothing happens while it is null).
 */
export function animationViewHandle(getNative: () => ElementRef<typeof NativeAnimationView> | null): CYLAnimationViewHandle {
  return {
    play: () => {
      const native = getNative();
      if (native) Commands.play(native);
    },
    stopAtProgress: (progress: number) => {
      const native = getNative();
      if (native) Commands.stopAtProgress(native, progress);
    },
    restart: () => {
      const native = getNative();
      if (native) Commands.restart(native);
    },
  };
}

/**
 * An animation played by CYLTabBarController's own engine (the one of the tab icons), whatever its library: Rive, Lottie,
 * PAG, GIF or SVGA, when the app has that library (iOS subspec, Android dependency). 由 CYLTabBarController 自己的引擎（Tab 图标所用）播放的动画。
 */
export const CYLAnimationView = forwardRef<CYLAnimationViewHandle, CYLAnimationViewProps>(function CYLAnimationView(props, ref) {
  const native = useRef<ElementRef<typeof NativeAnimationView>>(null);
  useImperativeHandle(ref, () => animationViewHandle(() => native.current), []);
  return <NativeAnimationView ref={native} {...nativeAnimationProps(props)} />;
});
