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
  backgroundImage?: CYLTabBarImage;
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
  /** Any other key of the configuration file (docs/Configuration-File.md); it wins over the props above. */
  configuration?: Record<string, unknown>;
  selectedIndex?: number;
  badgeValues?: string[];
  /** The plus button's badge: "" none, "dot" a red dot, anything else a text. */
  plusButtonBadgeValue?: string;
  badgeAnimation?: CYLTabBarBadgeAnimation;
  /** A tab was tapped; the plus button's own page (`plusButton.pageIdentifier`) gives index -1. */
  onTabSelect?: (index: number, identifier: string) => void;
  onPlusButtonPress?: () => void;
  /** A long press on a tab (its index) or the plus button (-1), with the title it shows. */
  onTabLongPress?: (index: number, identifier: string, title: string) => void;
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

export function buildConfiguration(props: CYLTabBarProps): Record<string, unknown> {
  const configuration: Record<string, unknown> = {};
  if (props.styleType) {
    configuration.CYLTabBarControllerStyleType = props.styleType;
  }
  if (props.userInterfaceStyle) configuration.CYLTabBarControllerUserInterfaceStyle = props.userInterfaceStyle;
  if (props.tapAnimation) configuration.CYLTabBarControllerTabButtonTapAnimation = props.tapAnimation;
  if (props.swipeToSwitchTab != null) configuration.CYLTabBarControllerSwipeToSwitchTab = props.swipeToSwitchTab;
  if (props.animationSpeed != null) configuration.CYLTabBarControllerTabBarItemAnimationSpeed = props.animationSpeed;
  if (props.items) {
    configuration.CYLTabBarControllerTabBarItemsAttributes = props.items.map(
      ({ title, image, selectedImage, identifier, ...rest }) => {
        const item: Record<string, unknown> = { ...rest };
        if (title != null) item.CYLTabBarItemTitle = title;
        if (identifier != null) item.CYLTabBarItemIdentifier = identifier;
        addImage(item, 'CYLTabBarItemImage', image);
        addImage(item, 'CYLTabBarItemSelectedImage', selectedImage);
        return item;
      }
    );
  }
  if (props.plusButton) {
    const p = props.plusButton;
    const plus: Record<string, unknown> = {};
    if (p.title != null) plus.CYLTabBarItemTitle = p.title;
    if (p.titleColor) plus.CYLTabBarItemTitleColor = p.titleColor;
    if (p.selectedTitleColor) plus.CYLTabBarItemSelectedTitleColor = p.selectedTitleColor;
    if (p.titleFont != null) plus.CYLTabBarItemTitleFont = p.titleFont;
    if (p.index != null) plus.CYLPlusButtonIndexInTabBar = p.index;
    if (p.centerYMultiplier != null) plus.CYLPlusButtonCenterYMultiplier = p.centerYMultiplier;
    if (p.centerYOffset != null) plus.CYLPlusButtonCenterYOffset = p.centerYOffset;
    if (p.alignsTitle != null) plus.CYLPlusButtonAlignsTitle = p.alignsTitle;
    if (p.keepsTitleVisible != null) plus.CYLPlusButtonKeepsTitleVisible = p.keepsTitleVisible;
    if (p.identifier) plus.CYLTabBarItemIdentifier = p.identifier;
    if (p.pageIdentifier) plus.CYLTabBarItemPageIdentifier = p.pageIdentifier;
    addImage(plus, 'CYLTabBarItemImage', p.image);
    addImage(plus, 'CYLPlusButtonBackgroundImage', p.backgroundImage);
    configuration.CYLTabBarControllerPlusButton = plus;
  }
  return { ...configuration, ...props.configuration };
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
    selectedIndex,
    badgeValues,
    plusButtonBadgeValue,
    badgeAnimation,
    ...rest
  } = props;
  const [height, setHeight] = useState<number | undefined>(undefined);
  const configuration = useMemo(
    () => JSON.stringify(buildConfiguration(props)),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [props.items, props.styleType, props.plusButton, props.configuration, props.userInterfaceStyle, props.tapAnimation,
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
