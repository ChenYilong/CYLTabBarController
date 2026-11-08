import { useState } from 'react';
import { Button, StyleSheet, Text, View } from 'react-native';
import { CYLTabBar, type CYLTabBarItem } from 'react-native-cyltabbar';

// The tabs: the same keys as a CYLTabBarController configuration file (docs/Configuration-File.md), with images required
// from JS. 与 CYLTabBarController 配置文件相同的键，图片从 JS 引入。
const ITEMS: CYLTabBarItem[] = [
  { title: 'Home', identifier: 'home', image: require('./assets/home_normal.png'), selectedImage: require('./assets/home_highlight.png') },
  { title: 'Fishpond', identifier: 'fishpond', image: require('./assets/fishpond_normal.png'), selectedImage: require('./assets/fishpond_highlight.png') },
  { title: 'Message', identifier: 'message', image: require('./assets/message_normal.png'), selectedImage: require('./assets/message_highlight.png') },
  { title: 'Me', identifier: 'account', image: require('./assets/account_normal.png'), selectedImage: require('./assets/account_highlight.png') },
];

const STYLES = ['default', 'liquidGlass', 'flatDesign'];

export default function App() {
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [styleIndex, setStyleIndex] = useState(0);
  const [badges, setBadges] = useState<string[]>(['', 'dot', '3', '']);
  const [plusTaps, setPlusTaps] = useState(0);
  const item = ITEMS[selectedIndex]!;

  return (
    <View style={styles.container}>
      {/* The page: React Native draws it; the native component draws only the bar. 页面由 RN 绘制，组件只绘制 TabBar。 */}
      <View style={styles.page}>
        <Text style={styles.title}>{item.title as string}</Text>
        <Text>identifier: {item.identifier as string}</Text>
        <Text>style: {STYLES[styleIndex]}</Text>
        <Text>plus button taps: {plusTaps}</Text>
        <Button title="Next style" onPress={() => setStyleIndex((styleIndex + 1) % STYLES.length)} />
        <Button title="Select Message from JS" onPress={() => setSelectedIndex(2)} />
        <Button
          title="Change badges"
          onPress={() => setBadges((current) => current.map((_, i) => (i === selectedIndex ? '' : String(Math.floor(Math.random() * 20)))))}
        />
      </View>
      <CYLTabBar
        items={ITEMS}
        styleType={STYLES[styleIndex]}
        plusButton={{ title: 'Post', image: require('./assets/post_normal.png') }}
        selectedIndex={selectedIndex}
        badgeValues={badges}
        onTabSelect={(index) => setSelectedIndex(index)}
        onPlusButtonPress={() => setPlusTaps((n) => n + 1)}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  page: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 8 },
  title: { fontSize: 28, fontWeight: '600' },
});
