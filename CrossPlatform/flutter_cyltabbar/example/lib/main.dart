// The Flutter twin of the Objective-C example (Example/, MainTabBarController.m), tracked item by item in
// docs/ObjC-Example-Parity/README.md. The same tab bar, built from a configuration: four Lottie tabs, the "Post" plus
// button with its own page, the badges and the cover of the first tab 1.5 s after launch; the home page's navigation bar
// ("Flat Design", "Skin", "Liquid Glass"); the pages follow the system's dark / light mode.
// Objective-C 示例（Example/，MainTabBarController.m）的 Flutter 版本，逐项复刻进度见 docs/ObjC-Example-Parity/README.md。
// 同样的 TabBar（由配置创建）：四个 Lottie Tab、带自己页面的「发布」PlusButton、启动 1.5 秒后的角标与第一个 Tab 的封面；首页导航栏
// （「Flat Design」「Skin」「Liquid Glass」）；页面跟随系统深色 / 浅色模式。
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_cyltabbar/flutter_cyltabbar.dart';

import 'demo/cyl_badge_view.dart';
import 'demo/cyl_demo_list.dart';
import 'cyl_skins.dart';

void main() => runApp(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.light),
    darkTheme: ThemeData(brightness: Brightness.dark),
    themeMode: ThemeMode.system,
    home: const CYLExampleApp(),
  ),
);

/// The Lottie files of MainTabBarController.m, light and dark. MainTabBarController.m 的 Lottie 文件（浅色与深色）。
Map<String, Object?> _lottie(String name) => {
  'CYLTabBarLottieFilePath': 'green_lottie_tab_$name.json',
  'CYLTabBarLottieDarkFilePath': 'green_lottie_tab_${name}_dark.json',
};

// +[MainTabBarController tabBarItemsAttributesForTabBar]
final _items = [
  CYLTabBarItem(
    title: 'Home',
    identifier: 'home',
    image: const CYLTabBarImage.asset('assets/home_normal.png'),
    selectedImage: const CYLTabBarImage.asset('assets/home_highlight.png'),
    attributes: {'CYLTabBarItemSelectedTitle': 'Refresh', ..._lottie('home')},
  ),
  CYLTabBarItem(
    title: 'Nearby',
    identifier: 'city',
    image: const CYLTabBarImage.asset('assets/fishpond_normal.png'),
    selectedImage: const CYLTabBarImage.asset('assets/fishpond_highlight.png'),
    attributes: {
      ..._lottie('discover'),
      'CYLTabBarAnimationColors': {'Icon_Discovery_Normal.**.Color': '#7F7F7F'},
    },
  ),
  CYLTabBarItem(
    title: 'Messages',
    identifier: 'message',
    image: const CYLTabBarImage.asset('assets/message_normal.png'),
    selectedImage: const CYLTabBarImage.asset('assets/message_highlight.png'),
    attributes: {
      'CYLTabBarItemDarkImage': const CYLTabBarImage.asset(
        'assets/message_normal_night.png',
      ).value,
      ..._lottie('news'),
    },
  ),
  CYLTabBarItem(
    title: 'Me',
    // No identifier in Objective-C: the class name is the default (#408). Objective-C 未设置：默认为类名（#408）。
    identifier: 'CYLMineViewController',
    image: const CYLTabBarImage.asset('assets/account_normal.png'),
    selectedImage: const CYLTabBarImage.asset('assets/account_highlight.png'),
    attributes: _lottie('mine'),
  ),
];

