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

type TabBarLayoutEvent = Readonly<{
  height: CodegenTypes.Double;
}>;

export interface NativeProps extends ViewProps {
  /** The configuration of CYLTabBarController, as JSON (docs/Configuration-File.md). */
  configuration?: string;
  /** The selected tab; -1 leaves the selection to the tab bar. */
  selectedIndex?: CodegenTypes.WithDefault<CodegenTypes.Int32, -1>;
  /** One value per tab: "" no badge, "dot" a red dot, anything else a number or text. */
  badgeValues?: ReadonlyArray<string>;
  /** The plus button's badge: "" none, "dot" a red dot, anything else a number or text. */
  plusButtonBadgeValue?: string;
  /** The animation of text badges: a CYLBadgeAnimationType (0 none, 1 scale, 2 shake, 3 bounce, 4 breathe...). */
  badgeAnimation?: CodegenTypes.WithDefault<CodegenTypes.Int32, 0>;
  onTabLongPress?: CodegenTypes.DirectEventHandler<TabLongPressEvent>;
  onTabSelect?: CodegenTypes.DirectEventHandler<TabSelectEvent>;
  onPlusButtonPress?: CodegenTypes.DirectEventHandler<PlusButtonPressEvent>;
  onTabBarLayout?: CodegenTypes.DirectEventHandler<TabBarLayoutEvent>;
}

export default codegenNativeComponent<NativeProps>(
  'CyltabbarView'
) as HostComponent<NativeProps>;
