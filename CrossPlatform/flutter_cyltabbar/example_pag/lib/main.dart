// The Flutter twin of Example-PAG (HealthyHome): the same tab bar, built from a configuration through CYLTabBar, and
// the same pages drawn by Flutter. Example-PAG（HealthyHome）的 Flutter 版本：同样的 TabBar（通过 CYLTabBar 由配置创建），
// 以及由 Flutter 绘制的同样页面。
//
// - Tabs: the images of Example-PAG's asset catalog and the PAG files of Example-Shared/PAGResources/tab-icons, added to
//   the iOS app (ios/) and to the Android assets (android/app/build.gradle.kts), named as in TabBarCommon.swift.
// - Plus button: "Menu" drawn on tabbar_database, its own page (CYLPlusButtonSubclass.swift), a badge that shows 1 after
//   launch and grows with each tap (Example-Shared/CYLPlusButtonBadgeDemo.swift).
// - Interactions: bounce on tap, swipe to switch, a long press alert (demoSetUpInteractions()).
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_cyltabbar/flutter_cyltabbar.dart';

// MARK: - Texts (CYLTabBarController.bundle's translations of the native demo) 文本

final bool _chinese = PlatformDispatcher.instance.locale.languageCode == 'zh';
String get _home => _chinese ? '首页' : 'Home';
String get _health => _chinese ? '健康' : 'Health';
String get _moments => _chinese ? '朋友圈' : 'Moments';
String get _me => _chinese ? '我的' : 'Me';
String get _menu => _chinese ? '菜单' : 'Menu';
String get _contacts => _chinese ? '通讯录' : 'Contacts';
String _longPressed(String name) => _chinese ? '长按了「$name」' : 'Long-pressed "$name"';
String get _cancel => _chinese ? '取消' : 'Cancel';

const Color _blue = Color(0xFF3A57ED);
const String _backgroundImage = 'https://fc3tn.baidu.com/it/u=3025909226,1763324618&fm=202&src=bqdata';
const List<String> _styles = ['default', 'flatDesign'];

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: PAGDemo()));

// MARK: - The tab bar (TabBarCommon.swift, RootTabBarController.swift, CYLPlusButtonSubclass.swift)

List<CYLTabBarItem> _items() {
  CYLTabBarItem tab(String title, String identifier, String image, String animation, [Map<String, Object?> extra = const {}]) =>
      CYLTabBarItem(
        title: title,
        identifier: identifier,
        image: CYLTabBarImage.name(image),
        selectedImage: CYLTabBarImage.name('${image}Selected'),
        attributes: {
          'CYLTabBarAnimationFilePath': animation,
          'CYLTabBarAnimationSize': '{33, 33}',
          // customizeInterface(): light gray titles, blue when selected. 浅灰色标题，选中时为蓝色。
          'CYLTabBarItemTitleColor': '#AAAAAA',
          'CYLTabBarItemSelectedTitleColor': '#3A57ED',
          ...extra,
        },
      );
  return [
    tab(_home, 'home', 'Home', 'tab_home.pag'),
    tab(_health, 'health', 'Message', 'tab_health.pag', {'CYLTabBarItemDarkImage': 'Message_night'}),
    tab(_moments, 'moments', 'lianxiren', 'tab_moments.pag'),
    tab(_me, 'me', 'Me', 'tab_me.pag'),
  ];
}

/// customizeInterface(): a white bar without its top line. 白色 TabBar，去掉顶部分割线。
const Map<String, Object?> _themes = {
  'CYLTabBarControllerThemes': {
    'default': {'CYLTabBarBackgroundColor': '#FFFFFF', 'CYLTabBarShadowColor': '#00000000'},
  },
};

// MARK: - Navigation (RootNavigationController: a blue bar, white title and buttons) 导航

class _BlueNavigator extends StatelessWidget {
  const _BlueNavigator({required this.title, required this.body, this.actions = const []});

  final String title;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          actions: actions,
        ),
        body: body,
      );
}

/// HomeVC → ChilderVC (a picture, "next") → NextVC.
class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) => _BlueNavigator(
        title: _home,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_full, size: 18),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _ChildPage())),
          ),
        ],
        body: const ColoredBox(color: Colors.red, child: SizedBox.expand()),
      );
}

class _ChildPage extends StatelessWidget {
  const _ChildPage();