// CYLPlusButtonSubclass.m
CYLTabBarPlusButton _plusButton({
  CYLTabBarImage? image,
  CYLTabBarImage? selectedImage,
}) => CYLTabBarPlusButton(
  title: 'Post',
  image: image ?? const CYLTabBarImage.asset('assets/post_normal.png'),
  selectedImage:
      selectedImage ?? const CYLTabBarImage.asset('assets/post_highlight.png'),
  selectedTitleColor: '#34C759',
  titleFont: 9.5,
  index: 2,
  size: const Size(55, 80),
  // A skin's image is drawn in the plus image's frame, aspect fit (`-updatePlusButtonWithAttributes:`).
  // 皮肤图片在 PlusButton 原图片区域内等比绘制。
  imageSize: const Size(55, 55),
  centerYOffset: -14,
  alignsTitle: true,
  // -tabBarController:shouldShowPlatterLiquidLensViewForControl: returns YES. 该代理方法返回 YES。
  showsSelection: true,
  identifier: 'plus',
  pageIdentifier: 'plus',
);

/// The Objective-C example's title offset (0, -3.5), which the aligned plus button follows, and its tab bar appearance
/// (+demoStandardAppearanceWithTitlePositionAdjustment:): titles 10 pt, red unselected, green selected. The bar-wide
/// values are a skin's named values, which build the same `UITabBarAppearance` on iOS.
/// ObjC 示例的标题偏移（标题对齐的 PlusButton 随之移动）与 TabBar 外观：标题 10pt，未选中红色、选中绿色。整个 TabBar 的值写在皮肤的命名值中，
/// iOS 上生成同样的 `UITabBarAppearance`。
const _configuration = {
  'CYLTabBarControllerTitlePositionAdjustment': [0, -3.5],
  // -[MainTabBarController setUpLoginRequiredTabs] (issue #19). 需要登录的 Tab。
  'CYLTabBarControllerLoginRequiredTabBarItemIdentifiers': [
    'message',
    'CYLMineViewController',
  ],
  'CYLTabBarControllerThemes': {
    'Default': {
      'CYLTabBarItemTitleColor': '#FF0000',
      'CYLTabBarItemIconColor': '#FF0000',
      'CYLTabBarItemSelectedTitleColor': '#34C759',
      'CYLTabBarItemSelectedIconColor': '#34C759',
      'CYLTabBarItemTitleFont': 10,
    },
  },
};

/// The tabs in a skin: holiday or network icons instead of the Lottie ones. 皮肤中的 Tab：用节日或网络图标替换 Lottie 图标。
List<CYLTabBarItem> _skinnedItems(CYLSkin skin) => [
  for (final (index, item) in _items.indexed)
    if (skin.icons != null)
      CYLTabBarItem(
        title: item.title,
        identifier: item.identifier,
        image: CYLTabBarImage.asset(
          themeIcon(skin.icons![index % skin.icons!.length], faded: true),
        ),
        selectedImage: CYLTabBarImage.asset(
          themeIcon(skin.icons![index % skin.icons!.length]),
        ),
        attributes: {
          'CYLTabBarItemSelectedTitle':
              item.attributes['CYLTabBarItemSelectedTitle'],
        },
      )
    else if (skin.network != null)
      CYLTabBarItem(
        title: '${skin.network!.titlePrefix} ${item.title}',
        identifier: item.identifier,
        image: item.image,
        attributes: {
          'CYLTabBarItemSelectedTitle':
              item.attributes['CYLTabBarItemSelectedTitle'],
          'CYLTabBarItemImageURL':
              skin.network!.tabs[index % skin.network!.tabs.length][0],
          'CYLTabBarItemSelectedImageURL':
              skin.network!.tabs[index % skin.network!.tabs.length][1],
          'CYLTabBarItemImageURLSize': [24, 24],
        },
      )
    else
      item,
];

/// The plus button in a skin (`cyl_plusButtonAttributesForTabBarController:`). 皮肤中的 PlusButton。
CYLTabBarPlusButton _skinnedPlusButton(CYLSkin skin) {
  if (skin.icons != null) {
    final icon = CYLTabBarImage.asset(themeIcon(skin.icons!.last));
    return _plusButton(image: icon, selectedImage: icon);
  }
  if (skin.network != null) {
    return _plusButton(
      image: CYLTabBarImage.name(skin.network!.plusButton[0]),
      selectedImage: CYLTabBarImage.name(skin.network!.plusButton[1]),
    );
  }
  return _plusButton();
}

