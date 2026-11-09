/**
 * The demo list of the Objective-C example, shown on every tab (UIViewController+CYLSettingsSection.m and the badge
 * samples of UITableViewCell+CYLBadgeExtention.m). The rows come from Example-Shared/CYLDemoList/demo-list.json, copied
 * here by scripts/sync-example-shared.py; `values` fills in the "{name}" parts, `onRow` handles a tap.
 * Objective-C 示例的演示列表，每个 Tab 都显示。行数据来自 Example-Shared/CYLDemoList/demo-list.json（由 scripts/sync-example-shared.py
 * 复制到这里）；`values` 填入「{name}」部分，`onRow` 处理点击。
 */
import { Image, Pressable, SectionList, StyleSheet, Switch, Text, View, type ImageSourcePropType } from 'react-native';
import { CYLBadgeView, type CYLBadgeSample } from './CYLBadgeView';
import { DEMO_ICONS } from './icons';
import { SKINS, THEME_ICONS, type CYLSkin } from '../CYLSkins';

const DATA = require('./demo-list.json') as {
  sections: { id: string; title: string; rows: CYLDemoRow[]; skins?: boolean }[];
  badgeSamples: (CYLBadgeSample & { title: string })[];
};

export type CYLDemoRow = {
  id: string;
  icon: string | null;
  title: string;
  subtitle: string;
  accessory: 'none' | 'chevron' | 'switch' | 'arrows';
  link?: boolean;
  button?: string;
  slider?: boolean;
  /** Set for the skin rows and the badge samples. 皮肤行与角标样例使用。 */
  skin?: CYLSkin;
  badge?: CYLBadgeSample;
};

export type CYLDemoColors = { background: string; label: string; secondaryLabel: string; card: string; separator: string };

type Props = {
  colors: CYLDemoColors;
  tint: string;
  values: Record<string, string>;
  switches: Record<string, boolean>;
  currentSkin: string;
  /** For example "Home (Liquid) CYLTabBarController on iOS 26.5". 例如「Home (Liquid) CYLTabBarController on iOS 26.5」。 */
  badgeSubtitle: string;
  header?: React.ReactNode;
  onRow: (row: CYLDemoRow, index: number) => void;
  onSwitch: (row: CYLDemoRow, on: boolean) => void;
};

const fill = (text: string, values: Record<string, string>) => text.replace(/\{(\w+)\}/g, (_, name) => values[name] ?? '-');

/** How VoiceOver / TalkBack reads a badge, as `CYLBadge`: "New content", "3 new messages" or its text. 读屏软件读出的角标内容。 */
export function badgeAccessibilityText(value: string) {
  if (value === '') return 'New content';
  return /^\d+$/.test(value) ? `${value} new messages` : value;
}

/** [EN] What a skin row says it changes. [CN] 皮肤行说明它改变的内容。 */
function skinSubtitle(skin: CYLSkin): string {
  if (skin.network) {
    return 'Network icons, titles and colors';
  }
  return skin.icons ? 'Holiday icons and colors' : 'Colors only';
}

/** [EN] A switch row reports on / off; a skin row reports whether it is the current skin. [CN] 开关行报告开 / 关；皮肤行报告是否为当前皮肤。 */
function rowAccessibilityState(item: CYLDemoRow, isSwitch: boolean, switches: Record<string, boolean>, currentSkin: string) {
  if (isSwitch) {
    return { checked: !!switches[item.id] };
  }
  return item.skin ? { selected: item.skin.name === currentSkin } : undefined;
}

