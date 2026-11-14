import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'cyl_touch_regions.dart';

/// The platform view type registered by the iOS and Android plugins.
const String _viewType = 'flutter_cyltabbar/CYLTabBar';

/// A tab image.
///
/// [CYLTabBarImage.asset] is an image of the app's Flutter assets (resolution variants such as `2.0x/` are used);
/// [CYLTabBarImage.name] is a name the native library resolves: an asset catalog image or `system:house.fill` on
/// iOS, a drawable resource on Android, or a file path.
@immutable
class CYLTabBarImage {
  const CYLTabBarImage.asset(String path) : value = 'flutter-asset:$path';
  const CYLTabBarImage.name(String name) : value = name;

  /// The value sent to the native library.
  final String value;
}

/// A tab: the keys of `CYLTabBarControllerTabBarItemsAttributes`.
@immutable
class CYLTabBarItem {
  const CYLTabBarItem({
    this.title,
    this.image,
    this.selectedImage,
    this.identifier,
    this.iconRenderingMode,
    this.iconColor,
    this.selectedIconColor,
    this.attributes = const {},
  });

  final String? title;
  final CYLTabBarImage? image;
  final CYLTabBarImage? selectedImage;

  /// `CYLTabBarItemIdentifier`, reported by [CYLTabBar.onTabSelect].
  final String? identifier;

  /// Issue #787: `'template'` (one image, tinted with [iconColor] / [selectedIconColor], else the bar's tint),
  /// `'original'` (keeps its colors) or `'automatic'`. Wins over [CYLTabBar.iconRenderingMode].
  final String? iconRenderingMode;

  /// Icon colors such as `#8E8E93`, unselected and selected.
  final String? iconColor;
  final String? selectedIconColor;

  /// Any other key of a tab in the configuration file, e.g. `CYLTabBarItemTitlePositionAdjustment`.
  final Map<String, Object?> attributes;

  Map<String, Object?> toConfiguration() => {
        ...attributes,
        if (title != null) 'CYLTabBarItemTitle': title,
        if (identifier != null) 'CYLTabBarItemIdentifier': identifier,
        if (image != null) 'CYLTabBarItemImage': image!.value,
        if (selectedImage != null) 'CYLTabBarItemSelectedImage': selectedImage!.value,
        if (iconRenderingMode != null) 'CYLTabBarItemIconRenderingMode': iconRenderingMode,
        if (iconColor != null) 'CYLTabBarItemIconColor': iconColor,
        if (selectedIconColor != null) 'CYLTabBarItemSelectedIconColor': selectedIconColor,
      };
}

/// The raised plus button: `CYLTabBarControllerPlusButton`.
@immutable
class CYLTabBarPlusButton {
  const CYLTabBarPlusButton({
    this.image,
    this.selectedImage,
    this.backgroundImage,
    this.size,
    this.imageSize,
    this.title,
    this.titleColor,
    this.selectedTitleColor,
    this.titleFont,
    this.index,
    this.centerYMultiplier,
    this.centerYOffset,
    this.alignsTitle,
    this.keepsTitleVisible,
    this.showsSelection,
    this.identifier,
    this.pageIdentifier,
  }) : assert(image != null || backgroundImage != null, 'a plus button needs an image or a background image');

  /// The button's image; or [backgroundImage], a picture with the title drawn on it.
  final CYLTabBarImage? image;

  /// The image while it is selected or touched.
  final CYLTabBarImage? selectedImage;
  final CYLTabBarImage? backgroundImage;

  /// Its size in logical pixels (default: its image and title), as a subclass sets its bounds.
  final Size? size;

  /// The size its images are drawn at, aspect fit (e.g. a 512 px network image).
  final Size? imageSize;

  /// Give it a title when the tab titles are aligned (the plus button's title then lines up with them).
  final String? title;

  /// Colors such as `#FF5500`.
  final String? titleColor;
  final String? selectedTitleColor;

  /// A font as in a configuration file: a size (`15`), `'bold:15'`, `'Menlo-Regular:12'`.
  final Object? titleFont;

  /// Its place among the tabs (default: the middle).
  final int? index;

  /// Its vertical center: `centerYMultiplier * tabBarHeight + centerYOffset`.
  final double? centerYMultiplier;
  final double? centerYOffset;

  /// Whether the title lines up with the tab titles (default: with a title and no background image).
  final bool? alignsTitle;

  /// Keeps the title visible on Liquid Glass.
  final bool? keepsTitleVisible;

  /// Liquid Glass: the selection stays under the button while its own page is selected (Android always shows it).
  final bool? showsSelection;

  final String? identifier;

