import { useMemo, useState } from 'react';
import { Image, type ImageSourcePropType, type ViewProps } from 'react-native';
import NativeCyltabbarView from './CyltabbarViewNativeComponent';

/** A tab image: a name ("home", "system:house.fill"), or an image required from JS (`require('./home.png')`). */
export type CYLTabBarImage = string | ImageSourcePropType;

export type CYLTabBarItem = {
  title?: string;
  image?: CYLTabBarImage;
  selectedImage?: CYLTabBarImage;
  identifier?: string;
  /** Any other key of the configuration file, e.g. CYLTabBarItemTitlePositionAdjustment. */
  [key: string]: unknown;
};

export type CYLTabBarPlusButton = {
  title?: string;
  /** The button's image; or `backgroundImage`, a picture with the title drawn on it. */
  image?: CYLTabBarImage;
  /** The image while it is selected or touched. */
  selectedImage?: CYLTabBarImage;
  backgroundImage?: CYLTabBarImage;
  /** Its size in points / dp, `[width, height]` (default: its image and title). */
  size?: [number, number];
  /** The size its images are drawn at, aspect fit, `[width, height]` (e.g. a 512 px network image). */
  imageSize?: [number, number];
  titleColor?: string;
  selectedTitleColor?: string;
  /** A font as in a configuration file: a size (15), "bold:15", "Menlo-Regular:12". */
  titleFont?: string | number;
  /** Its place among the tabs (default: the middle). */
  index?: number;
  /** Its vertical center: `multiplier * tabBarHeight + offset`. */
  centerYMultiplier?: number;
  centerYOffset?: number;
  /** Whether the title lines up with the tab titles (default: with a title and no background image). */
  alignsTitle?: boolean;
  /** Keeps the title visible on Liquid Glass. */
  keepsTitleVisible?: boolean;
  /** Liquid Glass: the selection stays under the button while its own page is selected (Android always shows it). */
  showsSelection?: boolean;
  identifier?: string;
  /** The plus button selects a page of its own: `onTabSelect(-1, identifier)`. */
  pageIdentifier?: string;
};

/** Names of `CYLBadgeAnimationType`. */
export type CYLTabBarBadgeAnimation =
  | 'none' | 'scale' | 'shake' | 'bounce' | 'breathe' | 'leftRightOnce' | 'rightLeftOnce' | 'fadeInOnce' | 'rollingOnce' | 'scaleOnce';

const BADGE_ANIMATIONS: CYLTabBarBadgeAnimation[] = [
  'none', 'scale', 'shake', 'bounce', 'breathe', 'leftRightOnce', 'rightLeftOnce', 'fadeInOnce', 'rollingOnce', 'scaleOnce',
];

/** A badge with a style (`CYLTabBarHostView.badgeAttributes`). */
export type CYLTabBarBadge = {
  /** "" none, "dot" a red dot, anything else a number or text. */
  value: string;
  /** A color such as "#AF52DE". */
  color?: string;
  animation?: CYLTabBarBadgeAnimation;
  /** The dot's radius. */
  radius?: number;
  /** Moves the badge from the icon's top-right corner, `[x, y]`. */
  centerOffset?: [number, number];
};