/// The bar's colors in a skin (`cyl_tabBarAppearanceForTabBarController:`). 皮肤中 TabBar 的颜色。
Map<String, Object?> _skinnedConfiguration(CYLSkin skin) {
  if (skin.tint == null) return _configuration;
  final normal = skin.normal ?? '#8E8E93';
  return {
    ..._configuration,
    'CYLTabBarControllerThemes': {
      skin.name: {
        if (skin.bar != null) 'CYLTabBarBackgroundColor': skin.bar,
        'CYLTabBarItemTitleColor': normal,
        'CYLTabBarItemSelectedTitleColor': skin.tint,
        // Full color icons are drawn as they are (`UIImageRenderingModeAlwaysOriginal`). 全彩图标按原图绘制。
        if (skin.icons == null && skin.network == null) ...{
          'CYLTabBarItemIconColor': normal,
          'CYLTabBarItemSelectedIconColor': skin.tint,
        },
        'CYLTabBarItemTitleFont': 10,
      },
    },
  };
}

/// A random color, as `UIColor.cyl_randomColor`. 随机颜色，与 `UIColor.cyl_randomColor` 相同。
String _randomColor() =>
    '#${Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

Color _color(String hex) =>
    Color(int.parse('FF${hex.substring(1)}', radix: 16));

// -[MainTabBarController cyl_demo_decorateTabBarController:], 1.5 s after launch: the first tab's dot is cleared at once
// by its cover (`-setSelectedCoverShow:`). 启动 1.5 秒后；第一个 Tab 的红点随即被其封面清除。
List<CYLTabBarBadge?> _launchBadges() => [
  CYLTabBarBadge(
    '',
    color: _randomColor(),
    radius: 5.5,
    animation: CYLTabBarBadgeAnimation.breathe,
  ),
  const CYLTabBarBadge(
    '8',
    color: '#AF52DE',
    animation: CYLTabBarBadgeAnimation.scale,
  ),
  const CYLTabBarBadge('100', animation: CYLTabBarBadgeAnimation.bounce),
  const CYLTabBarBadge(
    'NEW',
    animation: CYLTabBarBadgeAnimation.breathe,
    centerOffset: Offset(-1, 3),
  ),
];

/// -[CYLMainRootViewController createFlatDesignTabBar] / -createNewTabBarWithContext: the navigation bar buttons replace
/// the tab bar controller with a new one, in FlatDesign or Liquid Glass: a new key builds a new tab bar, with its launch
/// badges. The skin belongs to the app (CYLThemeManagerCenter.defaultThemeManager): it stays when the tab bar is replaced.
/// 导航栏按钮用新的 TabBarController（扁平样式或液态玻璃）替换旧的：新的 key 创建新的 TabBar 及其启动角标。皮肤属于整个 App（默认主题管理器）：
/// 替换 TabBar 时保持不变。
class CYLExampleApp extends StatefulWidget {
  const CYLExampleApp({super.key});

