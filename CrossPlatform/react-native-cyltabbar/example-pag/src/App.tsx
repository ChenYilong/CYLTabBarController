/**
 * The React Native twin of Example-PAG (HealthyHome): the same tab bar, built from a configuration through
 * <CYLTabBar>, and the same pages drawn by React Native.
 * Example-PAG（HealthyHome）的 React Native 版本：同样的 TabBar（通过 <CYLTabBar> 由配置创建），以及由 React Native 绘制的同样页面。
 *
 * - Tabs: the images of Example-PAG's asset catalog and the PAG files of Example-Shared/PAGResources/tab-icons, added to
 *   the iOS app (ios/) and to the Android assets (android/app/build.gradle), named as in TabBarCommon.swift.
 * - Plus button: "Menu" drawn on tabbar_database, its own page (CYLPlusButtonSubclass.swift), a badge that shows 1 after
 *   launch and grows with each tap (Example-Shared/CYLPlusButtonBadgeDemo.swift).
 * - Interactions: bounce on tap, swipe to switch, a long press alert (demoSetUpInteractions()).
 */
import { useEffect, useMemo, useState, type ReactNode } from 'react';
import { Alert, Image, NativeModules, Platform, Pressable, ScrollView, StyleSheet, Switch, Text, View } from 'react-native';
import { useSafeAreaInsetsTop } from './safeArea';
import { CYLTabBar, type CYLTabBarItem } from 'react-native-cyltabbar';

// MARK: - Texts (CYLTabBarController.bundle's translations of the native demo) 文本（原生 Demo 在 CYLTabBarController.bundle 中的翻译）

const locale: string =
  (Platform.OS === 'ios'
    ? NativeModules.SettingsManager?.settings?.AppleLocale ?? NativeModules.SettingsManager?.settings?.AppleLanguages?.[0]
    : NativeModules.I18nManager?.localeIdentifier) ?? 'en';
const chinese = locale.startsWith('zh');
const T = {
  home: chinese ? '首页' : 'Home',
  health: chinese ? '健康' : 'Health',
  moments: chinese ? '朋友圈' : 'Moments',
  me: chinese ? '我的' : 'Me',
  menu: chinese ? '菜单' : 'Menu',
  contacts: chinese ? '通讯录' : 'Contacts',
  longPressed: (name: string) => (chinese ? `长按了「${name}」` : `Long-pressed "${name}"`),
  cancel: chinese ? '取消' : 'Cancel',
};

const BLUE = '#3A57ED';
const BACKGROUND_IMAGE = 'https://fc3tn.baidu.com/it/u=3025909226,1763324618&fm=202&src=bqdata';

// MARK: - The tab bar (TabBarCommon.swift, RootTabBarController.swift, CYLPlusButtonSubclass.swift)

const STYLES = ['default', 'flatDesign'] as const;

function tabItems(): CYLTabBarItem[] {
  const tab = (title: string, identifier: string, image: string, animation: string): CYLTabBarItem => ({
    title,
    identifier,
    image,
    selectedImage: `${image}Selected`,
    CYLTabBarAnimationFilePath: animation,
    CYLTabBarAnimationSize: '{33, 33}',
    // customizeInterface(): light gray titles, blue when selected. 浅灰色标题，选中时为蓝色。
    CYLTabBarItemTitleColor: '#AAAAAA',
    CYLTabBarItemSelectedTitleColor: BLUE,
  });
  return [
    tab(T.home, 'home', 'Home', 'tab_home.pag'),
    { ...tab(T.health, 'health', 'Message', 'tab_health.pag'), CYLTabBarItemDarkImage: 'Message_night' },
    tab(T.moments, 'moments', 'lianxiren', 'tab_moments.pag'),
    tab(T.me, 'me', 'Me', 'tab_me.pag'),
  ];
}

/** customizeInterface(): a white bar without its top line. 白色 TabBar，去掉顶部分割线。 */
const THEMES = {
  CYLTabBarControllerThemes: {
    default: {
      CYLTabBarBackgroundColor: '#FFFFFF',
      CYLTabBarShadowColor: '#00000000',
    },
  },
};

// MARK: - Pages (UI/*) 页面

type Page = { title: string; render: (push: (page: Page) => void) => ReactNode; right?: { label: string; page: Page } };

function ColorPage({ color }: { color: string }) {
  return <View style={[styles.fill, { backgroundColor: color }]} />;
}

const nextPage: Page = { title: '', render: () => <View style={styles.fillWhite} /> };
const childPage: Page = {
  title: '',
  right: { label: 'next', page: nextPage },
  render: () => <Image source={{ uri: BACKGROUND_IMAGE }} style={styles.fill} resizeMode="cover" />,
};

function MePage({ styleIndex, onStyle, badges, onBadges }: { styleIndex: number; onStyle: () => void; badges: boolean; onBadges: (on: boolean) => void }) {
  return (
    <ScrollView style={styles.fillWhite} contentContainerStyle={styles.list}>
      <Text style={styles.sectionTitle}>{chinese ? 'TabBar 外观' : 'Tab bar appearance'}</Text>
      <View style={styles.card}>
        <Pressable style={styles.row} onPress={onStyle}>
          <Text style={styles.rowTitle}>{chinese ? '样式' : 'Style'}</Text>
          <Text style={styles.rowDetail}>{STYLES[styleIndex] === 'flatDesign' ? 'FlatDesign' : 'Liquid Glass / Classic'}</Text>
        </Pressable>
        <View style={styles.separator} />
        <View style={styles.row}>
          <Text style={styles.rowTitle}>{chinese ? 'Tab 角标' : 'Tab badges'}</Text>
          <Switch value={badges} onValueChange={onBadges} />
        </View>
      </View>
    </ScrollView>
  );
}

