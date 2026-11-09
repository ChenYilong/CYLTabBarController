// The demo list of the Objective-C example, shown on every tab (UIViewController+CYLSettingsSection.m and the badge
// samples of UITableViewCell+CYLBadgeExtention.m). The rows come from Example-Shared/CYLDemoList/demo-list.json, copied to
// assets/demo by scripts/sync-example-shared.py; `values` fills in the "{name}" parts, `onRow` handles a tap.
// Objective-C 示例的演示列表，每个 Tab 都显示。行数据来自 Example-Shared/CYLDemoList/demo-list.json（由 scripts/sync-example-shared.py
// 复制到 assets/demo）；`values` 填入「{name}」部分，`onRow` 处理点击。
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../cyl_skins.dart';
import 'cyl_badge_view.dart';

class CYLDemoRow {
  CYLDemoRow(Map<String, dynamic> json)
    : id = json['id'] as String,
      icon = json['icon'] as String?,
      title = json['title'] as String,
      subtitle = json['subtitle'] as String? ?? '',
      accessory = json['accessory'] as String? ?? 'none',
      link = json['link'] == true,
      button = json['button'] as String?,
      skin = null,
      badge = null;

  CYLDemoRow.custom({
    required this.id,
    this.icon,
    required this.title,
    required this.subtitle,
    this.skin,
    this.badge,
  }) : accessory = 'none',
       link = false,
       button = null;

  final String id;
  final String? icon;
  final String title;
  final String subtitle;
  final String accessory;
  final bool link;
  final String? button;

  /// Set for the skin rows and the badge samples. 皮肤行与角标样例使用。
  final CYLSkin? skin;
  final CYLBadgeSample? badge;
}

class CYLDemoSection {
  CYLDemoSection(this.title, this.rows);
  final String title;
  final List<CYLDemoRow> rows;
}

/// demo-list.json, loaded once. 只加载一次的 demo-list.json。
final Future<List<CYLDemoSection>> demoSections = rootBundle
    .loadString('assets/demo/demo-list.json')
    .then((text) {
      final json = jsonDecode(text) as Map<String, dynamic>;
      final sections = <CYLDemoSection>[
        for (final section in json['sections'] as List)
          CYLDemoSection(
            section['title'] as String,
            section['skins'] == true
                ? [
                    for (final skin in skins)
                      CYLDemoRow.custom(
                        id: 'skin:${skin.name}',
                        title: skin.name,
                        subtitle: skin.network != null
                            ? 'Network icons, titles and colors'
                            : (skin.icons != null
                                  ? 'Holiday icons and colors'
                                  : 'Colors only'),
                        skin: skin,
                      ),
                  ]
                : [
                    for (final row in section['rows'] as List)
                      CYLDemoRow(row as Map<String, dynamic>),
                  ],
          ),
      ];
      sections.add(
        CYLDemoSection('Badges', [
          for (final (index, sample) in (json['badgeSamples'] as List).indexed)
            CYLDemoRow.custom(
              id: 'badge:$index',
              icon: '@cyl_badge_sample_icon',
              title: (sample as Map<String, dynamic>)['title'] as String,
              subtitle: '',
              badge: CYLBadgeSample(sample),
            ),
        ]),
      );
      return sections;
    });

/// UIColor.systemGroupedBackgroundColor / labelColor / secondaryLabelColor / secondarySystemGroupedBackgroundColor / separatorColor.
class CYLDemoColors {
  const CYLDemoColors(this.dark);
  final bool dark;
  Color get background => dark ? Colors.black : const Color(0xFFF2F2F7);
  Color get label => dark ? Colors.white : Colors.black;
  Color get secondaryLabel =>
      dark ? const Color(0x99EBEBF5) : const Color(0x993C3C43);
  Color get card => dark ? const Color(0xFF1C1C1E) : Colors.white;
  Color get separator =>
      dark ? const Color(0x99545458) : const Color(0x4A3C3C43);
}

class CYLDemoList extends StatelessWidget {
  const CYLDemoList({
    super.key,
    required this.colors,
    required this.tint,
    required this.values,
    required this.switches,
    required this.currentSkin,
    required this.badgeSubtitle,
    required this.onRow,
    required this.onSwitch,
  });

  final CYLDemoColors colors;
  final Color tint;
  final Map<String, String> values;
  final Map<String, bool> switches;
  final String currentSkin;

  /// For example "Home (Liquid) CYLTabBarController on iOS 26.5". 例如「Home (Liquid) CYLTabBarController on iOS 26.5」。
  final String badgeSubtitle;
  final void Function(CYLDemoRow row, int index) onRow;
  final void Function(CYLDemoRow row, bool on) onSwitch;

  String _fill(String text) => text.replaceAllMapped(
    RegExp(r'\{(\w+)\}'),
    (match) => values[match[1]] ?? '-',
  );

