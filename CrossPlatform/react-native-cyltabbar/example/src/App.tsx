/**
 * The React Native twin of the Objective-C example (Example/, MainTabBarController.m), tracked item by item in
 * docs/ObjC-Example-Parity/README.md. The same tab bar, built from a configuration: four Lottie tabs, the "Post" plus
 * button with its own page, the badges and the cover of the first tab 1.5 s after launch; the pages follow the system's
 * dark / light mode.
 * Objective-C 示例（Example/，MainTabBarController.m）的 React Native 版本，逐项复刻进度见 docs/ObjC-Example-Parity/README.md。
 * 同样的 TabBar（由配置创建）：四个 Lottie Tab、带自己页面的「发布」PlusButton、启动 1.5 秒后的角标与第一个 Tab 的封面；页面跟随系统深色 / 浅色模式。
 */
import { useEffect, useRef, useState, type ReactNode } from 'react';
import { Alert, Animated, Image, Modal, Platform, Pressable, ScrollView, StatusBar, StyleSheet, Text, View, useColorScheme } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { CYLTabBar, type CYLTabBarBadge, type CYLTabBarItem, type CYLTabBarPlusButton } from 'react-native-cyltabbar';
import { SKINS, THEME_ICONS, type CYLSkin } from './CYLSkins';
import { CYLDemoList, type CYLDemoRow } from './demo/CYLDemoList';

/** A required image's URL, for the keys the component passes as they are. 被原样传递的键使用 require 图片的 URL。 */
const uri = (image: number) => Image.resolveAssetSource(image)?.uri ?? '';

/** The Lottie files of MainTabBarController.m, light and dark. MainTabBarController.m 的 Lottie 文件（浅色与深色）。 */
const lottie = (name: string) => ({
  CYLTabBarLottieFilePath: `green_lottie_tab_${name}.json`,
  CYLTabBarLottieDarkFilePath: `green_lottie_tab_${name}_dark.json`,
});

// +[MainTabBarController tabBarItemsAttributesForTabBar]
const ITEMS: CYLTabBarItem[] = [
  {
    title: 'Home',
    CYLTabBarItemSelectedTitle: 'Refresh',
    identifier: 'home',
    image: require('./assets/home_normal.png'),
    selectedImage: require('./assets/home_highlight.png'),
    ...lottie('home'),
  },
  {
    title: 'Nearby',
    identifier: 'city',
    image: require('./assets/fishpond_normal.png'),
    selectedImage: require('./assets/fishpond_highlight.png'),
    ...lottie('discover'),
    CYLTabBarAnimationColors: { 'Icon_Discovery_Normal.**.Color': '#7F7F7F' },
  },
  {
    title: 'Messages',
    identifier: 'message',
    image: require('./assets/message_normal.png'),
    CYLTabBarItemDarkImage: uri(require('./assets/message_normal_night.png')),
    selectedImage: require('./assets/message_highlight.png'),
    ...lottie('news'),
  },
  {
    title: 'Me',
    // No identifier in Objective-C: the class name is the default (#408). Objective-C 未设置：默认为类名（#408）。
    identifier: 'CYLMineViewController',
    image: require('./assets/account_normal.png'),
    selectedImage: require('./assets/account_highlight.png'),
    ...lottie('mine'),
  },
];

/** A random color, as `UIColor.cyl_randomColor`. 随机颜色，与 `UIColor.cyl_randomColor` 相同。 */
const randomColor = () =>
  `#${Math.floor(Math.random() * 0xffffff)
    .toString(16)
    .padStart(6, '0')}`;

// -[MainTabBarController cyl_demo_decorateTabBarController:], 1.5 s after launch: the first tab's dot is cleared at once
// by its cover (`-setSelectedCoverShow:`). 启动 1.5 秒后；第一个 Tab 的红点随即被其封面清除。
const launchBadges = (): CYLTabBarBadge[] => [
  { value: '', color: randomColor(), radius: 5.5, animation: 'breathe' },
  { value: '8', color: '#AF52DE', animation: 'scale' },
  { value: '100', animation: 'bounce' },
  { value: 'NEW', animation: 'breathe', centerOffset: [-1, 3] },
];

type CYLStyleType = 'liquidGlass' | 'flatDesign';