  /// The plus button selects a page of its own: [CYLTabBar.onTabSelect] gets index -1 and [identifier].
  final String? pageIdentifier;

  Map<String, Object?> toConfiguration() => {
        if (image != null) 'CYLTabBarItemImage': image!.value,
        if (selectedImage != null) 'CYLTabBarItemSelectedImage': selectedImage!.value,
        if (size != null) 'CYLPlusButtonSize': [size!.width, size!.height],
        if (imageSize != null) 'CYLPlusButtonImageSize': [imageSize!.width, imageSize!.height],
        if (backgroundImage != null) 'CYLPlusButtonBackgroundImage': backgroundImage!.value,
        if (title != null) 'CYLTabBarItemTitle': title,
        if (titleColor != null) 'CYLTabBarItemTitleColor': titleColor,
        if (selectedTitleColor != null) 'CYLTabBarItemSelectedTitleColor': selectedTitleColor,
        if (titleFont != null) 'CYLTabBarItemTitleFont': titleFont,
        if (index != null) 'CYLPlusButtonIndexInTabBar': index,
        if (centerYMultiplier != null) 'CYLPlusButtonCenterYMultiplier': centerYMultiplier,
        if (centerYOffset != null) 'CYLPlusButtonCenterYOffset': centerYOffset,
        if (alignsTitle != null) 'CYLPlusButtonAlignsTitle': alignsTitle,
        if (keepsTitleVisible != null) 'CYLPlusButtonKeepsTitleVisible': keepsTitleVisible,
        if (showsSelection != null) 'CYLPlusButtonShowsSelection': showsSelection,
        if (identifier != null) 'CYLTabBarItemIdentifier': identifier,
        if (pageIdentifier != null) 'CYLTabBarItemPageIdentifier': pageIdentifier,
      };
}

/// The animation of text badges (`CYLBadgeAnimationType`).
enum CYLTabBarBadgeAnimation { none, scale, shake, bounce, breathe, leftRightOnce, rightLeftOnce, fadeInOnce, rollingOnce, scaleOnce }

/// A badge with a style (`CYLTabBarHostView.badgeAttributes`).
@immutable
class CYLTabBarBadge {
  const CYLTabBarBadge(this.value, {this.color, this.animation, this.radius, this.centerOffset});

  /// `''` none, `'dot'` a red dot, anything else a number or text.
  final String value;

  /// A color such as `'#AF52DE'`.
  final String? color;
  final CYLTabBarBadgeAnimation? animation;

  /// The dot's radius.
  final double? radius;

  /// Moves the badge from the icon's top-right corner.
  final Offset? centerOffset;

  Map<String, Object?> toMap() => {
        'value': value,
        if (color != null) 'color': color,
        if (animation != null) 'animation': animation!.name,
        if (radius != null) 'radius': radius,
        if (centerOffset != null) 'centerOffset': [centerOffset!.dx, centerOffset!.dy],
      };
}

/// The native tab bar of CYLTabBarController (iOS) and its Android port.
///
/// It draws only the bar: build the pages yourself and switch them in [onTabSelect], for example with an
/// `IndexedStack` above it. Put it at the bottom of the screen (e.g. as `Scaffold.bottomNavigationBar`): it takes
/// the bar's height, bottom safe area included, plus the height the plus button rises above the bar.
///
/// On Android the activity must be a `FlutterFragmentActivity`.
class CYLTabBar extends StatefulWidget {
  const CYLTabBar({
    super.key,
    this.items = const [],
    this.styleType,
    this.userInterfaceStyle,
    this.tapAnimation,
    this.swipeToSwitchTab,
    this.animationSpeed,
    this.iconRenderingMode,
    this.iconColor,
    this.selectedIconColor,
    this.plusButton,
    this.configurationRoute,
    this.manifestRoute,
    this.configuration = const {},
    this.selectedIndex,
    this.badgeValues = const [],
    this.plusButtonBadgeValue = '',
    this.badgeAnimation = CYLTabBarBadgeAnimation.none,
    this.badgeStyles = const [],
    this.plusButtonBadge,
    this.tabCoverImages = const [],
    this.onTabSelect,
    this.onPlusButtonPress,
    this.onTabLongPress,
    this.loggedIn,
    this.onLoginRequest,
    this.onLoginStateChange,
    this.language,
    this.tabBarHidden = false,
    this.memoryWarningRequest = 0,
    this.animationSpeed,
    this.animationLoops = false,
    this.playAllRequest = 0,
    this.onMemoryWarning,
    this.titlePositionAdjustment,
  });

  /// The tabs: `CYLTabBarControllerTabBarItemsAttributes`.
  final List<CYLTabBarItem> items;