export function CYLDemoList({ colors, tint, values, switches, currentSkin, badgeSubtitle, header, onRow, onSwitch }: Readonly<Props>) {
  const sections = [
    ...DATA.sections.map((section) => ({
      title: section.title,
      data: section.skins
        ? SKINS.map<CYLDemoRow>((skin) => ({
            id: `skin:${skin.name}`,
            icon: null,
            title: skin.name,
            subtitle: skinSubtitle(skin),
            accessory: 'none',
            skin,
          }))
        : section.rows,
    })),
    {
      title: 'Badges',
      data: DATA.badgeSamples.map<CYLDemoRow>(({ title, ...badge }, index) => ({
        id: `badge:${index}`,
        icon: '@cyl_badge_sample_icon',
        title,
        subtitle: badgeSubtitle,
        accessory: 'none',
        badge,
      })),
    },
  ];

  const icon = (row: CYLDemoRow) => {
    if (row.skin) {
      const skin = row.skin;
      return skin.icons ? (
        <Image source={THEME_ICONS[skin.icons[0]!]!.image as ImageSourcePropType} style={styles.icon} />
      ) : (
        <View style={[styles.swatch, { backgroundColor: skin.tint ?? '#C7C7CC' }]}>
          {skin.network ? <Text style={styles.swatchGlyph}>↓</Text> : null}
        </View>
      );
    }
    if (!row.icon) return null;
    if (row.icon.startsWith('@')) {
      return (
        <View style={styles.iconBox}>
          <Image source={DEMO_ICONS[row.icon.slice(1)]!} style={styles.bundleIcon} />
          {row.badge ? <CYLBadgeView sample={row.badge} hostSize={30} /> : null}
        </View>
      );
    }
    const login = row.id === 'login' && switches.login ? 'person_crop_circle_badge_checkmark' : row.icon;
    return <Image source={DEMO_ICONS[login]!} style={[styles.icon, { tintColor: tint }]} />;
  };

  const accessory = (row: CYLDemoRow) => {
    if (row.skin) return row.skin.name === currentSkin ? <Text style={[styles.check, { color: tint }]}>✓</Text> : null;
    switch (row.accessory) {
      case 'chevron':
        return <Image source={DEMO_ICONS.chevron_right!} style={[styles.chevron, { tintColor: colors.secondaryLabel }]} />;
      case 'switch':
        // The row itself is the switch for accessibility (see below). 无障碍时整行即开关（见下）。
        return <Switch value={!!switches[row.id]} onValueChange={(on) => onSwitch(row, on)} accessibilityElementsHidden importantForAccessibility="no-hide-descendants" />;
      case 'arrows':
        return (
          <View style={styles.arrows}>
            <Pressable hitSlop={8} accessibilityRole="button" accessibilityLabel="Previous tab" onPress={() => onRow({ ...row, id: `${row.id}:-1` }, -1)}>
              <Text style={[styles.arrow, { color: tint }]}>◀︎</Text>
            </Pressable>
            <Pressable hitSlop={8} accessibilityRole="button" accessibilityLabel="Next tab" onPress={() => onRow({ ...row, id: `${row.id}:1` }, 1)}>
              <Text style={[styles.arrow, { color: tint }]}>▶︎</Text>
            </Pressable>
          </View>
        );
      default:
        return null;
    }
  };

  return (
    <SectionList
      style={{ backgroundColor: colors.background }}
      contentContainerStyle={styles.content}
      sections={sections}
      keyExtractor={(row) => row.id}
      stickySectionHeadersEnabled={false}
      ListHeaderComponent={header ? <>{header}</> : undefined}
      renderSectionHeader={({ section }) => <Text style={[styles.header, { color: colors.secondaryLabel }]}>{section.title}</Text>}
      renderItem={({ item, index, section }) => {
        const first = index === 0;
        const last = index === section.data.length - 1;
        // Accessibility: one element per row, its title and subtitle (and its badge); a switch row is the switch; rows
        // with their own buttons (arrows, "Tap me") let those buttons be reached. 无障碍：每行一个元素（标题、副标题与角标）；开关行即开关；
        // 带按钮的行（箭头、「Tap me」）让这些按钮可被访问。
        const isSwitch = item.accessory === 'switch';
        const grouped = item.accessory !== 'arrows' && !item.button;
        const label = [fill(item.title, values), item.badge ? badgeSubtitle : fill(item.subtitle, values), item.badge ? badgeAccessibilityText(item.badge.value) : '']
          .filter(Boolean)
          .join(', ');
        return (
          <Pressable
            accessible={grouped}
            accessibilityRole={isSwitch ? 'switch' : 'button'}
            accessibilityLabel={grouped ? label : undefined}
            accessibilityState={rowAccessibilityState(item, isSwitch, switches, currentSkin)}
            onPress={() => (isSwitch ? onSwitch(item, !switches[item.id]) : onRow(item, index))}
            style={({ pressed }) => [
              styles.row,
              { backgroundColor: pressed ? colors.separator : colors.card },
              first && styles.firstRow,
              last && styles.lastRow,
            ]}
          >
            {icon(item)}
            <View style={styles.texts}>
              <Text style={[styles.title, { color: item.link ? tint : colors.label }]}>{fill(item.title, values)}</Text>
              {item.subtitle ? (
                <Text style={[styles.subtitle, { color: colors.secondaryLabel }]} ellipsizeMode={item.badge ? 'middle' : 'tail'}>
                  {fill(item.subtitle, values)}
                </Text>
              ) : null}
              {item.button ? (
                <View style={[styles.outsideBox, { backgroundColor: colors.separator }]}>
                  <Pressable
                    accessibilityRole="button"
                    accessibilityLabel={item.button}
                    onPress={() => onRow({ ...item, id: `${item.id}:button` }, index)}
                    style={[styles.button, { backgroundColor: tint }]}
                  >
                    <Text style={styles.buttonTitle}>{item.button}</Text>
                  </Pressable>
                </View>
              ) : null}
            </View>
            {accessory(item)}
            {!last ? <View style={[styles.separator, { backgroundColor: colors.separator }]} /> : null}
          </Pressable>
        );
      }}
    />
  );
}

const styles = StyleSheet.create({
  content: { paddingHorizontal: 16, paddingBottom: 120 },
  header: { fontSize: 17, fontWeight: '600', marginTop: 28, marginBottom: 10, marginLeft: 4 },
  row: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 16, paddingVertical: 11, minHeight: 52 },
  firstRow: { borderTopLeftRadius: 26, borderTopRightRadius: 26 },
  lastRow: { borderBottomLeftRadius: 26, borderBottomRightRadius: 26 },
  icon: { width: 24, height: 24, marginRight: 16 },
  iconBox: { width: 30, height: 30, marginRight: 16 },
  bundleIcon: { width: 30, height: 30 },
  swatch: { width: 24, height: 24, borderRadius: 12, marginRight: 16, alignItems: 'center', justifyContent: 'center' },
  swatchGlyph: { color: '#FFFFFF', fontSize: 13, fontWeight: '700' },
  texts: { flex: 1 },
  title: { fontSize: 17, fontWeight: '500' },
  subtitle: { fontSize: 13, marginTop: 2 },
  chevron: { width: 9, height: 14, marginLeft: 8 },
  check: { fontSize: 17, fontWeight: '600', marginLeft: 8 },
  arrows: { flexDirection: 'row', gap: 16, marginLeft: 8 },
  arrow: { fontSize: 17 },
  outsideBox: { marginTop: 8, padding: 6, alignSelf: 'flex-start', borderRadius: 6 },
  button: { paddingHorizontal: 14, paddingVertical: 6, borderRadius: 8 },
  buttonTitle: { color: '#FFFFFF', fontSize: 15 },
  separator: { position: 'absolute', left: 56, right: 0, bottom: 0, height: StyleSheet.hairlineWidth },
});
