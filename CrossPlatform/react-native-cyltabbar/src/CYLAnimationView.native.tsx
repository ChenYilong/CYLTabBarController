import type { ViewProps } from 'react-native';
import NativeAnimationView from './CyltabbarAnimationViewNativeComponent';

/** Options of an animation file, e.g. Rive's `artboard`, `stateMachine`, `input`, `duration`. */
export type CYLAnimationOptions = Record<string, string | number>;

/** The URL of `file` with `options` in its fragment, sorted by name, like `CYLTabBarAnimationURLWithOptions()`. */
export function animationURLWithOptions(file: string, options: CYLAnimationOptions = {}): string {
  const base = file.split('#')[0]!;
  const pairs = Object.keys(options)
    .filter((name) => String(options[name]).length > 0)
    .sort()
    .map((name) => `${encodeURIComponent(name)}=${encodeURIComponent(String(options[name]))}`);
  return pairs.length > 0 ? `${base}#${pairs.join('&')}` : base;
}

export type CYLAnimationViewProps = ViewProps & {
  /** A file name in the app (iOS main bundle, Android assets), a path or a URL: `.riv`, `.json` (Lottie), `.pag`, `.gif`. */
  file: string;
  options?: CYLAnimationOptions;
  playing?: boolean;
};

/**
 * An animation played by CYLTabBarController's own engine (the one of the tab icons), whatever its library: Rive, Lottie,
 * PAG or GIF, when the app has that library (iOS subspec, Android dependency). 由 CYLTabBarController 自己的引擎（Tab 图标所用）播放的动画。
 */
export function CYLAnimationView({ file, options, playing, ...rest }: CYLAnimationViewProps) {
  return <NativeAnimationView {...rest} source={animationURLWithOptions(file, options)} playing={playing ?? false} />;
}
