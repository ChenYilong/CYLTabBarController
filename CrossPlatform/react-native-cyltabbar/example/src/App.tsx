/**
 * The React Native twin of the Objective-C example (Example/, MainTabBarController.m), tracked item by item in
 * docs/ObjC-Example-Parity/README.md. The same tab bar, built from a configuration: four Lottie tabs, the "Post" plus
 * button with its own page, the badges and the cover of the first tab 1.5 s after launch; the pages follow the system's
 * dark / light mode.
 * Objective-C 示例（Example/，MainTabBarController.m）的 React Native 版本，逐项复刻进度见 docs/ObjC-Example-Parity/README.md。
 * 同样的 TabBar（由配置创建）：四个 Lottie Tab、带自己页面的「发布」PlusButton、启动 1.5 秒后的角标与第一个 Tab 的封面；页面跟随系统深色 / 浅色模式。
 */
import { useEffect, useRef, useState, type ReactNode } from 'react';
import { ActionSheetIOS, Alert, Animated, Image, Modal, Platform, Pressable, ScrollView, StatusBar, StyleSheet, Text, View, useColorScheme } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { CYLTabBar, type CYLTabBarBadge, type CYLTabBarItem, type CYLTabBarPlusButton } from 'react-native-cyltabbar';
import { SKINS, THEME_ICONS, type CYLSkin } from './CYLSkins';
import { CYLDemoList, type CYLDemoRow } from './demo/CYLDemoList';
import { CYL_PICKER_LANGUAGES, CYLDemoLanguage, CYLFlaggedLanguageName, CYLIsRightToLeft, CYLLanguageName, CYLSetDemoLanguage, t, tDevice } from './demo/CYLLocalization';

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
  // The language belongs to the app (CYLSetLocalizationLanguage()); undefined follows the device. Not saved, as the
  // Objective-C example: a new launch follows the device again. 语言属于整个 App；undefined 跟随设备。与 Objective-C 示例相同不保存：重新启动后再次跟随设备。
  const [language, setLanguage] = useState<string | undefined>(undefined);
  CYLSetDemoLanguage(language);
  const shownLanguage = CYLDemoLanguage();
  const dark = useColorScheme() === 'dark';
  const effectiveName = effectiveSkinName(skinName, followsSystem, dark);
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
  // -[UIWindow cyl_setRootViewControllerProvider:]: a new language builds everything again (a new key), so every text is
  // created in it; a right-to-left language (Arabic) flips the layout. 新的语言会重新创建全部内容（新的 key），所有文字都用新语言创建；
  // 从右到左的语言（阿拉伯语）翻转布局。
  return (
    <View key={shownLanguage} style={[styles.container, { direction: CYLIsRightToLeft(shownLanguage) ? 'rtl' : 'ltr' }]}>
      <CYLMainTabBar
        key={generation}
        styleType={styleType}
        onRebuild={rebuild}
        skinPicker={skinPicker}
        loggedIn={loggedIn}
        onLoggedInChange={setLoggedIn}
        language={language}
        onLanguageChange={setLanguage}
      />
    </View>
  );
}

/** CYLDemoTitleVerticalOffsets: the next offset after `current`; one not in the list goes to the first. 下一个偏移；不在列表中时为第一个。 */
const TITLE_VERTICAL_OFFSETS = [0, -4, 4];
function nextTitleOffset(current: number): number {
  const index = TITLE_VERTICAL_OFFSETS.findIndex((offset) => Math.abs(offset - current) < 0.5);
  return TITLE_VERTICAL_OFFSETS[index < 0 ? 0 : (index + 1) % TITLE_VERTICAL_OFFSETS.length]!;
}

/**
 * -[UIViewController cyl_presentLanguagePicker]: the five languages, "Follow system" and "Cancel"; iOS shows an action
 * sheet, Android a list (its alerts hold three buttons only). The choice calls `onChoose` (undefined: follow the device).
 * 五种语言、「跟随系统」与「取消」；iOS 显示操作表，Android 显示列表（其弹窗最多三个按钮）。选择后调用 `onChoose`（undefined：跟随设备）。
 */
