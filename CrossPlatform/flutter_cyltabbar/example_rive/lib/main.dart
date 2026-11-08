// The Flutter twin of Example-Rive: the same tab bar (Rive icons of the course's icons.riv, a purple "Start" plus button
// with its own page, a dark glass bar), built from a configuration through CYLTabBar, and the course's pages
// (Example-SwiftUI-Rive/AnimatedApp) drawn by Flutter. Their Rive animations play through CYLAnimationView,
// CYLTabBarController's own engine. The .riv files are added to the iOS app (ios/) and to the Android assets
// (android/app/build.gradle.kts); the course's images and fonts are Flutter assets.
// Example-Rive 的 Flutter 版本：同样的 TabBar，通过 CYLTabBar 由配置创建；课程页面由 Flutter 绘制，其中的 Rive 动画通过 CYLAnimationView 播放。
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_cyltabbar/flutter_cyltabbar.dart';

final bool _chinese = PlatformDispatcher.instance.locale.languageCode == 'zh';

// MARK: - Course styles (Styles/CustomFont.swift; the app is dark: Assets.xcassets/Colors) 课程样式

const Color _background = Color(0xFF25254B);
const Color _background2 = Color(0xFF17203A);
const TextStyle _largeTitle = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 34, color: Colors.white);
const TextStyle _title2 = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 24, color: Colors.white);
const TextStyle _title3 = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white);
const TextStyle _body = TextStyle(fontFamily: 'Inter', fontSize: 17, color: Colors.white);
const TextStyle _headline = TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 17, color: Colors.white);
const TextStyle _subheadline = TextStyle(fontFamily: 'Inter', fontSize: 15, color: Colors.white);
const TextStyle _subheadline2 = TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white);
const TextStyle _footnote = TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white);
const TextStyle _footnote2 = TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white);
const Color _secondary = Color(0xFF8E8E93);

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: RiveDemo()));

// MARK: - The tab bar (TabItems.swift, RivePlusButton.swift, SceneDelegate.swift)

const List<(String, String, String, String)> _tabs = [
  ('chat', 'Chat', 'CHAT', 'message'),
  ('search', 'Search', 'SEARCH', 'magnifyingglass'),
  ('bell', 'Bell', 'BELL', 'bell'),
  ('user', 'User', 'USER', 'person'),
];

List<CYLTabBarItem> _items() => [
      for (final (id, title, artboard, symbol) in _tabs)
        CYLTabBarItem(
          title: title,
          identifier: id,
          image: CYLTabBarImage.name('system:$symbol'),
          selectedImage: CYLTabBarImage.name('system:$symbol'),
          attributes: {
            // [EN] The tab's artboard of icons.riv; icons.riv has no view model, so its state machine input "active" plays.
            // [CN] icons.riv 中该 Tab 的画板；icons.riv 没有 view model，因此播放其状态机输入 "active"。
            'CYLTabBarRiveFilePath': 'icons.riv',
            'CYLTabBarAnimationOptions': {'artboard': artboard, 'stateMachine': '${artboard}_Interactivity', 'input': 'active'},
            'CYLTabBarRiveSize': '{32, 32}',
          },
        ),
    ];

/// applyCourseTabBarAppearance(): "Background 2" at 80%, white icons and titles, for the whole bar (the plus button's
/// title, aligned with the tab titles, too). "Background 2" 80% 不透明度，整个 TabBar 使用白色图标与标题。
const Map<String, Object?> _themes = {
  'CYLTabBarControllerThemes': {
    'course': {
      'CYLTabBarBackgroundColor': '#17203ACC',
      'CYLTabBarItemTitleColor': '#FFFFFF99',
      'CYLTabBarItemSelectedTitleColor': '#FFFFFF',
      'CYLTabBarItemIconColor': '#FFFFFF99',
      'CYLTabBarItemSelectedIconColor': '#FFFFFF',
    },
  },
};
const List<String> _styles = ['liquidGlass', 'flatDesign'];

// MARK: - Navigation bar (a UINavigationController with the tab's title) 导航栏

class _NavigationBar extends StatelessWidget {
  const _NavigationBar(this.title, {this.color = _background});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        color: color,
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        height: MediaQuery.paddingOf(context).top + 44,
        alignment: Alignment.center,
        child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
      );
}

// MARK: - Chat: HomeView (Views/HomeView.swift, Components/VCard.swift, HCard.swift)