export type CYLTabBarProps = ViewProps & {
  /** The tabs. They become CYLTabBarControllerTabBarItemsAttributes. */
  items?: CYLTabBarItem[];
  /** "default" | "system" | "flatDesign" | "liquidGlass". */
  styleType?: string;
  /** "light" | "dark" | "system": the tab bar's appearance (iOS). */
  userInterfaceStyle?: 'light' | 'dark' | 'system';
  /** The tap animation of the tab buttons: "bounce", "scale", "zoomIn", "rotation", "flip", "fume"... */
  tapAnimation?: string;
  /** Swiping on the tab bar switches tabs. */
  swipeToSwitchTab?: boolean;
  /** The playback speed of the animated tab icons (1: the file's own). */
  animationSpeed?: number;
  plusButton?: CYLTabBarPlusButton;
  /**
   * A resource route to a configuration file built into the app or in its sandbox (docs/Resource-Routes.md), e.g.
   * "bundle:Configurations?name=tabbar" or "sandbox:Caches/tabbar?name=tabbar&theme=dark". The file is read first;
   * the other props and `configuration` win over its keys.
   */
  configurationRoute?: string;
  /** Any other key of the configuration file (docs/Configuration-File.md); it wins over the props above. */
  configuration?: Record<string, unknown>;
  selectedIndex?: number;
  badgeValues?: string[];
  /** The plus button's badge: "" none, "dot" a red dot, anything else a text. */
  plusButtonBadgeValue?: string;
  badgeAnimation?: CYLTabBarBadgeAnimation;
  /** Badges with a style, one per tab (null leaves the tab to `badgeValues`). */
  badgeStyles?: (CYLTabBarBadge | null)[];
  /** The plus button's badge with a style; wins over `plusButtonBadgeValue`. */
  plusButtonBadge?: CYLTabBarBadge;
  /** An image covering each tab's icon in both states, null for none. */
  tabCoverImages?: (CYLTabBarImage | null)[];
  /** A tab was tapped; the plus button's own page (`plusButton.pageIdentifier`) gives index -1. */
  onTabSelect?: (index: number, identifier: string) => void;
  onPlusButtonPress?: () => void;
  /** A long press on a tab (its index) or the plus button (-1), with the title it shows. */
  onTabLongPress?: (index: number, identifier: string, title: string) => void;
  /**
   * Login (issue #19): whether the user is logged in. While logged out, tapping a tab listed in the configuration's
   * `CYLTabBarControllerLoginRequiredTabBarItemIdentifiers` calls `onLoginRequest` instead of selecting it; show your
   * login screen, then set `loggedIn` and `selectedIndex`. Left undefined, the tab bar uses the state the library cached
   * (kept across launches) and reports it with `onLoginStateChange`.
   */
  loggedIn?: boolean;
  onLoginRequest?: (index: number, identifier: string, title: string) => void;
  /** The login state the tab bar uses, sent once it is built: start from it to keep the login across launches. */
  onLoginStateChange?: (loggedIn: boolean) => void;
  /**
   * The language of the library's own texts (badge and plus button accessibility texts) and of the layout direction: a
   * language code such as 'ar' or 'zh-Hans'; undefined for the device language. A right-to-left language lays the tab bar
   * out right to left. The tab titles come from `items`: translate them there.
   */
  language?: string;
  /**
   * Hides or shows the tab bar, animated, in every style (`-[CYLTabBarController setTabBarHidden:animated:]`). A hidden
   * tab bar takes no touches: the page under it gets them.
   */
  tabBarHidden?: boolean;
  /**
   * Issue #426: each increase simulates a memory warning once (`+[CYLTabBarController cyl_simulateMemoryWarningForTabBarController:]`);
   * `onMemoryWarning` then reports what happened to each tab, one line per tab, in the library's language. The
   * configuration decides what is unloaded (`CYLTabBarControllerUnloadsUnselectedViewsOnMemoryWarning`,
   * `CYLTabBarControllerKeepsLoadedTabBarItemIdentifiers`).
   */
  memoryWarningRequest?: number;
  onMemoryWarning?: (report: string) => void;
  /**
   * The title offset of every tab, [horizontal, vertical], set at runtime (`-[CYLTabBarController setTitlePositionAdjustment:]`)
   * without building the tab bar again; it wins over `CYLTabBarControllerTitlePositionAdjustment` of the configuration. A
   * plus button that aligns its title follows. Undefined keeps the configuration's.
   */
  titlePositionAdjustment?: [number, number];
};

/**
 * A required image becomes its URL (Metro serves it over http in debug, a file in release); the native view loads it into
 * an image before it builds the tab bar.
 */
function addImage(target: Record<string, unknown>, key: string, image?: CYLTabBarImage) {
  if (image == null) {
    return;
  }
  if (typeof image === 'string') {
    target[key] = image;
    return;
  }
  const source = Image.resolveAssetSource(image);
  if (source?.uri) {
    target[key] = source.uri;
  }
}

/** A required image's URL, or a name / URL string as it is; "" for none. */
function imageValue(image?: CYLTabBarImage | null): string {
  if (image == null) return '';
  if (typeof image === 'string') return image;
  return Image.resolveAssetSource(image)?.uri ?? '';
}

