/**
 * The React Native twin of Example-Rive: the same tab bar (Rive icons of the course's icons.riv, a purple "Start" plus
 * button with its own page, a dark glass bar), built from a configuration through <CYLTabBar>, and the course's pages
 * (Example-SwiftUI-Rive/AnimatedApp) drawn by React Native. Their Rive animations play through <CYLAnimationView>,
 * CYLTabBarController's own engine. The .riv files, the course's asset catalog and fonts are added to the iOS app (ios/)
 * and to the Android assets (android/app/build.gradle).
 * Example-Rive 的 React Native 版本：同样的 TabBar（课程 icons.riv 中的 Rive 图标、带自己页面的紫色 "Start" PlusButton、深色玻璃 TabBar），
 * 通过 <CYLTabBar> 由配置创建；课程页面（Example-SwiftUI-Rive/AnimatedApp）由 React Native 绘制，其中的 Rive 动画通过 <CYLAnimationView>
 * （CYLTabBarController 自己的引擎）播放。
 */
import { useEffect, useMemo, useState } from 'react';
import {
  Alert,
  Image,
  NativeModules,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  View,
  type ImageSourcePropType,
} from 'react-native';
import { CYLAnimationView, CYLTabBar, type CYLTabBarItem } from 'react-native-cyltabbar';
import { useSafeAreaInsetsTop } from './safeArea';

const locale: string =
  (Platform.OS === 'ios'
    ? NativeModules.SettingsManager?.settings?.AppleLocale ?? NativeModules.SettingsManager?.settings?.AppleLanguages?.[0]
    : NativeModules.I18nManager?.localeIdentifier) ?? 'en';
const chinese = locale.startsWith('zh');

// MARK: - Course styles (Styles/CustomFont.swift; the app is dark: Assets.xcassets/Colors) 课程样式

const BACKGROUND = '#25254B';
const BACKGROUND_2 = '#17203A';
const font = {
  largeTitle: { fontFamily: 'Poppins-Bold', fontSize: 34 },
  title2: { fontFamily: 'Poppins-Bold', fontSize: 24 },
  title3: { fontFamily: 'Poppins-Bold', fontSize: 20 },
  body: { fontFamily: 'Inter-Regular', fontSize: 17 },
  headline: { fontFamily: 'Inter-SemiBold', fontSize: 17 },
  subheadline: { fontFamily: 'Inter-Regular', fontSize: 15 },
  subheadline2: { fontFamily: 'Inter-SemiBold', fontSize: 15 },
  footnote: { fontFamily: 'Inter-Regular', fontSize: 13 },
  footnote2: { fontFamily: 'Inter-SemiBold', fontSize: 13 },
};

const IMAGES: Record<string, ImageSourcePropType> = {
  topic1: require('./assets/course/topic_1.png'),
  topic2: require('./assets/course/topic_2.png'),
  avatar4: require('./assets/course/avatar_4.png'),
  avatar5: require('./assets/course/avatar_5.png'),
  avatar6: require('./assets/course/avatar_6.png'),
  spline: require('./assets/course/spline.png'),
  email: require('./assets/course/icon_email.png'),
  lock: require('./assets/course/icon_lock.png'),
  logoEmail: require('./assets/course/logo_email.png'),
  logoApple: require('./assets/course/logo_apple.png'),
  logoGoogle: require('./assets/course/logo_google.png'),
};

// MARK: - The tab bar (TabItems.swift, RivePlusButton.swift, SceneDelegate.swift)

const TABS = [
  { id: 'chat', title: 'Chat', artboard: 'CHAT', symbol: 'message' },
  { id: 'search', title: 'Search', artboard: 'SEARCH', symbol: 'magnifyingglass' },
  { id: 'bell', title: 'Bell', artboard: 'BELL', symbol: 'bell' },
  { id: 'user', title: 'User', artboard: 'USER', symbol: 'person' },
] as const;