  /// `CYLTabBarControllerStyleType`: `default`, `system`, `flatDesign` or `liquidGlass`.
  final String? styleType;

  /// `'light'`, `'dark'` or `'system'`: the tab bar's appearance (iOS).
  final String? userInterfaceStyle;

  /// The tap animation of the tab buttons: `'bounce'`, `'scale'`, `'zoomIn'`, `'rotation'`, `'flip'`, `'fume'`...
  final String? tapAnimation;

  /// Swiping on the tab bar switches tabs.
  final bool? swipeToSwitchTab;

  /// The playback speed of the animated tab icons (1: the file's own).
  final double? animationSpeed;

  /// Issue #787: the icon rendering mode of every tab without its own: `'template'`, `'original'` or `'automatic'`.
  final String? iconRenderingMode;

  /// The icon colors of every tab without its own, such as `#8E8E93`, unselected and selected.
  final String? iconColor;
  final String? selectedIconColor;

  final CYLTabBarPlusButton? plusButton;

  /// Any other key of the configuration file (docs/Configuration-File.md); it wins over the fields above.
  final Map<String, Object?> configuration;

  /// The selected tab, among [items]. Null leaves the selection to the user's taps.
  final int? selectedIndex;

  /// A badge per tab: `''` none, `'dot'` a red dot, anything else a text.
  final List<String> badgeValues;

  /// The plus button's badge: `''` none, `'dot'` a red dot, anything else a text.
  final String plusButtonBadgeValue;

  final CYLTabBarBadgeAnimation badgeAnimation;

  /// Badges with a style, one per tab; null leaves the tab to [badgeValues].
  final List<CYLTabBarBadge?> badgeStyles;

  /// The plus button's badge with a style; wins over [plusButtonBadgeValue].
  final CYLTabBarBadge? plusButtonBadge;

  /// An image covering each tab's icon in both states, null for none.
  final List<CYLTabBarImage?> tabCoverImages;

  /// A tab was selected by a tap: its index in [items] and its identifier; the plus button's own page gives index -1.
  final void Function(int index, String identifier)? onTabSelect;

  final VoidCallback? onPlusButtonPress;

  /// A long press on a tab (its index) or the plus button (-1), with the title it shows.
  final void Function(int index, String identifier, String title)? onTabLongPress;

  /// Login (issue #19): whether the user is logged in. While logged out, tapping a tab listed in the configuration's
  /// `CYLTabBarControllerLoginRequiredTabBarItemIdentifiers` calls [onLoginRequest] instead of selecting it; show your
  /// login screen, then set [loggedIn] and [selectedIndex]. Left null, the tab bar uses the state the library cached (kept
  /// across launches) and reports it with [onLoginStateChange].
  final bool? loggedIn;
  final void Function(int index, String identifier, String title)? onLoginRequest;

  /// The login state the tab bar uses, sent once it is built: start from it to keep the login across launches.
  final ValueChanged<bool>? onLoginStateChange;

  /// The language of the library's own texts (badge and plus button accessibility texts) and of the layout direction: a
  /// language code such as 'ar' or 'zh-Hans'; null for the device language. A right-to-left language lays the tab bar out
  /// right to left. The tab titles come from [items]: translate them there.
  final String? language;

  /// Hides or shows the tab bar, animated, in every style (`-[CYLTabBarController setTabBarHidden:animated:]`). A hidden
  /// tab bar takes no touches: the page under it gets them.
  final bool tabBarHidden;

  /// Issue #426: each increase simulates a memory warning once (`+[CYLTabBarController cyl_simulateMemoryWarningForTabBarController:]`);
  /// [onMemoryWarning] then reports what happened to each tab, one line per tab, in the library's language. The
  /// configuration decides what is unloaded (`CYLTabBarControllerUnloadsUnselectedViewsOnMemoryWarning`,
  /// `CYLTabBarControllerKeepsLoadedTabBarItemIdentifiers`).
  final int memoryWarningRequest;

  /// The playback speed of every tab icon animation (`tabBarItemAnimationSpeed`), e.g. 0.25 to 3; null or 0 or less: the
  /// library's default. Applies to the animations already playing.
  final double? animationSpeed;

  /// Whether the tab icon animations repeat until this is false (`tabBarItemAnimationLoops`); applies to the animations
  /// already playing.
  final bool animationLoops;

  /// Each increase plays every tab icon animation again from progress 0, with [animationSpeed] and [animationLoops]
  /// ("Play all", `-[CYLTabBarController cyl_playAllTabBarItemAnimations]`).
  final int playAllRequest;
  final ValueChanged<String>? onMemoryWarning;