function presentLanguagePicker(onChoose: (language: string | undefined) => void, showAndroidList: () => void) {
  if (Platform.OS !== 'ios') return showAndroidList();
  const options = [...CYL_PICKER_LANGUAGES.map(CYLFlaggedLanguageName), t('Follow system'), t('Cancel')];
  ActionSheetIOS.showActionSheetWithOptions(
    { title: t('Language'), message: tDevice('Tap to change the language'), options, cancelButtonIndex: options.length - 1 },
    (index) => {
      if (index < CYL_PICKER_LANGUAGES.length) onChoose(CYL_PICKER_LANGUAGES[index]);
      else if (index === CYL_PICKER_LANGUAGES.length) onChoose(undefined);
    }
  );
}

/** The Android language list, in the skin menu's style. Android 的语言列表，与换肤菜单样式相同。 */
function CYLLanguageMenu({ visible, colors, onChoose, onClose }: Readonly<{ visible: boolean; colors: typeof LIGHT; onChoose: (language: string | undefined) => void; onClose: () => void }>) {
  const row = (key: string, title: string, label: string, onPress: () => void) => (
    <Pressable
      key={key}
      accessibilityRole="button"
      accessibilityLabel={label}
      style={styles.menuRow}
      onPress={() => {
        onClose();
        onPress();
      }}
    >
      <Text style={[styles.menuTitle, styles.languageTitle, { color: colors.label }]}>{title}</Text>
    </Pressable>
  );
  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <Pressable style={[styles.menuBackdrop, styles.languageBackdrop]} onPress={onClose} accessibilityLabel={t('Cancel')} accessibilityRole="button">
        <View style={[styles.menu, { backgroundColor: colors.menu }]} onStartShouldSetResponder={() => true}>
          <Text style={styles.menuHeader}>{t('Language')}</Text>
          <Text style={[styles.menuHeader, styles.languageMessage]}>{tDevice('Tap to change the language')}</Text>
          {CYL_PICKER_LANGUAGES.map((language) => row(language, CYLFlaggedLanguageName(language), CYLLanguageName(language), () => onChoose(language)))}
          {row('system', t('Follow system'), t('Follow system'), () => onChoose(undefined))}
          {row('cancel', t('Cancel'), t('Cancel'), () => {})}
        </View>
      </Pressable>
    </Modal>
  );
}

type CYLSkinPicker = { skin: CYLSkin; followsSystem: boolean; choose: (name: string) => void; toggleFollowsSystem: () => void };

/** The tabs in a skin: holiday or network icons instead of the Lottie ones. 皮肤中的 Tab：用节日或网络图标替换 Lottie 图标。 */
function skinnedItems(skin: CYLSkin): CYLTabBarItem[] {
  return ITEMS.map((item, index) => {
    // The titles in the current language, as CYLLocalizedTabBarItemsAttributes(). 当前语言中的标题。
    const title = t(item.title as string);
    const selectedTitle = item.CYLTabBarItemSelectedTitle ? t(item.CYLTabBarItemSelectedTitle as string) : undefined;
    const base: CYLTabBarItem = { title, identifier: item.identifier, CYLTabBarItemSelectedTitle: selectedTitle };
    if (skin.icons) {
      const icon = THEME_ICONS[skin.icons[index % skin.icons.length]!]!;
      return { ...base, image: icon.faded, selectedImage: icon.image };
    }
    if (skin.network) {
      const [image, selectedImage] = skin.network.tabs[index % skin.network.tabs.length]!;
      return {
        ...base,
        title: `${skin.network.titlePrefix} ${title}`,
        image: item.image,
        CYLTabBarItemImageURL: image,
        CYLTabBarItemSelectedImageURL: selectedImage,
        CYLTabBarItemImageURLSize: [24, 24],
      };
    }
    return { ...item, title, CYLTabBarItemSelectedTitle: selectedTitle };
  });
}