/** [EN] How a prop is copied: when truthy, or when not null. [CN] 属性的复制条件：为真值时，或不为 null 时。 */
type CYLKeyRule = 'truthy' | 'defined';
type CYLKeyMap = ReadonlyArray<readonly [prop: string, key: string, rule: CYLKeyRule]>;

const CONTROLLER_KEYS: CYLKeyMap = [
  ['styleType', 'CYLTabBarControllerStyleType', 'truthy'],
  ['userInterfaceStyle', 'CYLTabBarControllerUserInterfaceStyle', 'truthy'],
  ['tapAnimation', 'CYLTabBarControllerTabButtonTapAnimation', 'truthy'],
  ['swipeToSwitchTab', 'CYLTabBarControllerSwipeToSwitchTab', 'defined'],
  ['animationSpeed', 'CYLTabBarControllerTabBarItemAnimationSpeed', 'defined'],
];

const ITEM_KEYS: CYLKeyMap = [
  ['title', 'CYLTabBarItemTitle', 'defined'],
  ['identifier', 'CYLTabBarItemIdentifier', 'defined'],
];

const PLUS_BUTTON_KEYS: CYLKeyMap = [
  ['title', 'CYLTabBarItemTitle', 'defined'],
  ['titleColor', 'CYLTabBarItemTitleColor', 'truthy'],
  ['selectedTitleColor', 'CYLTabBarItemSelectedTitleColor', 'truthy'],
  ['titleFont', 'CYLTabBarItemTitleFont', 'defined'],
  ['index', 'CYLPlusButtonIndexInTabBar', 'defined'],
  ['centerYMultiplier', 'CYLPlusButtonCenterYMultiplier', 'defined'],
  ['centerYOffset', 'CYLPlusButtonCenterYOffset', 'defined'],
  ['alignsTitle', 'CYLPlusButtonAlignsTitle', 'defined'],
  ['keepsTitleVisible', 'CYLPlusButtonKeepsTitleVisible', 'defined'],
  ['showsSelection', 'CYLPlusButtonShowsSelection', 'defined'],
  ['identifier', 'CYLTabBarItemIdentifier', 'truthy'],
  ['pageIdentifier', 'CYLTabBarItemPageIdentifier', 'truthy'],
  ['size', 'CYLPlusButtonSize', 'truthy'],
  ['imageSize', 'CYLPlusButtonImageSize', 'truthy'],
];

/** [EN] Copies the props of `source` that pass their rule into `target`, under their keys. [CN] 把 `source` 中满足条件的属性按 key 复制到 `target`。 */
function copyKeys(target: Record<string, unknown>, source: object, keys: CYLKeyMap): void {
  const values = source as Record<string, unknown>;
  for (const [prop, key, rule] of keys) {
    const value = values[prop];
    if (rule === 'truthy' ? Boolean(value) : value != null) {
      target[key] = value;
    }
  }
}

function itemAttributes({ title, image, selectedImage, identifier, ...rest }: CYLTabBarItem): Record<string, unknown> {
  const item: Record<string, unknown> = { ...rest };
  copyKeys(item, { title, identifier }, ITEM_KEYS);
  addImage(item, 'CYLTabBarItemImage', image);
  addImage(item, 'CYLTabBarItemSelectedImage', selectedImage);
  return item;
}

function plusButtonAttributes(plusButton: CYLTabBarPlusButton): Record<string, unknown> {
  const plus: Record<string, unknown> = {};
  copyKeys(plus, plusButton, PLUS_BUTTON_KEYS);
  addImage(plus, 'CYLTabBarItemImage', plusButton.image);
  addImage(plus, 'CYLTabBarItemSelectedImage', plusButton.selectedImage);
  addImage(plus, 'CYLPlusButtonBackgroundImage', plusButton.backgroundImage);
  return plus;
}