// MARK: - Navigation (RootNavigationController: a blue bar, white title and buttons) 导航（蓝色导航栏，白色标题与按钮）

function Stack({ root }: { root: Page }) {
  const [stack, setStack] = useState<Page[]>([root]);
  useEffect(() => setStack([root]), [root]);
  const top = stack[stack.length - 1]!;
  const insetTop = useSafeAreaInsetsTop();
  const push = (page: Page) => setStack((current) => [...current, page]);
  return (
    <View style={styles.fill}>
      <View style={[styles.navigationBar, { paddingTop: insetTop }]}>
        <View style={styles.navigationContent}>
          {stack.length > 1 ? (
            <Pressable style={styles.navigationButton} onPress={() => setStack((current) => current.slice(0, -1))}>
              <Text style={styles.navigationButtonText}>‹</Text>
            </Pressable>
          ) : (
            <View style={styles.navigationButton} />
          )}
          <Text style={styles.navigationTitle}>{top.title}</Text>
          {top.right ? (
            <Pressable style={styles.navigationButton} onPress={() => push(top.right!.page)}>
              <Text style={styles.navigationButtonLabel}>{top.right.label}</Text>
            </Pressable>
          ) : (
            <View style={styles.navigationButton} />
          )}
        </View>
      </View>
      <View style={styles.fill}>{top.render(push)}</View>
    </View>
  );
}

// MARK: - The app

export default function App() {
  const [selected, setSelected] = useState<number | 'plus'>(0);
  const [styleIndex, setStyleIndex] = useState(0);
  const [plusBadge, setPlusBadge] = useState(0);
  const [tabBadges, setTabBadges] = useState(false);
  const items = useMemo(tabItems, []);

  // demoShowPlusButtonBadgeAfterLayout(): 1 after launch. 启动后显示 1。
  useEffect(() => {
    const timer = setTimeout(() => setPlusBadge((count) => Math.max(count, 1)), 1500);
    return () => clearTimeout(timer);
  }, []);

  const pages: Page[] = useMemo(
    () => [
      { title: T.home, right: { label: '⤢', page: childPage }, render: () => <ColorPage color="red" /> },
      { title: T.health, render: () => <ColorPage color="blue" /> },
      { title: T.contacts, render: () => <ColorPage color="purple" /> },
      {
        title: T.me,
        render: () => (
          <MePage
            styleIndex={styleIndex}
            onStyle={() => setStyleIndex((index) => (index + 1) % STYLES.length)}
            badges={tabBadges}
            onBadges={setTabBadges}
          />
        ),
      },
    ],
    [styleIndex, tabBadges]
  );
  const menuPage: Page = useMemo(() => ({ title: T.menu, render: () => <ColorPage color="orange" /> }), []);
  const page = selected === 'plus' ? menuPage : pages[selected]!;

  return (
    <View style={styles.fillWhite}>
      <Stack root={page} />
      <CYLTabBar
        style={styles.tabBar}
        items={items}
        styleType={STYLES[styleIndex]}
        animationSpeed={1.5}
        tapAnimation="bounce"
        swipeToSwitchTab
        configuration={THEMES}
        plusButton={{
          backgroundImage: 'tabbar_database',
          title: T.menu,
          titleColor: '#FFFFFF',
          titleFont: 15,
          keepsTitleVisible: true,
          index: 2,
          centerYMultiplier: 0.3,
          centerYOffset: -30,
          identifier: 'plus',
          pageIdentifier: 'menu',
        }}
        selectedIndex={selected === 'plus' ? -1 : selected}
        badgeValues={tabBadges ? ['', 'dot', '3', ''] : []}
        plusButtonBadgeValue={plusBadge > 0 ? String(plusBadge) : ''}
        badgeAnimation="bounce"
        onTabSelect={(index) => setSelected(index < 0 ? 'plus' : index)}
        onPlusButtonPress={() => setPlusBadge((count) => count + 1)}
        onTabLongPress={(_, __, title) => Alert.alert(T.longPressed(title), undefined, [{ text: T.cancel, style: 'cancel' }])}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  fillWhite: { flex: 1, backgroundColor: '#FFFFFF' },
  tabBar: { position: 'absolute', left: 0, right: 0, bottom: 0 },
  navigationBar: { backgroundColor: BLUE },
  navigationContent: { height: 44, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  navigationTitle: { color: '#FFFFFF', fontSize: 17, fontWeight: '600' },
  navigationButton: { width: 64, alignItems: 'center', justifyContent: 'center' },
  navigationButtonText: { color: '#FFFFFF', fontSize: 30, lineHeight: 32 },
  navigationButtonLabel: { color: '#FFFFFF', fontSize: 15 },
  list: { padding: 16, paddingBottom: 140 },
  sectionTitle: { fontSize: 15, fontWeight: '600', color: '#3C3C43', marginBottom: 8, marginTop: 8 },
  card: { borderRadius: 14, backgroundColor: '#F2F2F7', overflow: 'hidden' },
  row: { minHeight: 52, paddingHorizontal: 16, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  rowTitle: { fontSize: 16, color: '#000000' },
  rowDetail: { fontSize: 14, color: '#8E8E93' },
  separator: { height: StyleSheet.hairlineWidth, backgroundColor: '#C6C6C8', marginLeft: 16 },
});