  @override
  State<CYLExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<CYLExampleApp> {
  String _styleType = 'liquidGlass';
  int _generation = 0;
  String _skinName = 'Default';
  bool _followsSystem = false;
  // Login (issue #19) belongs to the app, as `cyl_loggedIn`: it stays when the tab bar is replaced. Null until the tab bar
  // reports the state the library cached, so the login is kept across launches, as the Objective-C example.
  // 登录状态（issue #19）属于整个 App，与 `cyl_loggedIn` 相同：替换 TabBar 时保持不变。TabBar 报告库缓存的状态之前为 null，
  // 因此与 Objective-C 示例相同，重启 App 后登录状态保留。
  bool? _loggedIn;

  @override
  Widget build(BuildContext context) {
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    // CYLDemoSetFollowsSystem: Dark in dark mode; in light mode back to Default from Dark, otherwise the skin chosen.
    // 跟随系统：深色时为 Dark；浅色时从 Dark 回到 Default，否则为所选皮肤。
    final name = _followsSystem
        ? (dark ? 'Dark' : (_skinName == 'Dark' ? 'Default' : _skinName))
        : _skinName;
    final skin = skins.firstWhere(
      (candidate) => candidate.name == name,
      orElse: () => skins.first,
    );
    return CYLExamplePage(
      key: ValueKey(_generation),
      styleType: _styleType,
      skin: skin,
      followsSystem: _followsSystem,
      onRebuild: (styleType) => setState(() {
        _styleType = styleType;
        _generation++;
      }),
      // CYLDemoApplyTheme: choosing a skin stops following the system. 选择皮肤时停止跟随系统。
      onChooseSkin: (name) => setState(() {
        _followsSystem = false;
        _skinName = name;
      }),
      onToggleFollowsSystem: () =>
          setState(() => _followsSystem = !_followsSystem),
      loggedIn: _loggedIn,
      onLoggedInChange: (loggedIn) => setState(() => _loggedIn = loggedIn),
    );
  }
}

/// A dot badge on a navigation bar button (`-cyl_showBadgeValue:animationType:backgroundColor:`). 导航栏按钮上的红点角标。
class _CYLNavigationBadge extends StatefulWidget {
  const _CYLNavigationBadge({required this.color, required this.breathe});
  final Color color;
  final bool breathe;

  @override
  State<_CYLNavigationBadge> createState() => _CYLNavigationBadgeState();
}

class _CYLNavigationBadgeState extends State<_CYLNavigationBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.breathe ? 1800 : 1560),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A decoration of the button: hidden from accessibility. 按钮的装饰：对无障碍隐藏。
    final dot = ExcludeSemantics(
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        if (widget.breathe) {
          return Opacity(opacity: 1 - 0.7 * sin(pi * t), child: child);
        }
        // A short shake, then a pause. 短暂抖动后停顿。
        final shake = t < 0.23 ? sin(t / 0.23 * 2 * pi) * 3 : 0.0;
        return Transform.translate(offset: Offset(shake, 0), child: child);
      },
      child: dot,
    );
  }
}

/// A Liquid Glass bar button. 液态玻璃导航栏按钮。
class _CYLNavigationButton extends StatelessWidget {
  const _CYLNavigationButton({
    required this.title,
    required this.onPressed,
    required this.dark,
    this.badge,
  });
  final String title;
  final VoidCallback onPressed;
  final bool dark;
  final Widget? badge;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: title,
    excludeSemantics: true,
    onTap: onPressed,
    child: GestureDetector(
      onTap: onPressed,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                color: dark ? Colors.white : Colors.black,
              ),
            ),
          ),
          if (badge != null) Positioned(top: -3, right: -3, child: badge!),
        ],
      ),
    ),
  );
}

class CYLExamplePage extends StatefulWidget {
  const CYLExamplePage({
    super.key,
    required this.styleType,
    required this.skin,
    required this.followsSystem,
    required this.onRebuild,
    required this.onChooseSkin,
    required this.onToggleFollowsSystem,
    required this.loggedIn,
    required this.onLoggedInChange,
  });

  final String styleType;
  final CYLSkin skin;
  final bool followsSystem;
  final ValueChanged<String> onRebuild;
  final ValueChanged<String> onChooseSkin;
  final VoidCallback onToggleFollowsSystem;
  final bool? loggedIn;
  final ValueChanged<bool> onLoggedInChange;