/**
 * -[CYLMainRootViewController createFlatDesignTabBar] / -createNewTabBarWithContext: the navigation bar buttons replace the
 * tab bar controller with a new one, in FlatDesign or Liquid Glass: a new key builds a new tab bar, with its launch badges.
 * 导航栏按钮用新的 TabBarController（扁平样式或液态玻璃）替换旧的：新的 key 创建新的 TabBar 及其启动角标。
 */
export default function App() {
  const [styleType, setStyleType] = useState<CYLStyleType>('liquidGlass');
  const [generation, setGeneration] = useState(0);
  const rebuild = (next: CYLStyleType) => {
    setStyleType(next);
    setGeneration((current) => current + 1);
  };
  // The skin belongs to the app (CYLThemeManagerCenter.defaultThemeManager): it stays when the tab bar is replaced.
  // 皮肤属于整个 App（默认主题管理器）：替换 TabBar 时保持不变。
  const [skinName, setSkinName] = useState('Default');
  // Login (issue #19) belongs to the app, as `cyl_loggedIn`: it stays when the tab bar is replaced. Undefined until the tab
  // bar reports the state the library cached, so the login is kept across launches, as the Objective-C example.
  // 登录状态（issue #19）属于整个 App，与 `cyl_loggedIn` 相同：替换 TabBar 时保持不变。TabBar 报告库缓存的状态之前为 undefined，
  // 因此与 Objective-C 示例相同，重启 App 后登录状态保留。
  const [loggedIn, setLoggedIn] = useState<boolean | undefined>(undefined);
  const [followsSystem, setFollowsSystem] = useState(false);
  const dark = useColorScheme() === 'dark';
  // CYLDemoSetFollowsSystem: Dark in dark mode; in light mode back to Default from Dark, otherwise the skin chosen.
  // 跟随系统：深色时为 Dark；浅色时从 Dark 回到 Default，否则为所选皮肤。
  const effectiveName = followsSystem ? (dark ? 'Dark' : skinName === 'Dark' ? 'Default' : skinName) : skinName;
  const skin = SKINS.find((candidate) => candidate.name === effectiveName) ?? SKINS[0]!;
  const skinPicker = {
    skin,
    followsSystem,
    // CYLDemoApplyTheme: choosing a skin stops following the system. 选择皮肤时停止跟随系统。
    choose: (name: string) => {
      setFollowsSystem(false);
      setSkinName(name);
    },
    toggleFollowsSystem: () => setFollowsSystem((current) => !current),
  };
  return (
    <CYLMainTabBar key={generation} styleType={styleType} onRebuild={rebuild} skinPicker={skinPicker} loggedIn={loggedIn} onLoggedInChange={setLoggedIn} />
  );
}

type CYLSkinPicker = { skin: CYLSkin; followsSystem: boolean; choose: (name: string) => void; toggleFollowsSystem: () => void };

/** The tabs in a skin: holiday or network icons instead of the Lottie ones. 皮肤中的 Tab：用节日或网络图标替换 Lottie 图标。 */
function skinnedItems(skin: CYLSkin): CYLTabBarItem[] {
  return ITEMS.map((item, index) => {
    const base: CYLTabBarItem = { title: item.title, identifier: item.identifier, CYLTabBarItemSelectedTitle: item.CYLTabBarItemSelectedTitle };
    if (skin.icons) {
      const icon = THEME_ICONS[skin.icons[index % skin.icons.length]!]!;
      return { ...base, image: icon.faded, selectedImage: icon.image };
    }
    if (skin.network) {
      const [image, selectedImage] = skin.network.tabs[index % skin.network.tabs.length]!;
      return {
        ...base,
        title: `${skin.network.titlePrefix} ${item.title}`,
        image: item.image,
        CYLTabBarItemImageURL: image,
        CYLTabBarItemSelectedImageURL: selectedImage,
        CYLTabBarItemImageURLSize: [24, 24],
      };
    }
    return item;
  });
}