  @override
  Widget build(BuildContext context) => _BlueNavigator(
        title: '',
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const _BlueNavigator(title: '', body: ColoredBox(color: Colors.white, child: SizedBox.expand())))),
            child: const Text('next', style: TextStyle(color: Colors.white, fontSize: 15)),
          ),
        ],
        body: Image.network(_backgroundImage, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
      );
}

class _MePage extends StatelessWidget {
  const _MePage({required this.styleIndex, required this.onStyle, required this.badges, required this.onBadges});

  final int styleIndex;
  final VoidCallback onStyle;
  final bool badges;
  final ValueChanged<bool> onBadges;

  @override
  Widget build(BuildContext context) => _BlueNavigator(
        title: _me,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 8),
              child: Text(_chinese ? 'TabBar 外观' : 'Tab bar appearance',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF3C3C43))),
            ),
            DecoratedBox(
              decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                ListTile(
                  title: Text(_chinese ? '样式' : 'Style'),
                  trailing: Text(_styles[styleIndex] == 'flatDesign' ? 'FlatDesign' : 'Liquid Glass / Classic',
                      style: const TextStyle(color: Color(0xFF8E8E93))),
                  onTap: onStyle,
                ),
                const Divider(height: 1, indent: 16),
                SwitchListTile(title: Text(_chinese ? 'Tab 角标' : 'Tab badges'), value: badges, onChanged: onBadges),
              ]),
            ),
          ],
        ),
      );
}

// MARK: - The app

class PAGDemo extends StatefulWidget {
  const PAGDemo({super.key});

  @override
  State<PAGDemo> createState() => _PAGDemoState();
}

class _PAGDemoState extends State<PAGDemo> {
  /// The selected tab; -1 is the plus button's page. 选中的 Tab；-1 为 PlusButton 的页面。
  int _selected = 0;
  int _styleIndex = 0;
  int _plusBadge = 0;
  bool _tabBadges = false;
  final List<CYLTabBarItem> _tabs = _items();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // demoShowPlusButtonBadgeAfterLayout(): 1 after launch. 启动后显示 1。
    _timer = Timer(const Duration(milliseconds: 1500), () => setState(() => _plusBadge = _plusBadge > 0 ? _plusBadge : 1));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _page() {
    switch (_selected) {
      case -1:
        return _BlueNavigator(title: _menu, body: const ColoredBox(color: Colors.orange, child: SizedBox.expand()));
      case 0:
        return const _HomePage();
      case 1:
        return _BlueNavigator(title: _health, body: const ColoredBox(color: Colors.blue, child: SizedBox.expand()));
      case 2:
        return _BlueNavigator(title: _contacts, body: const ColoredBox(color: Colors.purple, child: SizedBox.expand()));
      default:
        return _MePage(
          styleIndex: _styleIndex,
          onStyle: () => setState(() => _styleIndex = (_styleIndex + 1) % _styles.length),
          badges: _tabBadges,
          onBadges: (on) => setState(() => _tabBadges = on),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // [EN] Each tab keeps its own navigation stack. [CN] 每个 Tab 有自己的导航栈。
      Positioned.fill(child: Navigator(key: ValueKey(_selected), onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => _page()))),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: CYLTabBar(
          items: _tabs,
          styleType: _styles[_styleIndex],
          animationSpeed: 1.5,
          tapAnimation: 'bounce',
          swipeToSwitchTab: true,
          configuration: _themes,
          plusButton: CYLTabBarPlusButton(
            backgroundImage: const CYLTabBarImage.name('tabbar_database'),
            title: _menu,
            titleColor: '#FFFFFF',
            titleFont: 15,
            keepsTitleVisible: true,
            index: 2,
            centerYMultiplier: 0.3,
            centerYOffset: -30,
            identifier: 'plus',
            pageIdentifier: 'menu',
          ),
          selectedIndex: _selected,
          badgeValues: _tabBadges ? const ['', 'dot', '3', ''] : const [],
          plusButtonBadgeValue: _plusBadge > 0 ? '$_plusBadge' : '',
          badgeAnimation: CYLTabBarBadgeAnimation.bounce,
          onTabSelect: (index, identifier) => setState(() => _selected = index),
          onPlusButtonPress: () => setState(() => _plusBadge += 1),
          onTabLongPress: (index, identifier, title) => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(_longPressed(title)),
              actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(_cancel))],
            ),
          ),
        ),
      ),
    ]);
  }
}