const _courses = [
  ('Animations in SwiftUI', 'Build and animate an iOS app from scratch', '20 sections - 3 hours', Color(0xFF7850F0), 'topic_1'),
  ('Build Quick Apps with SwiftUI', 'Apply your Swift and SwiftUI knowledge by building real, quick and various applications from scratch', '47 sections - 11 hours', Color(0xFF6792FF), 'topic_2'),
  ('Build a SwiftUI app for iOS 15', 'Design and code a SwiftUI 3 app with custom layouts, animations and gestures using Xcode 13, SF Symbols 3, Canvas, Concurrency, Searchable and a whole lot more', '21 sections - 4 hours', Color(0xFF005FE7), 'topic_1'),
];
const _sections = [
  ('State Machine', 'Watch video - 15 mins', Color(0xFF9CC5FF), 'topic_2'),
  ('Animated Menu', 'Watch video - 10 mins', Color(0xFF6E6AE8), 'topic_1'),
  ('Tab Bar', 'Watch video - 8 mins', Color(0xFF005FE7), 'topic_2'),
  ('Button', 'Watch video - 9 mins', Color(0xFFBBA6FF), 'topic_1'),
];

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: _background,
        child: Column(children: [
          const _NavigationBar('Chat'),
          Expanded(
            child: ListView(padding: const EdgeInsets.only(bottom: 140), children: [
              const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Courses', style: _largeTitle)),
              SizedBox(
                height: 360,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  children: [
                    for (final (title, subtitle, caption, color, image) in _courses)
                      Container(
                        width: 260,
                        margin: const EdgeInsets.only(right: 20),
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 12))],
                        ),
                        child: Stack(children: [
                          Positioned(top: -10, right: -10, child: Image.asset('assets/course/$image.png')),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            SizedBox(width: 170, child: Text(title, style: _title2)),
                            const SizedBox(height: 8),
                            Flexible(child: Opacity(opacity: 0.7, child: Text(subtitle, style: _body, overflow: TextOverflow.fade))),
                            const SizedBox(height: 8),
                            Opacity(opacity: 0.7, child: Text(caption.toUpperCase(), style: _footnote2)),
                            const Spacer(),
                            SizedBox(
                              height: 44,
                              child: Stack(children: [
                                for (final (index, avatar) in ['avatar_4', 'avatar_5', 'avatar_6'].indexed)
                                  Positioned(left: index * 24.0, child: ClipOval(child: Image.asset('assets/course/$avatar.png', width: 44, height: 44))),
                              ]),
                            ),
                          ]),
                        ]),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(padding: EdgeInsets.only(bottom: 20), child: Text('Recent', style: _title3)),
                  for (final (title, caption, color, image) in _sections)
                    Container(
                      height: 110,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(30)),
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(title, style: _title2.copyWith(height: 1.2), maxLines: 1),
                            Text(caption, style: _body.copyWith(height: 1.2)),
                          ]),
                        ),
                        const VerticalDivider(color: Colors.white54, width: 40),
                        Image.asset('assets/course/$image.png'),
                      ]),
                    ),
                ]),
              ),
            ]),
          ),
        ]),
      );
}

// MARK: - Search: SideMenu (Navigation/SideMenu.swift), its icons from icons.riv

const _browse = [('Home', 'HOME', 'HOME_interactivity'), ('Search', 'SEARCH', 'SEARCH_Interactivity'), ('Favorites', 'LIKE/STAR', 'STAR_Interactivity'), ('Help', 'CHAT', 'CHAT_Interactivity')];
const _history = [('History', 'TIMER', 'TIMER_Interactivity'), ('Notifications', 'BELL', 'BELL_Interactivity')];

class _MenuRow extends StatefulWidget {
  const _MenuRow(this.item, {required this.selected, required this.onTap});

  final (String, String, String) item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    final (text, artboard, machine) = widget.item;
    return GestureDetector(
      onTap: () {
        widget.onTap();
        setState(() => _playing = true);
        Timer(const Duration(seconds: 2), () => mounted ? setState(() => _playing = false) : null);
      },
      child: Container(
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: widget.selected ? const Color(0xFF6E6AE8) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CYLAnimationView(
              file: 'icons.riv',
              options: {'artboard': artboard, 'stateMachine': machine, 'input': 'active', 'duration': 2},
              playing: _playing,
            ),
          ),
          const SizedBox(width: 14),
          Text(text, style: _headline),
        ]),
      ),
    );
  }
}

class _SideMenuPage extends StatefulWidget {
  const _SideMenuPage();

  @override
  State<_SideMenuPage> createState() => _SideMenuPageState();
}