export function buildConfiguration(props: CYLTabBarProps): Record<string, unknown> {
  const configuration: Record<string, unknown> = {};
  if (props.configurationRoute) {
    configuration.CYLTabBarControllerConfigurationRoute = props.configurationRoute;
  }
  copyKeys(configuration, props, CONTROLLER_KEYS);
  if (props.items) {
    configuration.CYLTabBarControllerTabBarItemsAttributes = props.items.map(itemAttributes);
  }
  if (props.plusButton) {
    configuration.CYLTabBarControllerPlusButton = plusButtonAttributes(props.plusButton);
  }
  return { ...configuration, ...props.configuration };
}

/** [EN] The native login state: -1 unknown (the library's cached state is used), 1 logged in, 0 logged out. [CN] 原生登录状态：-1 未知（使用库缓存的状态），1 已登录，0 未登录。 */
function loginStateValue(loggedIn: boolean | undefined): number {
  if (loggedIn === undefined) {
    return -1;
  }
  return loggedIn ? 1 : 0;
}

/**
 * The native tab bar of CYLTabBarController (iOS) and its Android port. It draws only the bar: render the pages yourself
 * and switch them in `onTabSelect`. Put it at the bottom of the screen; it takes the bar's height, safe area included.
 */
export function CYLTabBar(props: CYLTabBarProps) {
  const {
    style,
    items: _items,
    styleType: _styleType,
    plusButton: _plusButton,
    configuration: _configuration,
    userInterfaceStyle: _userInterfaceStyle,
    tapAnimation: _tapAnimation,
    swipeToSwitchTab: _swipeToSwitchTab,
    animationSpeed: _animationSpeed,
    onTabSelect,
    onPlusButtonPress,
    onTabLongPress,
    onLoginRequest,
    onLoginStateChange,
    loggedIn,
    language,
    tabBarHidden,
    memoryWarningRequest,
    onMemoryWarning,
    titlePositionAdjustment,
    selectedIndex,
    badgeValues,
    plusButtonBadgeValue,
    badgeAnimation,
    badgeStyles,
    plusButtonBadge,
    tabCoverImages,
    ...rest
  } = props;
  const [height, setHeight] = useState<number | undefined>(undefined);
  const configuration = useMemo(
    () => JSON.stringify(buildConfiguration(props)),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [props.items, props.styleType, props.plusButton, props.configuration, props.configurationRoute, props.userInterfaceStyle, props.tapAnimation,
      props.swipeToSwitchTab, props.animationSpeed]
  );
  return (
    <NativeCyltabbarView
      {...rest}
      style={[{ height: height ?? 83 }, style]}
      configuration={configuration}
      selectedIndex={selectedIndex ?? -1}
      badgeValues={badgeValues ?? []}
      plusButtonBadgeValue={plusButtonBadgeValue ?? ''}
      badgeAnimation={Math.max(0, BADGE_ANIMATIONS.indexOf(badgeAnimation ?? 'none'))}
      badgeStyles={badgeStyles ? JSON.stringify(badgeStyles) : ''}
      plusButtonBadgeStyle={plusButtonBadge ? JSON.stringify(plusButtonBadge) : ''}
      tabCoverImages={(tabCoverImages ?? []).map(imageValue)}
      loginState={loginStateValue(loggedIn)}
      language={language ?? ''}
      tabBarHidden={tabBarHidden ?? false}
      memoryWarningRequest={memoryWarningRequest ?? 0}
      titlePositionAdjustment={titlePositionAdjustment ?? []}
      onMemoryWarning={(event) => onMemoryWarning?.(event.nativeEvent.report)}
      onLoginStateChange={(event) => onLoginStateChange?.(event.nativeEvent.loggedIn)}
      onLoginRequest={(event) =>
        onLoginRequest?.(event.nativeEvent.index, event.nativeEvent.identifier, event.nativeEvent.title)
      }
      onTabLongPress={(event) =>
        onTabLongPress?.(event.nativeEvent.index, event.nativeEvent.identifier, event.nativeEvent.title)
      }
      onTabSelect={(event) => onTabSelect?.(event.nativeEvent.index, event.nativeEvent.identifier)}
      onPlusButtonPress={() => onPlusButtonPress?.()}
      onTabBarLayout={(event) => {
        const next = event.nativeEvent.height;
        if (next > 0 && next !== height) setHeight(next);
      }}
    />
  );
}
