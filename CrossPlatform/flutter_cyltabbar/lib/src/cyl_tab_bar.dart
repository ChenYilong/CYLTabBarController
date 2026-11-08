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
    this.attributes = const {},
  });

  final String? title;
  final CYLTabBarImage? image;
  final CYLTabBarImage? selectedImage;

  /// `CYLTabBarItemIdentifier`, reported by [CYLTabBar.onTabSelect].
  final String? identifier;

  /// Any other key of a tab in the configuration file, e.g. `CYLTabBarItemTitlePositionAdjustment`.
  final Map<String, Object?> attributes;

  Map<String, Object?> toConfiguration() => {
        ...attributes,
        if (title != null) 'CYLTabBarItemTitle': title,
        if (identifier != null) 'CYLTabBarItemIdentifier': identifier,
        if (image != null) 'CYLTabBarItemImage': image!.value,
        if (selectedImage != null) 'CYLTabBarItemSelectedImage': selectedImage!.value,
      };
}

/// The raised plus button: `CYLTabBarControllerPlusButton`.
@immutable
class CYLTabBarPlusButton {
  const CYLTabBarPlusButton({
    this.image,
    this.backgroundImage,
    this.title,
    this.titleColor,
    this.selectedTitleColor,
    this.titleFont,
    this.index,
    this.centerYMultiplier,
    this.centerYOffset,
    this.alignsTitle,
    this.keepsTitleVisible,
    this.identifier,
    this.pageIdentifier,
  }) : assert(image != null || backgroundImage != null, 'a plus button needs an image or a background image');

  /// The button's image; or [backgroundImage], a picture with the title drawn on it.
  final CYLTabBarImage? image;
  final CYLTabBarImage? backgroundImage;

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

  final String? identifier;

  /// The plus button selects a page of its own: [CYLTabBar.onTabSelect] gets index -1 and [identifier].
  final String? pageIdentifier;

  Map<String, Object?> toConfiguration() => {
        if (image != null) 'CYLTabBarItemImage': image!.value,
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
        if (identifier != null) 'CYLTabBarItemIdentifier': identifier,
        if (pageIdentifier != null) 'CYLTabBarItemPageIdentifier': pageIdentifier,
      };
}

/// The animation of text badges (`CYLBadgeAnimationType`).
enum CYLTabBarBadgeAnimation { none, scale, shake, bounce, breathe, leftRightOnce, rightLeftOnce, fadeInOnce, rollingOnce, scaleOnce }

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
    this.plusButton,
    this.configuration = const {},
    this.selectedIndex,
    this.badgeValues = const [],
    this.plusButtonBadgeValue = '',
    this.badgeAnimation = CYLTabBarBadgeAnimation.none,
    this.onTabSelect,
    this.onPlusButtonPress,
    this.onTabLongPress,
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

  /// A tab was selected by a tap: its index in [items] and its identifier; the plus button's own page gives index -1.
  final void Function(int index, String identifier)? onTabSelect;

  final VoidCallback? onPlusButtonPress;

  /// A long press on a tab (its index) or the plus button (-1), with the title it shows.
  final void Function(int index, String identifier, String title)? onTabLongPress;

  /// The configuration sent to the native library.
  Map<String, Object?> buildConfiguration() => {
        if (styleType != null) 'CYLTabBarControllerStyleType': styleType,
        if (userInterfaceStyle != null) 'CYLTabBarControllerUserInterfaceStyle': userInterfaceStyle,
        if (tapAnimation != null) 'CYLTabBarControllerTabButtonTapAnimation': tapAnimation,
        if (swipeToSwitchTab != null) 'CYLTabBarControllerSwipeToSwitchTab': swipeToSwitchTab,
        if (animationSpeed != null) 'CYLTabBarControllerTabBarItemAnimationSpeed': animationSpeed,
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
      };

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