class _SideMenuPageState extends State<_SideMenuPage> {
  String _selected = 'Home';
  bool _dark = true;

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 8),
        child: Opacity(opacity: 0.7, child: Text(text, style: _subheadline2)),
      );

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: _background2,
        child: Column(children: [
          const _NavigationBar('Search', color: _background),
          Expanded(
            child: ListView(padding: const EdgeInsets.only(bottom: 140), children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(children: [
                  CircleAvatar(radius: 22, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
                  SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Meng To', style: _body),
                    Opacity(opacity: 0.7, child: Text('UI Designer', style: _subheadline)),
                  ]),
                ]),
              ),
              _header('BROWSE'),
              for (final item in _browse) _MenuRow(item, selected: _selected == item.$1, onTap: () => setState(() => _selected = item.$1)),
              _header('HISTORY'),
              for (final item in _history) _MenuRow(item, selected: _selected == item.$1, onTap: () => setState(() => _selected = item.$1)),
              Container(
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CYLAnimationView(
                      file: 'icons.riv',
                      options: const {'artboard': 'SETTINGS', 'stateMachine': 'SETTINGS_Interactivity', 'input': 'active', 'duration': 0},
                      playing: _dark,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(child: Text('Dark Mode', style: _headline)),
                  Switch(value: _dark, onChanged: (value) => setState(() => _dark = value)),
                ]),
              ),
            ]),
          ),
        ]),
      );
}

// MARK: - Start: OnboardingView (Views/OnboardingView.swift): shapes.riv behind, button.riv to start

class _OnboardingPage extends StatefulWidget {
  const _OnboardingPage();

  @override
  State<_OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<_OnboardingPage> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: _background,
        child: Stack(children: [
          Positioned(
            left: 200,
            top: 100,
            child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), child: Image.asset('assets/course/spline.png')),
          ),
          const Positioned.fill(child: CYLAnimationView(file: 'shapes.riv', options: {'legacy': 1}, playing: true)),
          Column(children: [
            const _NavigationBar('Start', color: Colors.transparent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 40, 40, 140),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(
                    width: 260,
                    child: Text('Learn design & code',
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 60, height: 1.1, color: Colors.white)),
                  ),
                  const SizedBox(height: 16),
                  const Opacity(
                    opacity: 0.7,
                    child: Text('Don’t skip design. Learn design and code, by building real apps with React and Swift. Complete courses about the best tools.', style: _body),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() => _pressed = true);
                      Timer(const Duration(milliseconds: 800), () => mounted ? setState(() => _pressed = false) : null);
                    },
                    child: SizedBox(
                      width: 236,
                      height: 64,
                      child: Stack(alignment: Alignment.center, children: [
                        Positioned.fill(child: CYLAnimationView(file: 'button.riv', options: const {'animation': 'active'}, playing: _pressed)),
                        const Padding(
                          padding: EdgeInsets.only(top: 8, left: 8),
                          child: Text('→  Start the course', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 17, color: Colors.black)),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Opacity(
                    opacity: 0.7,
                    child: Text('Purchase includes access to 30+ courses, 240+ premium tutorials, 120+ hours of videos, source files and certificates.', style: _footnote),
                  ),
                ]),
              ),
            ),
          ]),
        ]),
      );
}

// MARK: - Bell: menu_button.riv (RiveMenuButtonDemoView.swift) above the settings list

class _BellPage extends StatefulWidget {
  const _BellPage({required this.styleIndex, required this.onStyle});

  final int styleIndex;
  final VoidCallback onStyle;

  @override
  State<_BellPage> createState() => _BellPageState();
}

class _BellPageState extends State<_BellPage> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Colors.black,
        child: Column(children: [
          const _NavigationBar('Bell'),
          Expanded(
            child: ListView(padding: const EdgeInsets.only(bottom: 140), children: [
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: CYLAnimationView(
                    file: 'menu_button.riv',
                    options: const {'stateMachine': 'State Machine', 'input': 'isOpen', 'duration': 0},
                    playing: _open,
                  ),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _open = !_open),
                  child: Text(_chinese ? '播放 / 停止' : 'Play / Stop', style: const TextStyle(color: Color(0xFF0A84FF), fontSize: 17, fontWeight: FontWeight.w600)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 8),
                child: Text(_chinese ? 'TabBar 外观' : 'Tab bar appearance',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFEBEBF5))),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  title: Text(_chinese ? '样式' : 'Style', style: const TextStyle(color: Colors.white)),
                  trailing: Text(_styles[widget.styleIndex] == 'flatDesign' ? 'FlatDesign' : 'Liquid Glass', style: const TextStyle(color: _secondary)),
                  onTap: widget.onStyle,
                ),
              ),
            ]),
          ),
        ]),
      );
}

// MARK: - User: SignInView (Views/SignInView.swift): check.riv and confetti.riv

class _SignInPage extends StatefulWidget {
  const _SignInPage();

  @override
  State<_SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<_SignInPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _loading = false;
  bool _succeeded = false;
  bool _check = false;
  bool _confetti = false;

