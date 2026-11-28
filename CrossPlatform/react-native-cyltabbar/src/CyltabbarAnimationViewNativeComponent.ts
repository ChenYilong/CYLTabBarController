import {
  codegenNativeCommands,
  codegenNativeComponent,
  type CodegenTypes,
  type ColorValue,
  type HostComponent,
  type ViewProps,
} from 'react-native';
import type * as React from 'react';

/**
 * [EN] No payload: the three animation events only say that it happened (HarmonyOS's `onAnimationLoaded`, `onAnimationFailed`,
 *      `onAnimationEnd`). [CN] 没有数据：三个动画事件只表示事件发生（鸿蒙的 `onAnimationLoaded`、`onAnimationFailed`、`onAnimationEnd`）。
 */
type AnimationEvent = Readonly<{}>;

/**
 * [EN] The file that cannot be shown, as configured, and why: "not found", "unreadable", "decode failed" or "engine library
 *      missing" (`CYLAnimatedItemView.onResourceMissing`). [CN] 无法显示的文件（按配置给出）及原因。
 */
type ResourceMissingEvent = Readonly<{ resource: string; reason: string }>;

/**
 * [EN] The cross-platform engine contract, with the names frozen in docs/Animated-Item.md ("Engine API across platforms"):
 *      props `source` and `playing` as before, plus `selected`, `animationSpeed`, `animationLoops`, `animationRestartToken`,
 *      `drivesAnimationPlayback`, `showsImageWhenAnimationEnds`, `image`, `iconSize`, `tintColor`, `animationTint`, `animationDarkTint`, `animationRenderingMode` and the item background `itemBackgroundStyle`, `itemBackgroundColor`, `itemCornerRadius`, `itemBorderWidth`, `itemBorderColor`; the events `onAnimationLoaded`, `onAnimationFailed` and
 *      `onAnimationEnd`; the commands `play`, `stopAtProgress` and `restart`. Both native halves wrap `CYLAnimatedItemView`.
 * [CN] 跨端引擎契约，名称已在 docs/Animated-Item.md（「跨端引擎 API」）中冻结：属性 `source`、`playing` 不变，新增 `selected`、
 *      `animationSpeed`、`animationLoops`、`animationRestartToken`、`drivesAnimationPlayback`、`iconSize`、`tintColor`；事件
 *      `onAnimationLoaded`、`onAnimationFailed`、`onAnimationEnd`；命令 `play`、`stopAtProgress`、`restart`。两个原生半边都封装 `CYLAnimatedItemView`。
 */
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
   * Whether the item is selected: a selected item rests on its last frame, an unselected one on its first.
   */
  selected?: CodegenTypes.WithDefault<boolean, false>;
  /**
   * The playback rate, 1 is the file's own speed.
   */
  animationSpeed?: CodegenTypes.WithDefault<CodegenTypes.Float, 1>;
  /**
   * Whether the animation plays again after each pass.
   */
  animationLoops?: CodegenTypes.WithDefault<boolean, false>;
  /**
   * Plays again from the start when it changes (the value at creation is not a restart).
   */
  animationRestartToken?: CodegenTypes.WithDefault<CodegenTypes.Int32, 0>;
  /**
   * true (default): the view applies the default playback rules; false: the host plays through the commands.
   */
  drivesAnimationPlayback?: CodegenTypes.WithDefault<boolean, true>;
  /**
   * Shows the still image instead of the last frame when a play-once pass ends.
   */
  showsImageWhenAnimationEnds?: CodegenTypes.WithDefault<boolean, false>;
  /**
   * The still image shown by `showsImageWhenAnimationEnds` after a play-once pass, resolved exactly like `source`: a URL, a
   * path or a file name in the app (iOS main bundle, Android assets). Without it the end shows the library's placeholder
   * (the HarmonyOS rule); with `showsImageWhenAnimationEnds` off the last frame stays.
   */
  image?: string;
  /**
   * The icon's side in points; 0 fills the view.
   */
  iconSize?: CodegenTypes.WithDefault<CodegenTypes.Float, 0>;
  /**
   * The icon color, optional. Unset (undefined) is the built-in default, never a forced color: label-like when normal, the view's
   * inherited tint when selected. Going from set to unset resets the native value to nil.
   */
  tintColor?: ColorValue;
  /**
   * The animation tint (tint spec v2): "title" or "#RRGGBB" / "#RRGGBBAA"; unset (empty) is not set. Forwarded to the item's
   * `animationTint`.
   */
  animationTint?: string;
  /**
   * The Dark Mode color of a fixed `animationTint` ("#RRGGBB" / "#RRGGBBAA"); unset (empty) is not set. Forwarded to the item's
   * `animationDarkTint`.
   */
  animationDarkTint?: string;
  /**
   * How a file is tinted while `animationTint` is unset (tint spec v2): `automatic` (default) tints only one-color files,
   * `alwaysTemplate` always, `alwaysOriginal` never. Forwarded to the item's `animationRenderingMode`.
   */
  animationRenderingMode?: CodegenTypes.WithDefault<'automatic' | 'alwaysTemplate' | 'alwaysOriginal', 'automatic'>;
  /**
   * The item's background: `flat` (default) fills with `itemBackgroundColor`; `liquidGlass` draws Liquid Glass tinted with it
   * (only where the platform draws Liquid Glass; elsewhere the view stays flat).
   */
  itemBackgroundStyle?: CodegenTypes.WithDefault<'flat' | 'liquidGlass', 'flat'>;
  /**
   * The solid fill when flat, the glass tint when `liquidGlass`; unset for none.
   */
  itemBackgroundColor?: ColorValue;
  /**
   * The corner radius in points, limited to half the height; a negative number (the default) is not set: a capsule for
   * `liquidGlass`, square for `flat`. 1000 (`cylAnimatedItemCornerRadiusCapsule`) is exactly a capsule.
   */
  itemCornerRadius?: CodegenTypes.WithDefault<CodegenTypes.Float, -1>;
  /**
   * The space between the outer border and the content, left and right only, in points; a negative number (the default) is not set:
   * 14 (`cylAnimatedItemLiquidGlassContentInset`) where Liquid Glass is really drawn, 0 for `flat`. Any number wins, including 0.
   */
  itemContentHorizontalInset?: CodegenTypes.WithDefault<CodegenTypes.Float, -1>;
  /**
   * The border width in points.
   */
  itemBorderWidth?: CodegenTypes.WithDefault<CodegenTypes.Float, 0>;
  /**
   * The border color; unset for none.
   */
  itemBorderColor?: ColorValue;
  /**
   * The item's badge (docs/Animated-Item-Badge-CrossPlatform.md, phase 2), drawn by the native `CYLAnimatedItemView` itself. Codegen cannot
   * say `string | null`, so the JavaScript side sends three internal props: `badgeValue` (the text; '' with `badgeHidden` false is a dot),
   * `badgeHidden` (true, the default: no badge) and `badgeAttributesJSON` (the style keys of `CYLBadgeAttributeKey` as JSON; '' for none).
   * Written statically, not run on a device yet.
   */
  badgeValue?: CodegenTypes.WithDefault<string, ''>;
  badgeHidden?: CodegenTypes.WithDefault<boolean, true>;
  badgeAttributesJSON?: CodegenTypes.WithDefault<string, ''>;
  /**
   * Reserves the badge's overhang when measuring (default false: the badge is not measured).
   */
  reservesBadgeSpace?: CodegenTypes.WithDefault<boolean, false>;
  onAnimationLoaded?: CodegenTypes.DirectEventHandler<AnimationEvent>;
  onAnimationFailed?: CodegenTypes.DirectEventHandler<AnimationEvent>;
  onAnimationEnd?: CodegenTypes.DirectEventHandler<AnimationEvent>;
  onResourceMissing?: CodegenTypes.DirectEventHandler<ResourceMissingEvent>;
}

type ComponentType = HostComponent<NativeProps>;

interface NativeCommands {
  play: (viewRef: React.ElementRef<ComponentType>) => void;
  stopAtProgress: (viewRef: React.ElementRef<ComponentType>, progress: CodegenTypes.Float) => void;
  restart: (viewRef: React.ElementRef<ComponentType>) => void;
}

export const Commands: NativeCommands = codegenNativeCommands<NativeCommands>({
  supportedCommands: ['play', 'stopAtProgress', 'restart'],
});

export default codegenNativeComponent<NativeProps>('CyltabbarAnimationView') as ComponentType;