/** The plus button in a skin (`cyl_plusButtonAttributesForTabBarController:`). 皮肤中的 PlusButton。 */
function skinnedPlusButton(skin: CYLSkin): CYLTabBarPlusButton {
  if (skin.icons) {
    const icon = THEME_ICONS[skin.icons[skin.icons.length - 1]!]!.image;
    return { ...PLUS_BUTTON, image: icon, selectedImage: icon };
  }
  if (skin.network) {
    return { ...PLUS_BUTTON, image: skin.network.plusButton[0], selectedImage: skin.network.plusButton[1] };
  }
  return PLUS_BUTTON;
}

/** The bar's colors in a skin (`cyl_tabBarAppearanceForTabBarController:`). 皮肤中 TabBar 的颜色。 */
function skinnedConfiguration(skin: CYLSkin) {
  if (!skin.tint) return CONFIGURATION;
  const normal = skin.normal ?? '#8E8E93';
  return {
    ...CONFIGURATION,
    CYLTabBarControllerThemes: {
      [skin.name]: {
        ...(skin.bar ? { CYLTabBarBackgroundColor: skin.bar } : {}),
        CYLTabBarItemTitleColor: normal,
        CYLTabBarItemSelectedTitleColor: skin.tint,
        // Full color icons are drawn as they are (`UIImageRenderingModeAlwaysOriginal`). 全彩图标按原图绘制。
        ...(skin.icons || skin.network ? {} : { CYLTabBarItemIconColor: normal, CYLTabBarItemSelectedIconColor: skin.tint }),
        CYLTabBarItemTitleFont: 10,
      },
    },
  };
}

/** The skin picker (`-cyl_themeMenuWithCompletion:`): a swatch or the first icon, a check on the current one. 换肤菜单。 */
function CYLSkinMenu({ visible, picker, colors, onClose }: { visible: boolean; picker: CYLSkinPicker; colors: typeof LIGHT; onClose: () => void }) {
  const row = (key: string, icon: ReactNode, title: string, checked: boolean, onPress: () => void) => (
    <Pressable
      key={key}
      accessibilityRole="button"
      accessibilityLabel={title}
      accessibilityState={{ selected: checked }}
      style={styles.menuRow}
      onPress={() => {
        onPress();
        onClose();
      }}
    >
      <Text style={[styles.menuCheck, { color: colors.label }]}>{checked ? '✓' : ''}</Text>
      {icon}
      <Text style={[styles.menuTitle, { color: colors.label }]}>{title}</Text>
    </Pressable>
  );
  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <Pressable style={styles.menuBackdrop} onPress={onClose} accessibilityLabel="Close the theme menu" accessibilityRole="button">
        {/* The menu takes the touches inside it, so a tap after a scroll reaches its row, not the backdrop that closes it.
            菜单接收其内部的触摸，滚动后的点击会到达对应行，而不是关闭菜单的背景。 */}
        <View style={[styles.menu, { backgroundColor: colors.menu }]} onStartShouldSetResponder={() => true}>
          <Text style={styles.menuHeader}>Choose a theme</Text>
          <ScrollView>
            {SKINS.map((skin) => {
              const firstIcon = skin.icons ? THEME_ICONS[skin.icons[0]!]!.image : undefined;
              const icon = firstIcon ? (
                <Image source={firstIcon as number} style={styles.menuIcon} />
              ) : (
                <View style={[styles.menuIcon, styles.menuSwatch, { backgroundColor: skin.tint ?? '#C7C7CC' }]}>
                  {skin.network ? <Text style={styles.menuSwatchGlyph}>↓</Text> : null}
                </View>
              );
              return row(skin.name, icon, skin.name, !picker.followsSystem && skin.name === picker.skin.name, () => picker.choose(skin.name));
            })}
            {row('system', <Text style={[styles.menuIcon, styles.menuGlyph, { color: colors.label }]}>◐</Text>, 'Follow the system Dark Mode', picker.followsSystem, picker.toggleFollowsSystem)}
          </ScrollView>
        </View>
      </Pressable>
    </Modal>
  );
}

