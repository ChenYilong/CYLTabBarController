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

  bool get _dark => Theme.of(context).brightness == Brightness.dark;

  // [EN] A Liquid Glass capsule as wide as its content, as in the example's tag lists. [CN] 与示例 TagList 相同：宽度随内容的液态玻璃胶囊。
  Widget _tag(String title, {String? value, Map<String, Object?>? attributes}) => Container(
    padding: const EdgeInsetsDirectional.only(start: 4, end: 16),
    decoration: ShapeDecoration(
      color: _dark ? const Color(0x1FFFFFFF) : const Color(0x99FFFFFF),
      shape: const StadiumBorder(side: BorderSide(color: Color(0x66FFFFFF))),
    ),
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
        Flexible(child: Text(title)),
      ],
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
    // [EN] The gradient plate of the example's tag lists. [CN] 示例 TagList 的渐变背景板。
    body: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _dark
              ? const [Color(0xFF5B2A3C), Color(0xFF1F4A63), Color(0xFF3B2D5C)]
              : const [Color(0xFFFFB199), Color(0xFF7EC8E3), Color(0xFFC3AED6)],
        ),
      ),
      child: SizedBox.expand(
        child: ListView(
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
            const Padding(
              padding: EdgeInsetsDirectional.only(start: 16, top: 12, bottom: 8),
              child: Text('Badges', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
            // [EN] The tags flow and wrap in a section card. [CN] 标签在分组卡片中流式换行。
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _dark ? const Color(0x1FFFFFFF) : const Color(0x99FFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x40FFFFFF)),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final (index, (value, animation, reduce)) in _samples.indexed)
                    _tag(
                      '${index + 1}. $animation${reduce ? ', Reduce Motion' : ''}',
                      value: _shows ? value : null,
                      attributes: {CYLBadgeAttributeKey.animation: animation, CYLBadgeAttributeKey.respectsReduceMotion: reduce},
                    ),
                  _tag('badgeValue = null'),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