  /// The title offset of every tab (dx horizontal, dy vertical), set at runtime
  /// (`-[CYLTabBarController setTitlePositionAdjustment:]`) without building the tab bar again; it wins over
  /// `CYLTabBarControllerTitlePositionAdjustment` of the configuration. A plus button that aligns its title follows. Null
  /// keeps the configuration's.
  final Offset? titlePositionAdjustment;

  /// A resource route to a configuration file built into the app or in its sandbox (docs/Resource-Routes.md), e.g.
  /// `bundle:Configurations?name=tabbar` or `sandbox:Caches/tabbar?name=tabbar&theme=dark`. The file is read first; the
  /// other parameters and [configuration] win over its keys.
  final String? configurationRoute;

  /// A resource route to a tab bar manifest (docs/Configuration-Manifest.md): tabs, plus button, themes and their images,
  /// version, platforms. The manifest is read first; the other parameters and [configuration] win over it.
  final String? manifestRoute;

  /// The configuration sent to the native library.
  Map<String, Object?> buildConfiguration() => {
        if (configurationRoute != null) 'CYLTabBarControllerConfigurationRoute': configurationRoute,
        if (manifestRoute != null) 'CYLTabBarControllerManifestRoute': manifestRoute,
        if (styleType != null) 'CYLTabBarControllerStyleType': styleType,
        if (userInterfaceStyle != null) 'CYLTabBarControllerUserInterfaceStyle': userInterfaceStyle,
        if (tapAnimation != null) 'CYLTabBarControllerTabButtonTapAnimation': tapAnimation,
        if (swipeToSwitchTab != null) 'CYLTabBarControllerSwipeToSwitchTab': swipeToSwitchTab,
        if (animationSpeed != null) 'CYLTabBarControllerTabBarItemAnimationSpeed': animationSpeed,
        if (iconRenderingMode != null) 'CYLTabBarControllerIconRenderingMode': iconRenderingMode,
        if (iconColor != null) 'CYLTabBarControllerIconColor': iconColor,
        if (selectedIconColor != null) 'CYLTabBarControllerSelectedIconColor': selectedIconColor,
        if (items.isNotEmpty)
          'CYLTabBarControllerTabBarItemsAttributes': [for (final item in items) item.toConfiguration()],
        if (plusButton != null) 'CYLTabBarControllerPlusButton': plusButton!.toConfiguration(),
        ...configuration,
      };

  @override
  State<CYLTabBar> createState() => _CYLTabBarState();
}

class _CYLTabBarState extends State<CYLTabBar> {
  MethodChannel? _channel;
  double _height = 83;
  List<Rect>? _touchableRects;
  late String _configurationJSON = jsonEncode(widget.buildConfiguration());

  Map<String, Object?> get _creationParams => {
        'configuration': _configurationJSON,
        'selectedIndex': widget.selectedIndex ?? -1,
        'badgeValues': widget.badgeValues,
        'plusButtonBadgeValue': widget.plusButtonBadgeValue,
        'badgeAnimation': widget.badgeAnimation.index,
        'badgeStyles': _badgeStyles(widget),
        'plusButtonBadge': widget.plusButtonBadge?.toMap(),
        'tabCoverImages': _coverImages(widget),
        'loggedIn': widget.loggedIn,
        'language': widget.language,
        'tabBarHidden': widget.tabBarHidden,
        'animationSpeed': widget.animationSpeed,
        'animationLoops': widget.animationLoops,
        'titlePositionAdjustment': _titleOffset(widget),
      };

  static List<double>? _titleOffset(CYLTabBar bar) {
    final offset = bar.titlePositionAdjustment;
    return offset == null ? null : [offset.dx, offset.dy];
  }

  static List<Map<String, Object?>?> _badgeStyles(CYLTabBar bar) => [for (final badge in bar.badgeStyles) badge?.toMap()];

  static List<String?> _coverImages(CYLTabBar bar) => [for (final image in bar.tabCoverImages) image?.value];

