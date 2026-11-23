import {
  codegenNativeComponent,
  type CodegenTypes,
  type HostComponent,
  type ViewProps,
} from 'react-native';

type TabSelectEvent = Readonly<{
  index: CodegenTypes.Int32;
  identifier: string;
}>;

type PlusButtonPressEvent = Readonly<{
  context: string;
}>;

type TabLongPressEvent = Readonly<{
  index: CodegenTypes.Int32;
  identifier: string;
  title: string;
}>;

type MemoryWarningEvent = Readonly<{
  report: string;
}>;

type LoginStateEvent = Readonly<{
  loggedIn: boolean;
}>;

type TabBarLayoutEvent = Readonly<{
  height: CodegenTypes.Double;
}>;

type ManifestApplyEvent = Readonly<{
  source: string;
}>;

type ManifestFailEvent = Readonly<{
  message: string;
}>;

type LifecycleMomentEvent = Readonly<{
  name: string;
  userInfo: string;
}>;

export interface NativeProps extends ViewProps {
  /**
   * The configuration of CYLTabBarController, as JSON (docs/Configuration-File.md).
   */
  configuration?: string;
  /**
   * The selected tab; -1 leaves the selection to the tab bar.
   */
  selectedIndex?: CodegenTypes.WithDefault<CodegenTypes.Int32, -1>;
  /**
   * One value per tab: "" no badge, "dot" a red dot, anything else a number or text.
   */
  badgeValues?: ReadonlyArray<string>;
  /**
   * The plus button's badge: "" none, "dot" a red dot, anything else a number or text.
   */
  plusButtonBadgeValue?: string;
  /**
   * The animation of text badges: a CYLBadgeAnimationType (0 none, 1 scale, 2 shake, 3 bounce, 4 breathe...).
   */
  badgeAnimation?: CodegenTypes.WithDefault<CodegenTypes.Int32, 0>;
  /**
   * Badges with a style, as JSON: a list of `{value, color, animation, radius, centerOffset}` or null, one per tab.
   */
  badgeStyles?: string;
  /**
   * The plus button's badge with a style, as JSON `{value, color, animation, radius, centerOffset}`.
   */
  plusButtonBadgeStyle?: string;
  /**
   * An image covering each tab's icon (a URL or an image name), "" for none.
   */
  tabCoverImages?: ReadonlyArray<string>;
  /**
   * Whether the user is logged in (`cyl_loggedIn`, issue #19): 1 yes, 0 no, -1 not set (the state the library cached).
   */
  loginState?: CodegenTypes.WithDefault<CodegenTypes.Int32, -1>;
  /**
   * The language of the library's texts and layout direction ("ar", "zh-Hans"); "" for the device language.
   */
  language?: string;
  /**
   * Hides the tab bar, animated (`setTabBarHidden:animated:`); a hidden tab bar takes no touches.
   */
  tabBarHidden?: boolean;
  /**
   * Each increase simulates a memory warning once; the report comes with onMemoryWarning.
   */
  memoryWarningRequest?: CodegenTypes.WithDefault<CodegenTypes.Int32, 0>;
  /**
   * The playback speed of every tab icon animation; 0 (or less): the library's default.
   */
  playbackSpeed?: CodegenTypes.WithDefault<CodegenTypes.Float, 0>;
  /**
   * Whether the tab icon animations repeat until this is false.
   */
  playbackLoops?: boolean;
  /**
   * Each increase plays every tab icon animation again from progress 0 ("Play all").
   */
  playAllRequest?: CodegenTypes.WithDefault<CodegenTypes.Int32, 0>;
  /**
   * True pauses every playing tab icon animation, false resumes them. Set it from the `onScrollBeginDrag` and
   * `onMomentumScrollEnd` of your list (`useLifecycle` gives `scrollHandlers`).
   */
  animationsPaused?: CodegenTypes.WithDefault<boolean, false>;
  /**
   * The title offset of every tab, [horizontal, vertical], set at runtime; empty keeps the configuration's.
   */
  titlePositionAdjustment?: ReadonlyArray<CodegenTypes.Double>;
  /**
   * The URL of a tab bar manifest to download (docs/Configuration-Manifest.md); its configuration is applied under the
   * configuration above, and the other props and `configuration` win over it.
   */
  manifestURL?: string;
  /**
   * The manifest was applied; the source is "remote", "cache" or "embedded".
   */
  onManifestApply?: CodegenTypes.DirectEventHandler<ManifestApplyEvent>;
  /**
   * The manifest could not be downloaded; the message says why, and another source was used if there was one.
   */
  onManifestFail?: CodegenTypes.DirectEventHandler<ManifestFailEvent>;
  /**
   * An animation (`cyl.animation.*`) or badge (`cyl.badge.*`) moment of any view; `userInfo` is a JSON object string.
   */
  onLifecycleEvent?: CodegenTypes.DirectEventHandler<LifecycleMomentEvent>;
  onTabLongPress?: CodegenTypes.DirectEventHandler<TabLongPressEvent>;
  /**
   * A tab that needs login was tapped while logged out; it is not selected.
   */
  onLoginRequest?: CodegenTypes.DirectEventHandler<TabLongPressEvent>;
  /**
   * The login state the tab bar uses, sent once it is built.
   */
  onLoginStateChange?: CodegenTypes.DirectEventHandler<LoginStateEvent>;
  /**
   * What a simulated memory warning did to each tab, one line per tab.
   */
  onMemoryWarning?: CodegenTypes.DirectEventHandler<MemoryWarningEvent>;
  onTabSelect?: CodegenTypes.DirectEventHandler<TabSelectEvent>;
  onPlusButtonPress?: CodegenTypes.DirectEventHandler<PlusButtonPressEvent>;
  onTabBarLayout?: CodegenTypes.DirectEventHandler<TabBarLayoutEvent>;
}

export default codegenNativeComponent<NativeProps>(
  'CyltabbarView'
) as HostComponent<NativeProps>;