  @override
  State<CYLExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<CYLExamplePage> {
  int _selectedIndex = 0;
  bool _plusPageSelected = false;
  List<CYLTabBarBadge?> _badges = const [];
  bool _decorated = false;
  bool _coverShown = true;
  Timer? _coverTimer;
  Timer? _timer;
  // -[CYLHomeViewController viewDidLoad]: dots in random colors on the "Flat Design" and "Liquid Glass" buttons.
  // 「Flat Design」与「Liquid Glass」按钮上的随机颜色红点。
  final _navigationBadgeColors = [_randomColor(), _randomColor()];

  /// MainTabBarController: the first page's title gets " (Liquid)" on Liquid Glass. The badge samples' subtitle uses it; a
  /// badge row changes only the navigation title ("Home (n)").
  /// 液态玻璃下第一个页面的标题加上「 (Liquid)」。角标样例副标题使用它；点击角标行只修改导航标题（「Home (n)」）。
  String get _pageTitle => _selectedIndex == 0
      ? 'Home${widget.styleType == 'liquidGlass' ? ' (Liquid)' : ''}'
      : _items[_selectedIndex].title!;

  /// The system version shown in the badge samples' subtitle. 角标样例副标题中的系统版本。
  String get _systemVersion {
    final version = Platform.operatingSystemVersion;
    // Android reports the kernel ("... android15 ..."); iOS reports "Version 26.5 (Build ...)". Android 报告内核版本；iOS 报告「Version 26.5」。
    final match =
        RegExp(r'android(\d+)').firstMatch(version) ??
        RegExp(r'(\d+(\.\d+)?)').firstMatch(version);
    return match?.group(1) ?? version;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer(
      const Duration(milliseconds: 1500),
      () => setState(() {
        _decorated = true;
        _badges = _launchBadges();
      }),
    );
  }

  // As the Objective-C example, the cover goes on after the tab icons: a skin's icons replace the tab's icon views, so the
  // cover is put back once they are in (network icons are downloaded first). 与 Objective-C 示例相同，封面在 Tab 图标之后添加：
  // 皮肤的图标会替换 Tab 的图标视图，因此在其就绪后重新添加封面（网络图标需要先下载）。
  @override
  void didUpdateWidget(CYLExamplePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.skin.name == widget.skin.name) return;
    _coverTimer?.cancel();
    _coverShown = false;
    _coverTimer = Timer(
      Duration(milliseconds: widget.skin.network != null ? 4000 : 1500),
      () => setState(() => _coverShown = true),
    );
  }

