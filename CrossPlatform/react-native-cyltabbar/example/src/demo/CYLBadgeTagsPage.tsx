// [EN] docs/Animated-Item-Badge-CrossPlatform.md, step R5: badges on tags whose icon is a CYLAnimationView (the native
//      CYLAnimatedItemView). A tag only passes badgeValue and badgeAttributes; no React Native view is stacked on the icon.
//      reservesBadgeSpace keeps the badge inside the native view's bounds.
// [CN] docs/Animated-Item-Badge-CrossPlatform.md，步骤 R5：图标为 CYLAnimationView（原生 CYLAnimatedItemView）的 Tag 上的角标。
//      Tag 只传 badgeValue 与 badgeAttributes；图标上不叠加任何 React Native 视图。reservesBadgeSpace 让角标留在原生视图范围内。
import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, useColorScheme, View } from 'react-native';
import { CYLAnimationView, CYLBadgeAttributeKey } from 'react-native-cyltabbar';

// [EN] (value, animation, respects Reduce Motion), as the first nine badge samples; repeat counts have no attribute key.
// [CN] （值、动画、是否遵循减弱动态效果），对应前九个角标示例；重复次数没有对应的属性键。
const SAMPLES: ReadonlyArray<readonly [string, string, boolean]> = [
  ['3', 'Scale', false],
  ['3', 'Shake', false],
  ['3', 'Bounce', false],
  ['', 'Breathe', false],
  ['3', 'Shake', true],
  ['new', 'RollingOnce', false],
  ['3', 'ScaleOnce', false],
  ['8', 'None', false],
  ['100', 'None', false],
];

type Colors = Readonly<{ background: string; label: string; card: string; tint: string }>;

export function CYLBadgeTagsPage({ colors, onClose }: Readonly<{ colors: Colors; onClose: () => void }>) {
  const [shows, setShows] = useState(true);
  const dark = useColorScheme() === 'dark';
  const glass = { backgroundColor: dark ? '#FFFFFF1F' : '#FFFFFF99' };
  // [EN] Right-to-left on this page only (AC8). [CN] 仅本页从右到左（AC8）。
  const [rightToLeft, setRightToLeft] = useState(false);
  const button = (title: string, onPress: () => void) => (
    <Pressable accessibilityRole="button" onPress={onPress} style={[styles.button, { backgroundColor: colors.card }]}>
      <Text style={{ color: colors.tint }}>{title}</Text>
    </Pressable>
  );
  const tag = (title: string, value: string | null, attributes?: Record<string, string | boolean>) => (
    <View key={title} style={[styles.tag, glass]}>
      {/* [EN] Wide enough for "99+". [CN] 足够容纳 "99+"。 */}
      <CYLAnimationView
        style={styles.icon}
        file=""
        image="cyl_still_check.png"
        iconSize={30}
        reservesBadgeSpace
        badgeValue={value}
        badgeAttributes={attributes}
      />
      <Text style={[styles.title, { color: colors.label }]}>{title}</Text>
    </View>
  );
  return (
    // [EN] The gradient plate of the example's tag lists. [CN] 示例 TagList 的渐变背景板。
    <View style={[styles.page, { backgroundColor: colors.background, experimental_backgroundImage: dark ? DARK_PLATE : LIGHT_PLATE }]}>
      {/* [EN] The key rebuilds the native views when the direction changes. [CN] 方向改变时 key 重建原生视图。 */}
      <ScrollView key={String(rightToLeft)} style={{ direction: rightToLeft ? 'rtl' : 'ltr' }} contentContainerStyle={styles.content}>
        <View style={styles.bar}>
          {button('‹ Back', onClose)}
          {button(shows ? 'badgeValue = null' : 'badgeValue', () => setShows((current) => !current))}
          {button('RTL', () => setRightToLeft((current) => !current))}
        </View>
        <Text style={[styles.header, { color: colors.label }]}>Badges</Text>
        {/* [EN] The tags flow and wrap in a section card, as in a tag list. [CN] 标签像 TagList 一样在分组卡片中流式换行。 */}
        <View style={[styles.card, glass]}>
          {SAMPLES.map(([value, animation, reduce], index) =>
            tag(`${index + 1}. ${animation}${reduce ? ', Reduce Motion' : ''}`, shows ? value : null, {
              [CYLBadgeAttributeKey.animation]: animation,
              [CYLBadgeAttributeKey.respectsReduceMotion]: reduce,
            })
          )}
          {tag('badgeValue = null', null)}
        </View>
      </ScrollView>
    </View>
  );
}

const LIGHT_PLATE = 'linear-gradient(135deg, #FFB199, #7EC8E3, #C3AED6)';
const DARK_PLATE = 'linear-gradient(135deg, #5B2A3C, #1F4A63, #3B2D5C)';

const styles = StyleSheet.create({
  page: { position: 'absolute', top: 0, left: 0, right: 0, bottom: 0 },
  content: { padding: 16 },
  bar: { flexDirection: 'row', gap: 8, marginBottom: 6 },
  button: { paddingHorizontal: 14, paddingVertical: 10, borderRadius: 18 },
  header: { fontSize: 17, fontWeight: 'bold', marginStart: 16, marginTop: 8, marginBottom: 8 },
  card: { flexDirection: 'row', flexWrap: 'wrap', gap: 10, padding: 14, borderRadius: 20, borderWidth: 0.5, borderColor: '#FFFFFF40' },
  // [EN] A capsule as wide as its content. [CN] 宽度随内容的胶囊。
  tag: { flexDirection: 'row', alignItems: 'center', paddingStart: 4, paddingEnd: 16, borderRadius: 999, borderWidth: 1, borderColor: '#FFFFFF66' },
  icon: { width: 64, height: 52 },
  title: { marginStart: 4, fontSize: 15 },
});