/** A dot badge on a navigation bar button (`-cyl_showBadgeValue:animationType:backgroundColor:`). 导航栏按钮上的红点角标。 */
function CYLNavigationBadge({ color, animation }: { color: string; animation: 'breathe' | 'shake' }) {
  const progress = useRef(new Animated.Value(0)).current;
  useEffect(() => {
    const loop = Animated.loop(
      Animated.sequence([
        Animated.timing(progress, { toValue: 1, duration: animation === 'breathe' ? 900 : 120, useNativeDriver: true }),
        Animated.timing(progress, { toValue: animation === 'breathe' ? 0 : -1, duration: animation === 'breathe' ? 900 : 120, useNativeDriver: true }),
        Animated.timing(progress, { toValue: 0, duration: animation === 'breathe' ? 0 : 120, useNativeDriver: true }),
        Animated.delay(animation === 'breathe' ? 0 : 1200),
      ])
    );
    loop.start();
    return () => loop.stop();
  }, [animation, progress]);
  const transform =
    animation === 'breathe'
      ? { opacity: progress.interpolate({ inputRange: [0, 1], outputRange: [1, 0.3] }) }
      : { transform: [{ translateX: progress.interpolate({ inputRange: [-1, 1], outputRange: [-3, 3] }) }] };
  // A decoration of the button: hidden from accessibility. 按钮的装饰：对无障碍隐藏。
  return (
    <Animated.View
      accessibilityElementsHidden
      importantForAccessibility="no-hide-descendants"
      style={[styles.navigationBadge, { backgroundColor: color }, transform]}
    />
  );
}

/** A Liquid Glass bar button. 液态玻璃导航栏按钮。 */
function CYLNavigationButton(props: { title: string; colors: typeof LIGHT; onPress: () => void; badge?: ReactNode }) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={props.title}
      onPress={props.onPress}
      style={[styles.navigationButton, { backgroundColor: props.colors.barButton }]}
    >
      <Text style={[styles.navigationButtonTitle, { color: props.colors.label }]}>{props.title}</Text>
      {props.badge}
    </Pressable>
  );
}