  Widget _icon(CYLDemoRow row) {
    final skin = row.skin;
    if (skin != null) {
      return Padding(
        padding: const EdgeInsets.only(right: 16),
        child: skin.icons != null
            ? Image.asset(themeIcon(skin.icons!.first), width: 24, height: 24)
            : Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: hexColor(skin.tint ?? '#C7C7CC'),
                  shape: BoxShape.circle,
                ),
                child: skin.network != null
                    ? const Text(
                        '↓',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
      );
    }
    final icon = row.icon;
    if (icon == null) return const SizedBox.shrink();
    if (icon.startsWith('@')) {
      return Padding(
        padding: const EdgeInsets.only(right: 16),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset(
                'assets/demo/icons/${icon.substring(1)}.png',
                width: 30,
                height: 30,
              ),
              if (row.badge != null)
                CYLBadgeView(sample: row.badge!, hostSize: 30),
            ],
          ),
        ),
      );
    }
    final name = row.id == 'login' && switches['login'] == true
        ? 'person_crop_circle_badge_checkmark'
        : icon;
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Image.asset(
        'assets/demo/icons/$name.png',
        width: 24,
        height: 24,
        color: tint,
      ),
    );
  }

  Widget _accessory(CYLDemoRow row) {
    if (row.skin != null) {
      return row.skin!.name == currentSkin
          ? Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '✓',
                style: TextStyle(
                  fontSize: 17,
                  color: tint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : const SizedBox.shrink();
    }
    switch (row.accessory) {
      case 'chevron':
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Image.asset(
            'assets/demo/icons/chevron_right.png',
            width: 9,
            height: 14,
            color: colors.secondaryLabel,
          ),
        );
      case 'switch':
        return Switch.adaptive(
          value: switches[row.id] == true,
          onChanged: (on) => onSwitch(row, on),
        );
      case 'arrows':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final step in [-1, 1])
              GestureDetector(
                onTap: () => onRow(
                  CYLDemoRow.custom(
                    id: '${row.id}:$step',
                    title: row.title,
                    subtitle: row.subtitle,
                  ),
                  step,
                ),
                child: Semantics(
                  button: true,
                  label: step < 0 ? 'Previous tab' : 'Next tab',
                  excludeSemantics: true,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      step < 0 ? '◀︎' : '▶︎',
                      style: TextStyle(fontSize: 17, color: tint),
                    ),
                  ),
                ),
              ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// How VoiceOver / TalkBack reads a badge, as `CYLBadge`: "New content", "3 new messages" or its text. 读屏软件读出的角标内容。
  static String badgeAccessibilityText(String value) {
    if (value.isEmpty) return 'New content';
    return RegExp(r'^\d+$').hasMatch(value) ? '$value new messages' : value;
  }

  Widget _row(CYLDemoRow row, int index, int count) {
    final first = index == 0;
    final last = index == count - 1;
    final subtitle = row.badge != null ? badgeSubtitle : _fill(row.subtitle);
    // Accessibility: one element per row, its title and subtitle (and its badge); a switch row is the switch; rows with
    // their own buttons (arrows, "Tap me") let those buttons be reached. 无障碍：每行一个元素（标题、副标题与角标）；开关行即开关；
    // 带按钮的行（箭头、「Tap me」）让这些按钮可被访问。
    final isSwitch = row.accessory == 'switch';
    final grouped = row.accessory != 'arrows' && row.button == null;
    final label = [
      _fill(row.title),
      subtitle,
      if (row.badge != null) badgeAccessibilityText(row.badge!.value),
    ].where((part) => part.isNotEmpty).join(', ');
    return Semantics(
      container: true,
      button: grouped && !isSwitch,
      toggled: isSwitch ? switches[row.id] == true : null,
      selected: row.skin != null ? row.skin!.name == currentSkin : null,
      label: grouped ? label : null,
      excludeSemantics: grouped,
      onTap: grouped
          ? () => isSwitch
                ? onSwitch(row, switches[row.id] != true)
                : onRow(row, index)
          : null,
      child: _rowContent(row, index, first, last, subtitle, isSwitch),
    );
  }

  Widget _rowContent(
    CYLDemoRow row,
    int index,
    bool first,
    bool last,
    String subtitle,
    bool isSwitch,
  ) {
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(first ? 26 : 0),
        bottom: Radius.circular(last ? 26 : 0),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => isSwitch
            ? onSwitch(row, switches[row.id] != true)
            : onRow(row, index),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            border: last
                ? null
                : Border(
                    bottom: BorderSide(color: colors.separator, width: 0.5),
                  ),
          ),
          child: Row(
            children: [
              _icon(row),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fill(row.title),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: row.link ? tint : colors.label,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.secondaryLabel,
                          ),
                        ),
                      ),
                    if (row.button != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colors.separator,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: GestureDetector(
                          onTap: () => onRow(
                            CYLDemoRow.custom(
                              id: '${row.id}:button',
                              title: row.title,
                              subtitle: row.subtitle,
                            ),
                            index,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: tint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              row.button!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _accessory(row),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<CYLDemoSection>>(
    future: demoSections,
    builder: (context, snapshot) {
      final sections = snapshot.data ?? const [];
      return ColoredBox(
        color: colors.background,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          children: [
            for (final section in sections) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 28, 4, 10),
                child: Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: colors.secondaryLabel,
                  ),
                ),
              ),
              for (final (index, row) in section.rows.indexed)
                _row(row, index, section.rows.length),
            ],
          ],
        ),
      );
    },
  );
}