/** The plus button in a skin (`cyl_plusButtonAttributesForTabBarController:`). 皮肤中的 PlusButton。 */
function skinnedPlusButton(skin: CYLSkin): CYLTabBarPlusButton {
  const plusButton = { ...PLUS_BUTTON, title: t(PLUS_BUTTON.title as string) };
  if (skin.icons) {
    const icon = THEME_ICONS[skin.icons.at(-1)!]!.image;
    return { ...plusButton, image: icon, selectedImage: icon };
  }
  if (skin.network) {
    return { ...plusButton, image: skin.network.plusButton[0], selectedImage: skin.network.plusButton[1] };
  }
  return plusButton;
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
function CYLSkinMenu({ visible, picker, colors, onClose }: Readonly<{ visible: boolean; picker: CYLSkinPicker; colors: typeof LIGHT; onClose: () => void }>) {
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
          <Text style={styles.menuHeader}>{t('Choose a theme')}</Text>
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
              return row(skin.name, icon, t(skin.name), !picker.followsSystem && skin.name === picker.skin.name, () => picker.choose(skin.name));
            })}
            {row('system', <Text style={[styles.menuIcon, styles.menuGlyph, { color: colors.label }]}>◐</Text>, t('Follow the system Dark Mode'), picker.followsSystem, picker.toggleFollowsSystem)}
          </ScrollView>
        </View>
      </Pressable>
    </Modal>
  );
}