function CYLMainTabBar({
  styleType,
  onRebuild,
  skinPicker,
  loggedIn,
  onLoggedInChange,
}: {
  styleType: CYLStyleType;
  onRebuild: (styleType: CYLStyleType) => void;
  skinPicker: CYLSkinPicker;
  loggedIn: boolean | undefined;
  onLoggedInChange: (loggedIn: boolean) => void;
}) {
  const dark = useColorScheme() === 'dark';
  const colors = dark ? DARK : LIGHT;
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [plusPageSelected, setPlusPageSelected] = useState(false);
  const [decorated, setDecorated] = useState(false);
  const [coverShown, setCoverShown] = useState(true);
  const [badgeStyles, setBadgeStyles] = useState<(CYLTabBarBadge | null)[]>([]);

  useEffect(() => {
    const timer = setTimeout(() => {
      setDecorated(true);
      setBadgeStyles(launchBadges());
    }, 1500);
    return () => clearTimeout(timer);
  }, []);

  // -[MainTabBarController tabBarController:didSelectControl:]: the tab button itself shows no badge on Liquid Glass (the
  // badge is on its image view), so a tap that selects a tab turns its badge into a dot, in the badge's color.
  // 液态玻璃下 Tab 按钮本身没有角标（角标在其图片视图上），因此选中 Tab 的点击会把其角标变为红点，保留角标颜色。
  const markBadge = (index: number) =>
    setBadgeStyles((current) => {
      const next = [...current];
      next[index] = { value: 'dot', color: current[index]?.color };
      return next;
    });
  const title = plusPageSelected ? 'PlusChildViewController' : ITEMS[selectedIndex]!.title;
  // -[CYLHomeViewController viewDidLoad]: dots in random colors on the "Flat Design" and "Liquid Glass" buttons.
  // 「Flat Design」与「Liquid Glass」按钮上的随机颜色红点。
  const [navigationBadgeColors] = useState(() => [randomColor(), randomColor()]);
  const [skinMenuVisible, setSkinMenuVisible] = useState(false);
  // As the Objective-C example, the cover goes on after the tab icons: a skin's icons replace the tab's icon views, so
  // the cover is put back once they are in (network icons are downloaded first). 与 Objective-C 示例相同，封面在 Tab 图标之后添加：
  // 皮肤的图标会替换 Tab 的图标视图，因此在其就绪后重新添加封面（网络图标需要先下载）。
  const skinName = skinPicker.skin.name;
  const firstSkin = useRef(true);
  useEffect(() => {
    if (firstSkin.current) {
      firstSkin.current = false;
      return;
    }
    setCoverShown(false);
    const timer = setTimeout(() => setCoverShown(true), skinPicker.skin.network ? 4000 : 1500);
    return () => clearTimeout(timer);
  }, [skinName, skinPicker.skin.network]);
  const [orangePagePushed, setOrangePagePushed] = useState(false);
  // MainTabBarController: the first page's title gets " (Liquid)" on Liquid Glass. 液态玻璃下第一个页面的标题加上「 (Liquid)」。
  // The badge samples' subtitle uses the page's `title`; a badge row changes only `navigationItem.title` ("Home (n)").
  // 角标样例副标题使用页面的 `title`；点击角标行只修改 `navigationItem.title`（「Home (n)」）。
  const pageTitle = selectedIndex === 0 ? `Home${styleType === 'liquidGlass' ? ' (Liquid)' : ''}` : (ITEMS[selectedIndex]!.title as string);
  const { skin } = skinPicker;
  // FlatDesign: a skin's tint colors the badges without a color of their own (`badgeBackgroundColor` of the appearance);
  // Liquid Glass keeps them red. 扁平样式：皮肤的 tint 为没有自定颜色的角标着色（appearance 的 `badgeBackgroundColor`）；液态玻璃下仍为红色。
  const tintsBadges = styleType === 'flatDesign' && skin.tint;
  const skinnedBadges = badgeStyles.map((badge) => (badge && !badge.color && tintsBadges ? { ...badge, color: skin.tint } : badge));

  const insetTop = useSafeAreaInsets().top;

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      {/* The page avoids the status bar; the tab bar handles the bottom safe area itself, so the page reaches the bottom
          edge and scrolls under the bar, as in the Objective-C example. Only the top inset pads the page (the bar must not
          go up by the home indicator's inset), on both platforms (Android draws under the status bar).
          页面避开状态栏；TabBar 自己处理底部安全区，因此页面延伸到底部并在 TabBar 下方滚动，与 Objective-C 示例相同。页面只使用顶部安全区
          边距（TabBar 不能上移 Home 指示条的高度），两个平台相同（Android 绘制到状态栏下方）。 */}
      <View style={[styles.container, { paddingTop: insetTop }]}>
      <StatusBar barStyle={dark ? 'light-content' : 'dark-content'} />
      {/* CYLHomeViewController's navigation bar: "Flat Design" on the left, "Skin" and "Liquid Glass" on the right.
          首页导航栏：左侧「Flat Design」，右侧「Skin」与「Liquid Glass」。 */}
      {!plusPageSelected && selectedIndex === 0 && (
        <View style={styles.navigationBar}>
          <CYLNavigationButton
            title="Flat Design"
            colors={colors}
            onPress={() => onRebuild('flatDesign')}
            badge={<CYLNavigationBadge color={navigationBadgeColors[0]!} animation="breathe" />}
          />
          <View style={styles.page} />
          <CYLNavigationButton title="Skin" colors={colors} onPress={() => setSkinMenuVisible(true)} />
          <CYLNavigationButton
            title="Liquid Glass"
            colors={colors}
            onPress={() => onRebuild('liquidGlass')}
            badge={<CYLNavigationBadge color={navigationBadgeColors[1]!} animation="shake" />}
          />
        </View>
      )}
      <CYLSkinMenu visible={skinMenuVisible} picker={skinPicker} colors={colors} onClose={() => setSkinMenuVisible(false)} />
      {/* The page: React Native draws it; the native component draws only the bar. Every tab shows the demo list
          (item 51); the plus button's page shows its title. 页面由 RN 绘制，组件只绘制 TabBar。每个 Tab 都显示演示列表（第 51 项）；
          PlusButton 的页面显示其标题。 */}
      {plusPageSelected ? (
        <View style={styles.page}>
          <Text style={[styles.title, { color: colors.label }]}>{title as string}</Text>
        </View>
      ) : (
        <CYLDemoList
          colors={colors}
          tint={skin.tint ?? colors.tint}
          values={{
            titleOffset: '(0, -3.5)',
            appearance: 'Original',
            skin: skin.name,
            scrollBehavior: 'Automatic',
            indexWithoutPlus: String(selectedIndex),
            selectedIndex: String(selectedIndex < 2 ? selectedIndex : selectedIndex + 1),
            selectedTitle: selectedIndex === 0 ? 'Refresh' : (ITEMS[selectedIndex]!.title as string),
            login: loggedIn === true ? 'logged in' : 'logged out',
            touchScale: '1.0x',
            tapAnimation: 'None',
            tapSound: 'None',
            longPress: '0.5',
            doubleTap: '0.35',
            adjacent: '-',
            outsideTaps: '0',
          }}
          switches={{ login: loggedIn === true }}
          currentSkin={skinPicker.followsSystem ? '' : skin.name}
          // The system version, as -[CYLHomeViewController configureCell:forIndexPath:] ("iOS 26.5", "Android 15").
          // 系统版本，与 ObjC 示例相同（「iOS 26.5」「Android 15」）。
          badgeSubtitle={`${pageTitle} CYLTabBarController on ${Platform.OS === 'ios' ? `iOS ${Platform.Version}` : `Android ${(Platform.constants as { Release?: string }).Release ?? Platform.Version}`}`}
          onRow={(row: CYLDemoRow) => {
            if (row.skin) return skinPicker.choose(row.skin.name);
            if (row.id === 'skin') return setSkinMenuVisible(true);
            if (row.badge) {
              // -[CYLHomeViewController tableView:didSelectRowAtIndexPath:]: an orange page (the "Home (n)" navigation title
              // is not shown: the home page's navigation bar shows only its buttons). 推入橙色页面（导航标题「Home (n)」不显示：
              // 首页导航栏只显示按钮）。
              setOrangePagePushed(true);
            }
          }}
          onSwitch={(row: CYLDemoRow, on: boolean) => {
            // The login state row (CYLLoginStateSwitch): on means logged in. 登录状态行：打开表示已登录。
            if (row.id === 'login') onLoggedInChange(on);
          }}
        />
      )}
      </View>
      <CYLTabBar
        style={styles.tabBar}
        items={skinnedItems(skin)}
        styleType={styleType}
        // -addScaleAnimationOnView:repeatCount: on every tap. 每次点击播放一次缩放动画。
        tapAnimation="scale"
        plusButton={skinnedPlusButton(skin)}
        configuration={skinnedConfiguration(skin)}
        selectedIndex={plusPageSelected ? -1 : selectedIndex}
        badgeStyles={skinnedBadges}
        plusButtonBadge={decorated ? { value: '1', animation: 'bounce' } : undefined}
        tabCoverImages={decorated && coverShown ? [require('./assets/home_select_cover.png')] : []}
        onTabSelect={(index) => {
          setPlusPageSelected(index < 0);
          if (index < 0) return;
          if (index !== selectedIndex || plusPageSelected) markBadge(index);
          setSelectedIndex(index);
        }}
        loggedIn={loggedIn}
        onLoginStateChange={onLoggedInChange}
        // -[MainTabBarController cyl_demo_presentLoginForViewController:completion:]: "Messages" and "Me" need login; the
        // alert logs in, then selects the tapped tab. 「Messages」「Me」需要登录；弹窗登录后选中所点击的 Tab。
        onLoginRequest={(index, _identifier, title) =>
          Alert.alert('Login required', `Log in to view “${title}”`, [
            { text: 'Cancel', style: 'cancel' },
            {
              text: 'Log in',
              onPress: () => {
                onLoggedInChange(true);
                setPlusPageSelected(false);
                markBadge(index);
                setSelectedIndex(index);
              },
            },
          ])
        }
      />
      {/* -[CYLHomeViewController pushToNewViewController]: a full screen orange page without a navigation bar, over the
          tab bar; tap to go back. 覆盖 TabBar 的全屏橙色页面，无导航栏；点击返回。 */}
      {orangePagePushed ? (
        <Pressable style={styles.orangePage} accessibilityRole="button" accessibilityLabel="Back" onPress={() => setOrangePagePushed(false)} />
      ) : null}
    </View>
  );
}