function tabItems(): CYLTabBarItem[] {
  return TABS.map((tab) => ({
    title: tab.title,
    identifier: tab.id,
    image: `system:${tab.symbol}`,
    selectedImage: `system:${tab.symbol}`,
    // [EN] The tab's artboard of icons.riv; icons.riv has no view model, so its state machine input "active" plays.
    // [CN] icons.riv 中该 Tab 的画板；icons.riv 没有 view model，因此播放其状态机输入 "active"。
    CYLTabBarRiveFilePath: 'icons.riv',
    CYLTabBarAnimationOptions: { artboard: tab.artboard, stateMachine: `${tab.artboard}_Interactivity`, input: 'active' },
    CYLTabBarRiveSize: '{32, 32}',
  }));
}

/**
 * applyCourseTabBarAppearance(): "Background 2" at 80%, white icons and titles, for the whole bar (the plus button's title,
 * aligned with the tab titles, too). "Background 2" 80% 不透明度，整个 TabBar（包括与 Tab 标题对齐的 PlusButton 标题）使用白色图标与标题。
 */
const THEMES = {
  CYLTabBarControllerThemes: {
    course: {
      CYLTabBarBackgroundColor: '#17203ACC',
      CYLTabBarItemTitleColor: '#FFFFFF99',
      CYLTabBarItemSelectedTitleColor: '#FFFFFF',
      CYLTabBarItemIconColor: '#FFFFFF99',
      CYLTabBarItemSelectedIconColor: '#FFFFFF',
    },
  },
};
const STYLES = ['liquidGlass', 'flatDesign'] as const;

// MARK: - Navigation bar (a UINavigationController with the tab's title) 导航栏

function NavigationBar({ title, dark = true }: { title: string; dark?: boolean }) {
  const top = useSafeAreaInsetsTop();
  return (
    <View style={{ paddingTop: top, backgroundColor: dark ? BACKGROUND : '#FFFFFF' }}>
      <View style={styles.navigationContent}>
        <Text style={[styles.navigationTitle, { color: dark ? '#FFFFFF' : '#000000' }]}>{title}</Text>
      </View>
    </View>
  );
}

// MARK: - Chat: HomeView (Views/HomeView.swift, Components/VCard.swift, HCard.swift)

const COURSES = [
  { title: 'Animations in SwiftUI', subtitle: 'Build and animate an iOS app from scratch', caption: '20 sections - 3 hours', color: '#7850F0', image: 'topic1' },
  { title: 'Build Quick Apps with SwiftUI', subtitle: 'Apply your Swift and SwiftUI knowledge by building real, quick and various applications from scratch', caption: '47 sections - 11 hours', color: '#6792FF', image: 'topic2' },
  { title: 'Build a SwiftUI app for iOS 15', subtitle: 'Design and code a SwiftUI 3 app with custom layouts, animations and gestures using Xcode 13, SF Symbols 3, Canvas, Concurrency, Searchable and a whole lot more', caption: '21 sections - 4 hours', color: '#005FE7', image: 'topic1' },
];
const SECTIONS = [
  { title: 'State Machine', caption: 'Watch video - 15 mins', color: '#9CC5FF', image: 'topic2' },
  { title: 'Animated Menu', caption: 'Watch video - 10 mins', color: '#6E6AE8', image: 'topic1' },
  { title: 'Tab Bar', caption: 'Watch video - 8 mins', color: '#005FE7', image: 'topic2' },
  { title: 'Button', caption: 'Watch video - 9 mins', color: '#BBA6FF', image: 'topic1' },
];