/** A dot badge on a navigation bar button (`-cyl_showBadgeValue:animationType:backgroundColor:`). 导航栏按钮上的红点角标。 */
function CYLNavigationBadge({ color, animation }: Readonly<{ color: string; animation: 'breathe' | 'shake' }>) {
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
function CYLNavigationButton(props: Readonly<{ title: string; colors: typeof LIGHT; onPress: () => void; badge?: ReactNode }>) {
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

/**
 * [EN] CYLDemoSetFollowsSystem: Dark in dark mode; in light mode back to Default from Dark, otherwise the skin chosen.
 * [CN] 跟随系统：深色时为 Dark；浅色时从 Dark 回到 Default，否则为所选皮肤。
 */
function effectiveSkinName(skinName: string, followsSystem: boolean, dark: boolean): string {
  if (!followsSystem) {
    return skinName;
  }
  if (dark) {
    return 'Dark';
  }
  return skinName === 'Dark' ? 'Default' : skinName;
}

/**
 * [EN] MainTabBarController: the first page's title gets " (Liquid)" on Liquid Glass.
 * [CN] MainTabBarController：液态玻璃下第一个页面的标题加上「 (Liquid)」。
 */
function homePageTitle(selectedIndex: number, styleType: CYLStyleType): string {
  if (selectedIndex !== 0) {
    return t(ITEMS[selectedIndex]!.title as string);
  }
  return styleType === 'liquidGlass' ? `${t('Home')} (Liquid)` : t('Home');
}

/**
 * [EN] FlatDesign: a skin's tint colors the badges without a color of their own (`badgeBackgroundColor` of the
 *      appearance); Liquid Glass keeps them red.
 * [CN] 扁平样式：皮肤的 tint 为没有自定颜色的角标着色（appearance 的 `badgeBackgroundColor`）；液态玻璃下仍为红色。
 */
function badgesInSkin(badges: (CYLTabBarBadge | null)[], styleType: CYLStyleType, skin: CYLSkin): (CYLTabBarBadge | null)[] {
  if (styleType !== 'flatDesign' || !skin.tint) {
    return badges;
  }
  return badges.map((badge) => (badge && !badge.color ? { ...badge, color: skin.tint } : badge));
}

/** [EN] The values the demo rows show, in the current language, as the Objective-C example. [CN] 演示列表各行显示的值，使用当前语言，与 Objective-C 示例相同。 */
function demoValues(skinName: string, selectedIndex: number, titleOffset: number): Record<string, string> {
  const selectedTitle = selectedIndex === 0 ? 'Refresh' : (ITEMS[selectedIndex]!.title as string);
  return {
    titleOffset: `(0, ${titleOffset})`,
    appearance: t('Original'),
    skin: t(skinName),
    scrollBehavior: 'Automatic',
    indexWithoutPlus: String(selectedIndex),
    selectedIndex: String(selectedIndex < 2 ? selectedIndex : selectedIndex + 1),
    selectedTitle: t(selectedTitle),
    loginTabs: [t('Messages'), t('Me')].join(', '),
    bundleImage: 'Found CYLImagePathInBundle ✓ (cyl_badge_sample_icon@3x.png) · CYLBundleImagePath ✓ · CYLBundleImageData 11 KB · CYLBundleImageFromData ✓ (@3x) · CYLImageNamed ✓',
    touchScale: '1.0',
    tapAnimation: t('None'),
    tapSound: t('None'),
    longPress: '0.5',
    doubleTap: '0.35',
    adjacent: '-',
    outsideTaps: '0',
  };
}

/**
 * [EN] The system version, as -[CYLHomeViewController configureCell:forIndexPath:] ("iOS 26.5", "Android 15").
 * [CN] 系统版本，与 ObjC 示例相同（「iOS 26.5」「Android 15」）。
 */
function systemVersionText(): string {
  if (Platform.OS === 'ios') {
    return `iOS ${Platform.Version}`;
  }
  const release = (Platform.constants as { Release?: string }).Release ?? Platform.Version;
  return `Android ${release}`;
}

/** [EN] The badge samples' subtitle; the library translates the iOS one. [CN] 角标样例的副标题；库翻译了 iOS 的写法。 */
function badgeSubtitle(pageTitle: string): string {
  if (Platform.OS === 'ios') {
    return t('{page} CYLTabBarController on iOS {version}', { page: pageTitle, version: String(Platform.Version) });
  }
  return `${pageTitle} CYLTabBarController on ${systemVersionText()}`;
}

function CYLMainTabBar({
  styleType,
  onRebuild,
  skinPicker,
  loggedIn,
  onLoggedInChange,
  language,
  onLanguageChange,
}: Readonly<{
  styleType: CYLStyleType;
  onRebuild: (styleType: CYLStyleType) => void;
  skinPicker: CYLSkinPicker;
  loggedIn: boolean | undefined;
  onLoggedInChange: (loggedIn: boolean) => void;
  language: string | undefined;
  onLanguageChange: (language: string | undefined) => void;
}>) {
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
  const [languageMenuVisible, setLanguageMenuVisible] = useState(false);
  // -[CYLFlatDesignTableViewController tableView:didSelectRowAtIndexPath:]: setTabBarHidden:!isTabBarHidden animated:YES,
  // in every style. 在所有样式下切换 TabBar 的显示与隐藏。
  const [tabBarHidden, setTabBarHidden] = useState(false);
  // -[UIViewController cyl_simulateMemoryWarningAndShowResult]: each tap asks the tab bar for one simulated memory warning.
  // 每次点击请求 TabBar 模拟一次内存警告。
  const [memoryWarningRequest, setMemoryWarningRequest] = useState(0);
  // CYLSwitchTitlePositionAdjustment(): the title row cycles the vertical offset of every title through 0, -4 and 4 at
  // runtime (`setTitlePositionAdjustment:`); undefined is the configuration's -3.5. 标题行在运行时依次切换所有标题的垂直偏移：
  // 0、-4、4；undefined 为配置中的 -3.5。
  const [titleOffset, setTitleOffset] = useState<number | undefined>(undefined);
  const shownTitleOffset = titleOffset ?? (CONFIGURATION.CYLTabBarControllerTitlePositionAdjustment[1] as number);
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
  // The badge samples' subtitle uses the page's `title`; a badge row changes only `navigationItem.title` ("Home (n)").
  // 角标样例副标题使用页面的 `title`；点击角标行只修改 `navigationItem.title`（「Home (n)」）。
  const pageTitle = homePageTitle(selectedIndex, styleType);
  const { skin } = skinPicker;
  const skinnedBadges = badgesInSkin(badgeStyles, styleType, skin);

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
            title={t('Flat Design')}
            colors={colors}
            onPress={() => onRebuild('flatDesign')}
            badge={<CYLNavigationBadge color={navigationBadgeColors[0]!} animation="breathe" />}
          />
          <View style={styles.page} />
          <CYLNavigationButton title={t('Skin')} colors={colors} onPress={() => setSkinMenuVisible(true)} />
          <CYLNavigationButton
            title={t('Liquid Glass')}
            colors={colors}
            onPress={() => onRebuild('liquidGlass')}
            badge={<CYLNavigationBadge color={navigationBadgeColors[1]!} animation="shake" />}
          />
        </View>
      )}
      <CYLSkinMenu visible={skinMenuVisible} picker={skinPicker} colors={colors} onClose={() => setSkinMenuVisible(false)} />
      <CYLLanguageMenu visible={languageMenuVisible} colors={colors} onChoose={onLanguageChange} onClose={() => setLanguageMenuVisible(false)} />
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
          values={demoValues(skin.name, selectedIndex, shownTitleOffset)}
          switches={{ login: loggedIn === true }}
          currentSkin={skinPicker.followsSystem ? '' : skin.name}
          badgeSubtitle={badgeSubtitle(pageTitle)}
          onRow={(row: CYLDemoRow) => {
            if (row.skin) return skinPicker.choose(row.skin.name);
            if (row.id === 'skin') return setSkinMenuVisible(true);
            if (row.id === 'flatShowHide') return setTabBarHidden((hidden) => !hidden);
            if (row.id === 'memoryWarning') return setMemoryWarningRequest((request) => request + 1);
            if (row.id === 'titleOffset') return setTitleOffset(nextTitleOffset(shownTitleOffset));
            if (row.id === 'language') return presentLanguagePicker(onLanguageChange, () => setLanguageMenuVisible(true));
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
        language={language}
        tabBarHidden={tabBarHidden}
        memoryWarningRequest={memoryWarningRequest}
        titlePositionAdjustment={titleOffset === undefined ? undefined : [0, titleOffset]}
        onMemoryWarning={(report) => Alert.alert(t('Memory warning'), report, [{ text: t('OK') }])}
        // -[MainTabBarController cyl_demo_presentLoginForViewController:completion:]: "Messages" and "Me" need login; the
        // alert logs in, then selects the tapped tab. 「Messages」「Me」需要登录；弹窗登录后选中所点击的 Tab。
        onLoginRequest={(index, _identifier, title) =>
          Alert.alert(t('Login required'), t('Log in to view “{title}”', { title }), [
            { text: t('Cancel'), style: 'cancel' },
            {
              text: t('Log in'),
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
  // MainTabBarController: unloadsUnselectedViewsOnMemoryWarning = YES and -shouldUnloadViewOfViewController: keeps the home
  // tab (issue #426). 卸载未选中的 Tab，并保留首页 Tab。
  CYLTabBarControllerUnloadsUnselectedViewsOnMemoryWarning: true,
  CYLTabBarControllerKeepsLoadedTabBarItemIdentifiers: ['home'],
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
  // A dialog over a dimmed page, as an action sheet. 变暗页面上的对话框，与操作表相同。
  languageBackdrop: { alignItems: 'center', justifyContent: 'center', paddingTop: 0, paddingRight: 0, backgroundColor: '#00000066' },
  // The whole row: Android measures Devanagari ("हिन्दी") narrower than it draws, which wrapped and clipped it.
  // 占满整行：Android 测量天城文（「हिन्दी」）比实际绘制更窄，导致换行并被裁剪。
  languageTitle: { flex: 1, paddingHorizontal: 8 },
  languageMessage: { fontSize: 13 },
});