// CYLPlusButtonSubclass.m
const PLUS_BUTTON: CYLTabBarPlusButton = {
  title: 'Post',
  image: require('./assets/post_normal.png'),
  selectedImage: require('./assets/post_highlight.png'),
  selectedTitleColor: '#34C759',
  titleFont: 9.5,
  index: 2,
  size: [55, 80],
  // A skin's image is drawn in the plus image's frame, aspect fit (`-updatePlusButtonWithAttributes:`).
  // 皮肤图片在 PlusButton 原图片区域内等比绘制。
  imageSize: [55, 55],
  centerYOffset: -14,
  alignsTitle: true,
  // -tabBarController:shouldShowPlatterLiquidLensViewForControl: returns YES. 该代理方法返回 YES。
  showsSelection: true,
  identifier: 'plus',
  pageIdentifier: 'plus',
};

/**
 * The Objective-C example's title offset (0, -3.5), which the aligned plus button follows, and its tab bar appearance
 * (+demoStandardAppearanceWithTitlePositionAdjustment:): titles 10 pt, red unselected, green selected. The bar-wide
 * values are a skin's named values, which build the same `UITabBarAppearance` on iOS.
 * ObjC 示例的标题偏移（标题对齐的 PlusButton 随之移动）与 TabBar 外观：标题 10pt，未选中红色、选中绿色。整个 TabBar 的值写在皮肤的命名值中，
 * iOS 上生成同样的 `UITabBarAppearance`。
 */