  @override
  void dispose() {
    _coverTimer?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  /// The skin picker (`-cyl_themeMenuWithCompletion:`): a swatch or the first icon, a check on the current one. 换肤菜单。
  void _showSkinMenu(bool dark) {
    final label = dark ? Colors.white : Colors.black;
    Widget row(Widget icon, String title, bool checked, VoidCallback onTap) =>
        Semantics(
          button: true,
          selected: checked,
          label: title,
          excludeSemantics: true,
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop();
              onTap();
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    child: Text(
                      checked ? '✓' : '',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, color: label),
                    ),
                  ),
                  SizedBox(width: 26, height: 26, child: icon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 17, color: label),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Align(
        alignment: Alignment.topRight,
        child: Padding(
          // Below the navigation bar; the dialog already stays inside the safe area. 位于导航栏下方；对话框已在安全区内。
          padding: const EdgeInsets.only(top: 40, right: 16),
          child: Material(
            color: dark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 260,
                maxHeight: MediaQuery.sizeOf(context).height * 0.75,
              ),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(
                      'Choose a theme',
                      style: TextStyle(fontSize: 15, color: Color(0xFF8E8E93)),
                    ),
                  ),
                  for (final skin in skins)
                    row(
                      skin.icons != null
                          ? Image.asset(themeIcon(skin.icons!.first))
                          : Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _color(skin.tint ?? '#C7C7CC'),
                                shape: BoxShape.circle,
                              ),
                              child: skin.network != null
                                  ? const Text(
                                      '↓',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  : null,
                            ),
                      skin.name,
                      !widget.followsSystem && skin.name == widget.skin.name,
                      () => widget.onChooseSkin(skin.name),
                    ),
                  row(
                    Center(
                      child: Text(
                        '◐',
                        style: TextStyle(fontSize: 20, color: label),
                      ),
                    ),
                    'Follow the system Dark Mode',
                    widget.followsSystem,
                    widget.onToggleFollowsSystem,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final skin = widget.skin;
    final title = _plusPageSelected
        ? 'PlusChildViewController'
        : _items[_selectedIndex].title!;
    // FlatDesign: a skin's tint colors the badges without a color of their own (`badgeBackgroundColor` of the appearance);
    // Liquid Glass keeps them red. 扁平样式：皮肤的 tint 为没有自定颜色的角标着色（appearance 的 `badgeBackgroundColor`）；液态玻璃下仍为红色。
    final tintsBadges = widget.styleType == 'flatDesign' && skin.tint != null;
    final badges = [
      for (final badge in _badges)
        badge != null && badge.color == null && tintsBadges
            ? CYLTabBarBadge(
                badge.value,
                color: skin.tint,
                animation: badge.animation,
                radius: badge.radius,
                centerOffset: badge.centerOffset,
              )
            : badge,
    ];
    return Scaffold(
      // The page scrolls under the floating bar, as in the Objective-C example. 页面在悬浮的 TabBar 下方滚动，与 Objective-C 示例相同。
      extendBody: true,
      // UIColor.systemBackgroundColor / labelColor.
      backgroundColor: CYLDemoColors(dark).background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // CYLHomeViewController's navigation bar: "Flat Design" on the left, "Skin" and "Liquid Glass" on the right.
            // 首页导航栏：左侧「Flat Design」，右侧「Skin」与「Liquid Glass」。
            if (!_plusPageSelected && _selectedIndex == 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    _CYLNavigationButton(
                      title: 'Flat Design',
                      dark: dark,
                      onPressed: () => widget.onRebuild('flatDesign'),
                      badge: _CYLNavigationBadge(
                        color: _color(_navigationBadgeColors[0]),
                        breathe: true,
                      ),
                    ),
                    const Spacer(),
                    _CYLNavigationButton(
                      title: 'Skin',
                      dark: dark,
                      onPressed: () => _showSkinMenu(dark),
                    ),
                    const SizedBox(width: 12),
                    _CYLNavigationButton(
                      title: 'Liquid Glass',
                      dark: dark,
                      onPressed: () => widget.onRebuild('liquidGlass'),
                      badge: _CYLNavigationBadge(
                        color: _color(_navigationBadgeColors[1]),
                        breathe: false,
                      ),
                    ),
                  ],
                ),
              ),
            // Every tab shows the demo list (item 51); the plus button's page shows its title.
            // 每个 Tab 都显示演示列表（第 51 项）；PlusButton 的页面显示其标题。
            Expanded(
              child: _plusPageSelected
                  ? Center(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: dark ? Colors.white : Colors.black,
                        ),
                      ),
                    )
                  : CYLDemoList(
                      colors: CYLDemoColors(dark),
                      tint: skin.tint != null
                          ? hexColor(skin.tint!)
                          : (dark
                                ? const Color(0xFF0A84FF)
                                : const Color(0xFF007AFF)),
                      values: {
                        'titleOffset': '(0, -3.5)',
                        'appearance': 'Original',
                        'skin': skin.name,
                        'scrollBehavior': 'Automatic',
                        'indexWithoutPlus': '$_selectedIndex',
                        'selectedIndex':
                            '${_selectedIndex < 2 ? _selectedIndex : _selectedIndex + 1}',
                        'selectedTitle': _selectedIndex == 0
                            ? 'Refresh'
                            : _items[_selectedIndex].title!,
                        'login': widget.loggedIn == true ? 'logged in' : 'logged out',
                        'touchScale': '1.0x',
                        'tapAnimation': 'None',
                        'tapSound': 'None',
                        'longPress': '0.5',
                        'doubleTap': '0.35',
                        'adjacent': '-',
                        'outsideTaps': '0',
                      },
                      switches: {'login': widget.loggedIn == true},
                      currentSkin: widget.followsSystem ? '' : skin.name,
                      badgeSubtitle:
                          '$_pageTitle CYLTabBarController on ${Theme.of(context).platform == TargetPlatform.iOS ? 'iOS' : 'Android'} $_systemVersion',
                      onRow: (row, index) {
                        if (row.skin != null) {
                          return widget.onChooseSkin(row.skin!.name);
                        }
                        if (row.id == 'skin') return _showSkinMenu(dark);
                        if (row.badge != null) {
                          // -[CYLHomeViewController tableView:didSelectRowAtIndexPath:]: a full screen orange page without a
                          // navigation bar, tap to go back (the "Home (n)" navigation title is not shown: the home page's
                          // navigation bar shows only its buttons). 全屏橙色页面，无导航栏，点击返回（导航标题「Home (n)」不显示：首页导航栏只显示按钮）。
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => Semantics(
                                button: true,
                                label: 'Back',
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: const ColoredBox(
                                    color: Color(0xFFFF8000),
                                    child: SizedBox.expand(),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                      },
                      // The login state row (CYLLoginStateSwitch): on means logged in. 登录状态行：打开表示已登录。
                      onSwitch: (row, on) {
                        if (row.id == 'login') widget.onLoggedInChange(on);
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CYLTabBar(
        items: _skinnedItems(skin),
        styleType: widget.styleType,
        // -addScaleAnimationOnView:repeatCount: on every tap. 每次点击播放一次缩放动画。
        tapAnimation: 'scale',
        plusButton: _skinnedPlusButton(skin),
        configuration: _skinnedConfiguration(skin),
        selectedIndex: _plusPageSelected ? null : _selectedIndex,
        badgeStyles: badges,
        plusButtonBadge: _decorated
            ? const CYLTabBarBadge(
                '1',
                animation: CYLTabBarBadgeAnimation.bounce,
              )
            : null,
        tabCoverImages: _decorated && _coverShown
            ? const [CYLTabBarImage.asset('assets/home_select_cover.png')]
            : const [],
        loggedIn: widget.loggedIn,
        onLoginStateChange: widget.onLoggedInChange,
        // -[MainTabBarController cyl_demo_presentLoginForViewController:completion:]: "Messages" and "Me" need login; the
        // alert logs in, then selects the tapped tab. 「Messages」「Me」需要登录；弹窗登录后选中所点击的 Tab。
        onLoginRequest: (index, identifier, title) => showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog.adaptive(
            title: const Text('Login required'),
            content: Text('Log in to view “$title”'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  widget.onLoggedInChange(true);
                  setState(() => _select(index));
                },
                child: const Text('Log in'),
              ),
            ],
          ),
        ),
        onTabSelect: (index, identifier) => setState(() {
          final reselected = index == _selectedIndex && !_plusPageSelected;
          _plusPageSelected = index < 0;
          if (index < 0) return;
          if (reselected) {
            return;
          }
          _select(index);
        }),
      ),
    );
  }

  /// Selects a tab and marks its badge. 选中 Tab 并标记其角标。
  void _select(int index) {
    _plusPageSelected = false;
    _selectedIndex = index;
    {
      // -[MainTabBarController tabBarController:didSelectControl:]: the tab button itself shows no badge on Liquid
      // Glass (the badge is on its image view), so a tap that selects a tab turns its badge into a dot, in the
      // badge's color. 液态玻璃下 Tab 按钮本身没有角标（角标在其图片视图上），因此选中 Tab 的点击会把其角标变为红点，保留角标颜色。
      final next = [..._badges];
      while (next.length <= index) {
        next.add(null);
      }
      next[index] = CYLTabBarBadge('dot', color: next[index]?.color);
      _badges = next;
    }
  }
}