function HomePage() {
  return (
    <View style={styles.dark}>
      <NavigationBar title="Chat" />
      <ScrollView contentContainerStyle={styles.bottomRoom}>
        <Text style={[font.largeTitle, styles.white, styles.horizontal20]}>Courses</Text>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.cards}>
          {COURSES.map((course) => (
            <View
              key={course.title}
              // [EN] VCard.swift: a gradient from the color to its half opacity, top-left to bottom-right (React Native's built-in CSS gradient).
              // [CN] VCard.swift：从颜色到其半透明的渐变，左上到右下（React Native 内置的 CSS 渐变）。
              style={[styles.vCard, { backgroundImage: `linear-gradient(to bottom right, ${course.color}, ${course.color}80)`, shadowColor: course.color }]}>
              <Image source={IMAGES[course.image]!} style={styles.vCardImage} />
              <Text style={[font.title2, styles.white, styles.vCardTitle]}>{course.title}</Text>
              <Text style={[font.body, styles.whiteDim]} numberOfLines={3}>{course.subtitle}</Text>
              <Text style={[font.footnote2, styles.whiteDim]}>{course.caption.toUpperCase()}</Text>
              <View style={styles.flex} />
              <View style={styles.avatars}>
                {['avatar4', 'avatar5', 'avatar6'].map((avatar, index) => (
                  <Image key={avatar} source={IMAGES[avatar]!} style={[styles.avatar, { marginLeft: index === 0 ? 0 : -20 }]} />
                ))}
              </View>
            </View>
          ))}
        </ScrollView>
        <View style={styles.padding20}>
          <Text style={[font.title3, styles.white, styles.recent]}>Recent</Text>
          {SECTIONS.map((section) => (
            <View key={section.title} style={[styles.hCard, { backgroundColor: section.color }]}>
              <View style={styles.flex}>
                <Text style={[font.title2, styles.white]}>{section.title}</Text>
                <Text style={[font.body, styles.white]}>{section.caption}</Text>
              </View>
              <View style={styles.divider} />
              <Image source={IMAGES[section.image]!} />
            </View>
          ))}
        </View>
      </ScrollView>
    </View>
  );
}

// MARK: - Search: SideMenu (Navigation/SideMenu.swift), its icons from icons.riv

const BROWSE = [
  { text: 'Home', artboard: 'HOME', machine: 'HOME_interactivity' },
  { text: 'Search', artboard: 'SEARCH', machine: 'SEARCH_Interactivity' },
  { text: 'Favorites', artboard: 'LIKE/STAR', machine: 'STAR_Interactivity' },
  { text: 'Help', artboard: 'CHAT', machine: 'CHAT_Interactivity' },
];
const HISTORY = [
  { text: 'History', artboard: 'TIMER', machine: 'TIMER_Interactivity' },
  { text: 'Notifications', artboard: 'BELL', machine: 'BELL_Interactivity' },
];

function MenuRow({ item, selected, onPress }: { item: (typeof BROWSE)[number]; selected: boolean; onPress: () => void }) {
  const [playing, setPlaying] = useState(false);
  return (
    <Pressable
      onPress={() => {
        onPress();
        setPlaying(true);
        setTimeout(() => setPlaying(false), 2000);
      }}
      style={[styles.menuRow, selected && styles.menuRowSelected]}
    >
      <CYLAnimationView
        file="icons.riv"
        options={{ artboard: item.artboard, stateMachine: item.machine, input: 'active', duration: 2 }}
        playing={playing}
        style={styles.menuIcon}
      />
      <Text style={[font.headline, styles.white]}>{item.text}</Text>
    </Pressable>
  );
}

function SideMenuPage() {
  const [selected, setSelected] = useState('Home');
  const [dark, setDark] = useState(true);
  return (
    <View style={[styles.flex, { backgroundColor: BACKGROUND_2 }]}>
      <NavigationBar title="Search" />
      <ScrollView contentContainerStyle={styles.bottomRoom}>
        <View style={styles.profile}>
          <View style={styles.profileIcon}>
            <Text style={styles.profileGlyph}>👤</Text>
          </View>
          <View>
            <Text style={[font.body, styles.white]}>Meng To</Text>
            <Text style={[font.subheadline, styles.whiteDim]}>UI Designer</Text>
          </View>
        </View>
        <Text style={[font.subheadline2, styles.menuHeader]}>BROWSE</Text>
        {BROWSE.map((item) => (
          <MenuRow key={item.text} item={item} selected={selected === item.text} onPress={() => setSelected(item.text)} />
        ))}
        <Text style={[font.subheadline2, styles.menuHeader]}>HISTORY</Text>
        {HISTORY.map((item) => (
          <MenuRow key={item.text} item={item} selected={selected === item.text} onPress={() => setSelected(item.text)} />
        ))}
        <View style={styles.menuRow}>
          <CYLAnimationView file="icons.riv" options={{ artboard: 'SETTINGS', stateMachine: 'SETTINGS_Interactivity', input: 'active', duration: 0 }} playing={dark} style={styles.menuIcon} />
          <Text style={[font.headline, styles.white, styles.flex]}>Dark Mode</Text>
          <Switch value={dark} onValueChange={setDark} />
        </View>
      </ScrollView>
    </View>
  );
}