  void _logIn() {
    final ok = _email.text.isNotEmpty;
    setState(() {
      _loading = true;
      _succeeded = ok;
    });
    Timer(const Duration(seconds: 1), () => setState(() => _check = true));
    Timer(const Duration(seconds: 3), () => setState(() {
          _confetti = ok;
          _loading = false;
          _check = false;
        }));
    Timer(const Duration(seconds: 4), () => setState(() => _confetti = false));
  }

  Widget _field(TextEditingController controller, String icon, {bool secure = false}) => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
        padding: const EdgeInsets.only(left: 8),
        child: Row(children: [
          Image.asset('assets/course/$icon.png'),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: controller, obscureText: secure, decoration: const InputDecoration(border: InputBorder.none))),
        ]),
      );

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: _background,
        child: Column(children: [
          const _NavigationBar('User'),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 140), children: [
              Stack(children: [
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(20)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Center(child: Text('Sign in', style: _largeTitle.copyWith(color: Colors.black))),
                    const SizedBox(height: 12),
                    Text('Access to 240+ hours of content. Learn design and code, by building real apps with React and Swift.',
                        textAlign: TextAlign.center, style: _body.copyWith(color: _secondary)),
                    const SizedBox(height: 12),
                    Text('Email', style: _subheadline.copyWith(color: _secondary)),
                    const SizedBox(height: 6),
                    _field(_email, 'icon_email'),
                    const SizedBox(height: 12),
                    Text('Password', style: _subheadline.copyWith(color: _secondary)),
                    const SizedBox(height: 6),
                    _field(_password, 'icon_lock', secure: true),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _logIn,
                      child: Container(
                        height: 60,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF77D8E),
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                        ),
                        child: const Text('→  Sign in', style: _headline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      const Expanded(child: Divider(color: Colors.black12)),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('OR', style: _subheadline2.copyWith(color: Colors.black26))),
                      const Expanded(child: Divider(color: Colors.black12)),
                    ]),
                    const SizedBox(height: 12),
                    Center(child: Text('Sign up with Email, Apple, Google', style: _subheadline.copyWith(color: _secondary))),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Image.asset('assets/course/logo_email.png'),
                      Image.asset('assets/course/logo_apple.png'),
                      Image.asset('assets/course/logo_google.png'),
                    ]),
                  ]),
                ),
                if (_loading)
                  Positioned.fill(
                    child: Center(
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: CYLAnimationView(
                          file: 'check.riv',
                          options: {'stateMachine': 'State Machine 1', 'triggerInput': _succeeded ? 'Check' : 'Error'},
                          playing: _check,
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CYLAnimationView(
                      file: 'confetti.riv',
                      options: const {'stateMachine': 'State Machine 1', 'triggerInput': 'Trigger explosion'},
                      playing: _confetti,
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      );
}

// MARK: - The app

class RiveDemo extends StatefulWidget {
  const RiveDemo({super.key});

  @override
  State<RiveDemo> createState() => _RiveDemoState();
}

class _RiveDemoState extends State<RiveDemo> {
  String _selected = 'chat';
  int _styleIndex = 0;
  int _plusBadge = 0;
  final List<CYLTabBarItem> _tabItems = _items();
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
      case 'plus':
        return const _OnboardingPage();
      case 'search':
        return const _SideMenuPage();
      case 'bell':
        return _BellPage(styleIndex: _styleIndex, onStyle: () => setState(() => _styleIndex = (_styleIndex + 1) % _styles.length));
      case 'user':
        return const _SignInPage();
      default:
        return const _HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = _tabs.indexWhere((tab) => tab.$1 == _selected);
    return Material(
      color: Colors.black,
      child: Stack(children: [
        Positioned.fill(child: KeyedSubtree(key: ValueKey(_selected), child: _page())),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: CYLTabBar(
            items: _tabItems,
            styleType: _styles[_styleIndex],
            userInterfaceStyle: 'dark',
            tapAnimation: 'bounce',
            swipeToSwitchTab: true,
            configuration: _themes,
            plusButton: const CYLTabBarPlusButton(
              image: CYLTabBarImage.asset('assets/rive_plus.png'),
              title: 'Start',
              index: 2,
              identifier: 'plus',
              pageIdentifier: 'timer',
            ),
            selectedIndex: index,
            plusButtonBadgeValue: _plusBadge > 0 ? '$_plusBadge' : '',
            badgeAnimation: CYLTabBarBadgeAnimation.bounce,
            onTabSelect: (index, identifier) => setState(() => _selected = index < 0 ? 'plus' : identifier),
            onPlusButtonPress: () => setState(() => _plusBadge += 1),
            onTabLongPress: (index, identifier, title) => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(_chinese ? '长按了「$title」' : 'Long-pressed "$title"'),
                actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(_chinese ? '取消' : 'Cancel'))],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
