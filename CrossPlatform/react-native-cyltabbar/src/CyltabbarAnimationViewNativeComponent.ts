import type * as React from 'react';
import {
  codegenNativeCommands,
  codegenNativeComponent,
  type CodegenTypes,
  type ColorValue,
  type HostComponent,
  type ViewProps,
} from 'react-native';

type AnimationEvent = Readonly<{}>;

export interface NativeProps extends ViewProps {
  /**
   * The animation file: a URL, a path or a file name in the app (iOS main bundle, Android assets), with its options in
   * the fragment, as `CYLTabBarAnimationURLWithOptions()` writes them ("icons.riv#artboard=CHAT&input=active").
   */
  source?: string;
  /**
   * Plays when true, stops when false.
   */
  playing?: CodegenTypes.WithDefault<boolean, false>;
  /**
   * Whether the item is selected: with `drivesAnimationPlayback`, selected plays once from the start, unselected rests.
   */
  selected?: CodegenTypes.WithDefault<boolean, false>;
  /**
   * The speed, 1 by default; 0 or less keeps the file's own speed.
   */
  animationSpeed?: CodegenTypes.WithDefault<CodegenTypes.Float, 1>;
  /**
   * Whether the animation loops.
   */
  animationLoops?: CodegenTypes.WithDefault<boolean, false>;
  /**
   * Restarts the animation from the start whenever it changes (the value at creation is not a restart).
   */
  animationRestartToken?: CodegenTypes.WithDefault<CodegenTypes.Int32, 0>;
  /**
   * False: the view applies none of the default rules and the host plays through the commands.
   */
  drivesAnimationPlayback?: CodegenTypes.WithDefault<boolean, true>;
  /**
   * The icon size in points; 0 fills the view.
   */
  iconSize?: CodegenTypes.WithDefault<CodegenTypes.Float, 0>;
  /**
   * The tint of the icon (where the engine takes one).
   */
  tintColor?: ColorValue;
  onAnimationLoaded?: CodegenTypes.DirectEventHandler<AnimationEvent>;
  onAnimationFailed?: CodegenTypes.DirectEventHandler<AnimationEvent>;
  onAnimationEnd?: CodegenTypes.DirectEventHandler<AnimationEvent>;
}

type ComponentType = HostComponent<NativeProps>;

interface NativeCommands {
  play(viewRef: React.ElementRef<ComponentType>): void;
  stopAtProgress(viewRef: React.ElementRef<ComponentType>, progress: CodegenTypes.Float): void;
  restart(viewRef: React.ElementRef<ComponentType>): void;
}

export const Commands: NativeCommands = codegenNativeCommands<NativeCommands>({
  supportedCommands: ['play', 'stopAtProgress', 'restart'],
});

export default codegenNativeComponent<NativeProps>('CyltabbarAnimationView') as ComponentType;