// MARK: - Start: OnboardingView (Views/OnboardingView.swift): shapes.riv behind, button.riv to start

function OnboardingPage() {
  const [pressed, setPressed] = useState(false);
  return (
    <View style={[styles.flex, { backgroundColor: BACKGROUND }]}>
      <Image source={IMAGES.spline!} style={styles.spline} blurRadius={50} />
      <CYLAnimationView file="shapes.riv" options={{ legacy: 1 }} playing style={StyleSheet.absoluteFill} />
      <NavigationBar title="Start" />
      <View style={styles.onboarding}>
        <Text style={styles.onboardingTitle}>Learn design & code</Text>
        <Text style={[font.body, styles.whiteDim]}>
          Don’t skip design. Learn design and code, by building real apps with React and Swift. Complete courses about the best tools.
        </Text>
        <View style={styles.flex} />
        <Pressable
          style={styles.startButton}
          onPress={() => {
            setPressed(true);
            setTimeout(() => setPressed(false), 800);
          }}
        >
          <CYLAnimationView file="button.riv" options={{ animation: 'active' }} playing={pressed} style={StyleSheet.absoluteFill} />
          <Text style={[font.headline, styles.startLabel]}>→  Start the course</Text>
        </Pressable>
        <Text style={[font.footnote, styles.whiteDim]}>
          Purchase includes access to 30+ courses, 240+ premium tutorials, 120+ hours of videos, source files and certificates.
        </Text>
      </View>
    </View>
  );
}

// MARK: - Bell: menu_button.riv (RiveMenuButtonDemoView.swift) above the settings list

function BellPage({ styleIndex, onStyle }: { styleIndex: number; onStyle: () => void }) {
  const [open, setOpen] = useState(false);
  return (
    <View style={[styles.flex, styles.black]}>
      <NavigationBar title="Bell" />
      <ScrollView contentContainerStyle={styles.bottomRoom}>
        <View style={styles.bellHeader}>
          <CYLAnimationView file="menu_button.riv" options={{ stateMachine: 'State Machine', input: 'isOpen', duration: 0 }} playing={open} style={styles.menuButton} />
          <Pressable onPress={() => setOpen((value) => !value)}>
            <Text style={styles.playStop}>{chinese ? '播放 / 停止' : 'Play / Stop'}</Text>
          </Pressable>
        </View>
        <Text style={styles.sectionTitle}>{chinese ? 'TabBar 外观' : 'Tab bar appearance'}</Text>
        <View style={styles.card}>
          <Pressable style={styles.row} onPress={onStyle}>
            <Text style={styles.rowTitle}>{chinese ? '样式' : 'Style'}</Text>
            <Text style={styles.rowDetail}>{STYLES[styleIndex] === 'flatDesign' ? 'FlatDesign' : 'Liquid Glass'}</Text>
          </Pressable>
        </View>
      </ScrollView>
    </View>
  );
}

// MARK: - User: SignInView (Views/SignInView.swift): check.riv and confetti.riv

function SignInPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [succeeded, setSucceeded] = useState(false);
  const [check, setCheck] = useState(false);
  const [confetti, setConfetti] = useState(false);
  const logIn = () => {
    setLoading(true);
    const ok = email !== '';
    setSucceeded(ok);
    setTimeout(() => setCheck(true), 1000);
    setTimeout(() => {
      if (ok) setConfetti(true);
      setLoading(false);
      setCheck(false);
    }, 3000);
    setTimeout(() => setConfetti(false), 4000);
  };
  return (
    <View style={[styles.flex, { backgroundColor: BACKGROUND }]}>
      <NavigationBar title="User" />
      <ScrollView contentContainerStyle={[styles.padding20, styles.bottomRoom]}>
        <View style={styles.signIn}>
          <Text style={[font.largeTitle, styles.signInCenter]}>Sign in</Text>
          <Text style={[font.body, styles.secondary, styles.signInCenter]}>
            Access to 240+ hours of content. Learn design and code, by building real apps with React and Swift.
          </Text>
          <Text style={[font.subheadline, styles.secondary]}>Email</Text>
          <View style={styles.field}>
            <Image source={IMAGES.email!} style={styles.fieldIcon} />
            <TextInput value={email} onChangeText={setEmail} autoCapitalize="none" style={styles.fieldInput} />
          </View>
          <Text style={[font.subheadline, styles.secondary]}>Password</Text>
          <View style={styles.field}>
            <Image source={IMAGES.lock!} style={styles.fieldIcon} />
            <TextInput value={password} onChangeText={setPassword} secureTextEntry style={styles.fieldInput} />
          </View>
          <Pressable style={styles.signInButton} onPress={logIn}>
            <Text style={[font.headline, styles.white]}>→  Sign in</Text>
          </Pressable>
          <View style={styles.orRow}>
            <View style={styles.orLine} />
            <Text style={[font.subheadline2, styles.or]}>OR</Text>
            <View style={styles.orLine} />
          </View>
          <Text style={[font.subheadline, styles.secondary, styles.signInCenter]}>Sign up with Email, Apple, Google</Text>
          <View style={styles.logos}>
            <Image source={IMAGES.logoEmail!} />
            <Image source={IMAGES.logoApple!} />
            <Image source={IMAGES.logoGoogle!} />
          </View>
          {loading ? (
            <CYLAnimationView
              file="check.riv"
              options={{ stateMachine: 'State Machine 1', triggerInput: succeeded ? 'Check' : 'Error' }}
              playing={check}
              style={styles.check}
            />
          ) : null}
          <CYLAnimationView
            file="confetti.riv"
            options={{ stateMachine: 'State Machine 1', triggerInput: 'Trigger explosion' }}
            playing={confetti}
            style={styles.confetti}
            pointerEvents="none"
          />
        </View>
      </ScrollView>
    </View>
  );
}

// MARK: - The app

