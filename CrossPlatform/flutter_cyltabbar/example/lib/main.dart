import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_cyltabbar/flutter_cyltabbar.dart';

void main() => runApp(const MaterialApp(home: ExamplePage()));

// The tabs: the same keys as a CYLTabBarController configuration file (docs/Configuration-File.md), with Flutter asset
// images. 与 CYLTabBarController 配置文件相同的键，图片为 Flutter asset。
const _items = [
  CYLTabBarItem(
    title: 'Home',
    identifier: 'home',
    image: CYLTabBarImage.asset('assets/home_normal.png'),
    selectedImage: CYLTabBarImage.asset('assets/home_highlight.png'),
  ),
  CYLTabBarItem(
    title: 'Fishpond',
    identifier: 'fishpond',
    image: CYLTabBarImage.asset('assets/fishpond_normal.png'),
    selectedImage: CYLTabBarImage.asset('assets/fishpond_highlight.png'),
  ),
  CYLTabBarItem(
    title: 'Message',
    identifier: 'message',
    image: CYLTabBarImage.asset('assets/message_normal.png'),
    selectedImage: CYLTabBarImage.asset('assets/message_highlight.png'),
  ),
  CYLTabBarItem(
    title: 'Me',
    identifier: 'account',
    image: CYLTabBarImage.asset('assets/account_normal.png'),
    selectedImage: CYLTabBarImage.asset('assets/account_highlight.png'),
  ),
];

const _styles = ['default', 'liquidGlass', 'flatDesign'];

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  int _selectedIndex = 0;
  int _styleIndex = 0;
  int _plusTaps = 0;
  List<String> _badges = const ['', 'dot', '3', ''];
  final _random = Random();

  @override
  Widget build(BuildContext context) {
    final item = _items[_selectedIndex];
    return Scaffold(
      backgroundColor: Colors.white,
      // The page: Flutter draws it; the native widget draws only the bar. 页面由 Flutter 绘制，组件只绘制 TabBar。
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Text(item.title!, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
            Text('identifier: ${item.identifier}'),
            Text('style: ${_styles[_styleIndex]}'),
            Text('plus button taps: $_plusTaps'),
            TextButton(
              onPressed: () => setState(() => _styleIndex = (_styleIndex + 1) % _styles.length),
              child: const Text('Next style'),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 2),
              child: const Text('Select Message from Dart'),
            ),
            TextButton(
              onPressed: () => setState(() {
                _badges = [for (var i = 0; i < _items.length; i++) i == _selectedIndex ? '' : '${_random.nextInt(20) + 1}'];
              }),
              child: const Text('Change badges'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CYLTabBar(
        items: _items,
        styleType: _styles[_styleIndex],
        plusButton: const CYLTabBarPlusButton(title: 'Post', image: CYLTabBarImage.asset('assets/post_normal.png')),
        selectedIndex: _selectedIndex,
        badgeValues: _badges,
        onTabSelect: (index, identifier) => setState(() => _selectedIndex = index),
        onPlusButtonPress: () => setState(() => _plusTaps++),
      ),
    );
  }
}
