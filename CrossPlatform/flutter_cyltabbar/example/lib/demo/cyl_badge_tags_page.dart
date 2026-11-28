// [EN] docs/Animated-Item-Badge-CrossPlatform.md, step F4: badges on tags whose icon is a CYLAnimationView (the native
//      CYLAnimatedItemView). A tag only passes badgeValue and badgeAttributes; no Flutter widget is stacked on the icon.
//      reservesBadgeSpace keeps the badge inside the platform view's bounds.
// [CN] docs/Animated-Item-Badge-CrossPlatform.md，步骤 F4：图标为 CYLAnimationView（原生 CYLAnimatedItemView）的 Tag 上的角标。
//      Tag 只传 badgeValue 与 badgeAttributes；图标上不叠加任何 Flutter 组件。reservesBadgeSpace 让角标留在 platform view 范围内。
import 'package:flutter/material.dart';
import 'package:flutter_cyltabbar/flutter_cyltabbar.dart';

class CYLBadgeTagsPage extends StatefulWidget {
  const CYLBadgeTagsPage({super.key});

  @override
  State<CYLBadgeTagsPage> createState() => _CYLBadgeTagsPageState();
}

class _CYLBadgeTagsPageState extends State<CYLBadgeTagsPage> {
  // [EN] (value, animation, respects Reduce Motion), as the first nine badge samples; repeat counts have no attribute key.
  // [CN] （值、动画、是否遵循减弱动态效果），对应前九个角标示例；重复次数没有对应的属性键。
  static const List<(String, String, bool)> _samples = [
    ('3', 'Scale', false),
    ('3', 'Shake', false),
    ('3', 'Bounce', false),
    ('', 'Breathe', false),
    ('3', 'Shake', true),
    ('new', 'RollingOnce', false),
    ('3', 'ScaleOnce', false),
    ('8', 'None', false),
    ('100', 'None', false),
  ];

  bool _shows = true;
  // [EN] Right-to-left on this page only: the plugin passes Directionality to the native view (AC8). [CN] 仅本页从右到左：插件把 Directionality 传给原生视图（AC8）。
  bool _rightToLeft = false;

  Widget _tag(String title, {String? value, Map<String, Object?>? attributes}) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsetsDirectional.only(start: 4, end: 16),
      decoration: BoxDecoration(color: const Color(0x33888888), borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            // [EN] Wide enough for "99+": the platform view clips what it does not contain. [CN] 足够容纳 "99+"：platform view 会裁掉超出部分。
            width: 64,
            height: 52,
            child: CYLAnimationView(
              file: '',
              image: 'cyl_still_check.png',
              iconSize: 30,
              reservesBadgeSpace: true,
              badgeValue: value,
              badgeAttributes: attributes,
            ),
          ),
          const SizedBox(width: 4),
          Text(title),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: _rightToLeft ? TextDirection.rtl : TextDirection.ltr,
    child: _page(),
  );

  Widget _page() => Scaffold(
    appBar: AppBar(
      title: const Text('CYLAnimationView badges'),
      actions: [TextButton(onPressed: () => setState(() => _rightToLeft = !_rightToLeft), child: const Text('RTL'))],
    ),
    body: ListView(
      // [EN] The key rebuilds the platform views, which take their direction when created. [CN] key 重建 platform view，它们在创建时取得方向。
      key: ValueKey(_rightToLeft),
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.tonal(
            onPressed: () => setState(() => _shows = !_shows),
            child: Text(_shows ? 'badgeValue = null' : 'badgeValue'),
          ),
        ),
        for (final (index, (value, animation, reduce)) in _samples.indexed)
          _tag(
            '${index + 1}. $animation${reduce ? ', Reduce Motion' : ''}',
            value: _shows ? value : null,
            attributes: {CYLBadgeAttributeKey.animation: animation, CYLBadgeAttributeKey.respectsReduceMotion: reduce},
          ),
        _tag('badgeValue = null'),
      ],
    ),
  );
}