  @override
  void didUpdateWidget(CYLTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final channel = _channel;
    final json = jsonEncode(widget.buildConfiguration());
    if (json != _configurationJSON) {
      _configurationJSON = json;
      channel?.invokeMethod<void>('setConfiguration', json);
    }
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      channel?.invokeMethod<void>('setSelectedIndex', widget.selectedIndex ?? -1);
    }
    if (!listEquals(widget.badgeValues, oldWidget.badgeValues)) {
      channel?.invokeMethod<void>('setBadgeValues', widget.badgeValues);
    }
    if (widget.plusButtonBadgeValue != oldWidget.plusButtonBadgeValue) {
      channel?.invokeMethod<void>('setPlusButtonBadgeValue', widget.plusButtonBadgeValue);
    }
    if (widget.badgeAnimation != oldWidget.badgeAnimation) {
      channel?.invokeMethod<void>('setBadgeAnimation', widget.badgeAnimation.index);
    }
    final badgeStyles = _badgeStyles(widget);
    if (jsonEncode(badgeStyles) != jsonEncode(_badgeStyles(oldWidget))) {
      channel?.invokeMethod<void>('setBadgeStyles', badgeStyles);
    }
    final plusButtonBadge = widget.plusButtonBadge?.toMap();
    if (jsonEncode(plusButtonBadge) != jsonEncode(oldWidget.plusButtonBadge?.toMap())) {
      channel?.invokeMethod<void>('setPlusButtonBadge', plusButtonBadge);
    }
    final coverImages = _coverImages(widget);
    if (!listEquals(coverImages, _coverImages(oldWidget))) {
      channel?.invokeMethod<void>('setTabCoverImages', coverImages);
    }
    if (widget.memoryWarningRequest > oldWidget.memoryWarningRequest) {
      channel?.invokeMethod<String>('simulateMemoryWarning').then((report) {
        if (report != null) widget.onMemoryWarning?.call(report);
      });
    }
    if (widget.animationSpeed != oldWidget.animationSpeed) {
      channel?.invokeMethod<void>('setAnimationSpeed', widget.animationSpeed);
    }
    if (widget.animationLoops != oldWidget.animationLoops) {
      channel?.invokeMethod<void>('setAnimationLoops', widget.animationLoops);
    }
    if (widget.playAllRequest > oldWidget.playAllRequest) {
      channel?.invokeMethod<void>('playAllAnimations');
    }
    if (widget.titlePositionAdjustment != oldWidget.titlePositionAdjustment) {
      channel?.invokeMethod<void>('setTitlePositionAdjustment', _titleOffset(widget));
    }
    if (widget.tabBarHidden != oldWidget.tabBarHidden) {
      channel?.invokeMethod<void>('setTabBarHidden', widget.tabBarHidden);
    }
    if (widget.language != oldWidget.language) {
      channel?.invokeMethod<void>('setLanguage', widget.language);
    }
    if (widget.loggedIn != oldWidget.loggedIn) {
      channel?.invokeMethod<void>('setLoggedIn', widget.loggedIn);
    }
  }

  void _onPlatformViewCreated(int id) {
    final channel = MethodChannel('$_viewType/$id');
    channel.setMethodCallHandler((call) async {
      final arguments = call.arguments;
      switch (call.method) {
        case 'onTabSelect':
          if (arguments is Map) {
            widget.onTabSelect?.call(arguments['index'] as int, (arguments['identifier'] as String?) ?? '');
          }
        case 'onPlusButtonPress':
          widget.onPlusButtonPress?.call();
        case 'onTabLongPress':
          if (arguments is Map) {
            widget.onTabLongPress?.call(
                arguments['index'] as int, (arguments['identifier'] as String?) ?? '', (arguments['title'] as String?) ?? '');
          }
        case 'onLoginRequest':
          if (arguments is Map) {
            widget.onLoginRequest?.call(
                arguments['index'] as int, (arguments['identifier'] as String?) ?? '', (arguments['title'] as String?) ?? '');
          }
        case 'onLoginStateChange':
          widget.onLoginStateChange?.call(arguments == true);
        case 'onTouchableRects':
          if (mounted) setState(() => _touchableRects = CYLTouchRegions.parse(arguments));
        case 'onTabBarLayout':
          final height = (arguments as num).toDouble();
          if (mounted && height > 0 && (height - _height).abs() >= 0.5) {
            setState(() => _height = height);
          }
      }
    });
    _channel = channel;
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: _height, child: CYLTouchRegions(rects: _touchableRects, child: _buildPlatformView()));
  }

  Widget _buildPlatformView() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: _viewType,
          creationParams: _creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
        );
      case TargetPlatform.android:
        // Hybrid composition: the native tab bar controller hosts fragments, which need a view in the activity.
        return PlatformViewLink(
          viewType: _viewType,
          surfaceFactory: (context, controller) => AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          ),
          onCreatePlatformView: (params) {
            final controller = PlatformViewsService.initExpensiveAndroidView(
              id: params.id,
              viewType: _viewType,
              layoutDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
              creationParams: _creationParams,
              creationParamsCodec: const StandardMessageCodec(),
              onFocus: () => params.onFocusChanged(true),
            );
            controller
              ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
              ..addOnPlatformViewCreatedListener(_onPlatformViewCreated)
              ..create();
            return controller;
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