const CONFIGURATION = {
  CYLTabBarControllerTitlePositionAdjustment: [0, -3.5],
  // -[MainTabBarController setUpLoginRequiredTabs] (issue #19). 需要登录的 Tab。
  CYLTabBarControllerLoginRequiredTabBarItemIdentifiers: ['message', 'CYLMineViewController'],
  CYLTabBarControllerThemes: {
    Default: {
      CYLTabBarItemTitleColor: '#FF0000',
      CYLTabBarItemIconColor: '#FF0000',
      CYLTabBarItemSelectedTitleColor: '#34C759',
      CYLTabBarItemSelectedIconColor: '#34C759',
      CYLTabBarItemTitleFont: 10,
    },
  },
};

/** UIColor.systemBackgroundColor / labelColor. */
/** UIColor.systemGroupedBackgroundColor / labelColor / secondaryLabelColor / secondarySystemGroupedBackgroundColor / separatorColor / systemBlueColor. */
const LIGHT = { background: '#F2F2F7', label: '#000000', secondaryLabel: '#3C3C4399', card: '#FFFFFF', separator: '#3C3C434A', tint: '#007AFF', barButton: '#FFFFFF', menu: '#F2F2F7' };
const DARK = { background: '#000000', label: '#FFFFFF', secondaryLabel: '#EBEBF599', card: '#1C1C1E', separator: '#54545899', tint: '#0A84FF', barButton: '#1C1C1E', menu: '#1C1C1E' };

const styles = StyleSheet.create({
  container: { flex: 1 },
  page: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  title: { fontSize: 17, fontWeight: '600' },
  tabBar: { position: 'absolute', left: 0, right: 0, bottom: 0 },
  orangePage: { position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: '#FF8000' },
  navigationBar: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 20, paddingTop: 8, gap: 12 },
  navigationButton: { height: 36, paddingHorizontal: 14, borderRadius: 18, justifyContent: 'center' },
  navigationButtonTitle: { fontSize: 17 },
  navigationBadge: { position: 'absolute', top: -3, right: -3, width: 10, height: 10, borderRadius: 5 },
  menuBackdrop: { flex: 1, alignItems: 'flex-end', paddingTop: 100, paddingRight: 16 },
  menu: { width: 260, maxHeight: '75%', borderRadius: 24, paddingVertical: 12 },
  menuHeader: { color: '#8E8E93', fontSize: 15, paddingHorizontal: 20, paddingBottom: 8 },
  menuRow: { flexDirection: 'row', alignItems: 'center', minHeight: 44, paddingHorizontal: 12, paddingVertical: 4 },
  menuCheck: { width: 22, fontSize: 17 },
  menuIcon: { width: 26, height: 26, marginRight: 12 },
  menuSwatch: { borderRadius: 13, alignItems: 'center', justifyContent: 'center' },
  menuSwatchGlyph: { color: '#FFFFFF', fontSize: 15, fontWeight: '700' },
  menuGlyph: { fontSize: 20, textAlign: 'center' },
  menuTitle: { fontSize: 17, flexShrink: 1 },
});