export default function App() {
  const [selected, setSelected] = useState<string>('chat');
  const [styleIndex, setStyleIndex] = useState(0);
  const [plusBadge, setPlusBadge] = useState(0);
  const items = useMemo(tabItems, []);

  // demoShowPlusButtonBadgeAfterLayout(): 1 after launch. 启动后显示 1。
  useEffect(() => {
    const timer = setTimeout(() => setPlusBadge((count) => Math.max(count, 1)), 1500);
    return () => clearTimeout(timer);
  }, []);

  const index = TABS.findIndex((tab) => tab.id === selected);
  let page;
  switch (selected) {
    case 'plus':
      page = <OnboardingPage />;
      break;
    case 'search':
      page = <SideMenuPage />;
      break;
    case 'bell':
      page = <BellPage styleIndex={styleIndex} onStyle={() => setStyleIndex((value) => (value + 1) % STYLES.length)} />;
      break;
    case 'user':
      page = <SignInPage />;
      break;
    default:
      page = <HomePage />;
  }

  return (
    <View style={styles.black}>
      <View style={styles.flex}>{page}</View>
      <CYLTabBar
        style={styles.tabBar}
        items={items}
        styleType={STYLES[styleIndex]}
        userInterfaceStyle="dark"
        tapAnimation="bounce"
        swipeToSwitchTab
        configuration={THEMES}
        plusButton={{ image: require('./assets/rive_plus.png'), title: 'Start', index: 2, identifier: 'plus', pageIdentifier: 'timer' }}
        selectedIndex={index}
        plusButtonBadgeValue={plusBadge > 0 ? String(plusBadge) : ''}
        badgeAnimation="bounce"
        onTabSelect={(i, identifier) => setSelected(i < 0 ? 'plus' : identifier)}
        onPlusButtonPress={() => setPlusBadge((count) => count + 1)}
        onTabLongPress={(_, __, title) =>
          Alert.alert(chinese ? `长按了「${title}」` : `Long-pressed "${title}"`, undefined, [{ text: chinese ? '取消' : 'Cancel', style: 'cancel' }])
        }
      />
    </View>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  dark: { flex: 1, backgroundColor: BACKGROUND },
  black: { flex: 1, backgroundColor: '#000000' },
  white: { color: '#FFFFFF' },
  whiteDim: { color: '#FFFFFF', opacity: 0.7 },
  secondary: { color: '#8E8E93' },
  tabBar: { position: 'absolute', left: 0, right: 0, bottom: 0 },
  bottomRoom: { paddingBottom: 140 },
  horizontal20: { paddingHorizontal: 20 },
  padding20: { padding: 20 },
  navigationContent: { height: 44, alignItems: 'center', justifyContent: 'center' },
  navigationTitle: { fontSize: 17, fontWeight: '600' },
  cards: { padding: 20, paddingBottom: 30, gap: 20 },
  vCard: {
    width: 260, height: 310, borderRadius: 30, padding: 30, gap: 8,
    shadowOpacity: 0.3, shadowRadius: 8, shadowOffset: { width: 0, height: 12 }, elevation: 8,
  },
  vCardImage: { position: 'absolute', top: 20, right: 20 },
  vCardTitle: { maxWidth: 170 },
  avatars: { flexDirection: 'row' },
  avatar: { width: 44, height: 44, borderRadius: 22 },
  recent: { marginBottom: 20 },
  hCard: { height: 110, borderRadius: 30, padding: 30, flexDirection: 'row', alignItems: 'center', gap: 20, marginBottom: 20 },
  divider: { width: StyleSheet.hairlineWidth, alignSelf: 'stretch', backgroundColor: '#FFFFFF66' },
  profile: { flexDirection: 'row', alignItems: 'center', gap: 12, padding: 20 },
  profileIcon: { width: 44, height: 44, borderRadius: 22, backgroundColor: '#FFFFFF33', alignItems: 'center', justifyContent: 'center' },
  profileGlyph: { fontSize: 20 },
  menuHeader: { color: '#FFFFFF', opacity: 0.7, paddingHorizontal: 24, paddingTop: 30, paddingBottom: 8 },
  menuRow: { flexDirection: 'row', alignItems: 'center', gap: 14, marginHorizontal: 8, paddingHorizontal: 12, height: 56, borderRadius: 10 },
  menuRowSelected: { backgroundColor: '#6E6AE8' },
  menuIcon: { width: 32, height: 32 },
  spline: { position: 'absolute', left: 200, top: 100, opacity: 0.8 },
  onboarding: { flex: 1, padding: 40, paddingTop: 40, gap: 16, paddingBottom: 140 },
  onboardingTitle: { fontFamily: 'Poppins-Bold', fontSize: 60, lineHeight: 66, width: 260, color: '#FFFFFF' },
  startButton: { width: 236, height: 64, alignItems: 'center', justifyContent: 'center' },
  startLabel: { color: '#000000', marginTop: 8, marginLeft: 8 },
  bellHeader: { alignItems: 'center', paddingTop: 16, paddingBottom: 8, gap: 12 },
  menuButton: { width: 88, height: 88 },
  playStop: { color: '#0A84FF', fontSize: 17, fontWeight: '600' },
  sectionTitle: { fontSize: 15, fontWeight: '600', color: '#EBEBF5', marginHorizontal: 32, marginTop: 24, marginBottom: 8 },
  card: { borderRadius: 14, backgroundColor: '#1C1C1E', marginHorizontal: 16, overflow: 'hidden' },
  row: { minHeight: 52, paddingHorizontal: 16, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  rowTitle: { fontSize: 16, color: '#FFFFFF' },
  rowDetail: { fontSize: 14, color: '#8E8E93' },
  signIn: { backgroundColor: '#F2F2F7', borderRadius: 20, padding: 30, gap: 12 },
  signInCenter: { textAlign: 'center' },
  field: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#FFFFFF', borderRadius: 10, borderWidth: 1, borderColor: '#0000001A', paddingLeft: 8 },
  fieldIcon: { marginRight: 8 },
  fieldInput: { flex: 1, paddingVertical: 15, fontSize: 17, color: '#000000' },
  signInButton: { backgroundColor: '#F77D8E', height: 60, borderRadius: 20, borderTopLeftRadius: 8, alignItems: 'center', justifyContent: 'center', marginTop: 8 },
  orRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  orLine: { flex: 1, height: 1, backgroundColor: '#0000001A' },
  or: { color: '#0000004D' },
  logos: { flexDirection: 'row', justifyContent: 'space-between' },
  check: { position: 'absolute', alignSelf: 'center', top: '40%', width: 100, height: 100 },
  confetti: { position: 'absolute', left: 0, right: 0, top: 0, bottom: 0 },
});
