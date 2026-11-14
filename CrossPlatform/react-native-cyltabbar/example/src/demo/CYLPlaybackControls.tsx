// The playback controls AGENTS.md asks of every example that shows tab icon animations ("Animated icon examples: Play all,
// speed slider, loop switch"). AGENTS.md 要求每个展示 Tab 图标动画的示例提供的播放控件（「全部播放」、倍速滑块、循环开关）。
import { useRef, useState } from 'react';
import { PanResponder, Pressable, StyleSheet, Switch, Text, View, type AccessibilityActionEvent, type LayoutChangeEvent } from 'react-native';
import type { CYLDemoColors } from './CYLDemoList';
import { t } from './CYLLocalization';

/** The speed range of the slider, in steps of 0.05. 滑块的速度范围，步长 0.05。 */
export const CYL_MINIMUM_SPEED = 0.25;
export const CYL_MAXIMUM_SPEED = 3;
const STEP = 0.05;

/** The speed as text without trailing zeros: "1.5". 不带多余 0 的速度文字："1.5"。 */
export function CYLSpeedText(speed: number): string {
  return speed.toFixed(2).replace(/\.?0+$/, '');
}

function clampedStep(speed: number): number {
  const steps = Math.round(speed / STEP);
  return Math.min(CYL_MAXIMUM_SPEED, Math.max(CYL_MINIMUM_SPEED, Math.round(steps * STEP * 100) / 100));
}

type Props = Readonly<{
  colors: CYLDemoColors;
  tint: string;
  speed: number;
  loops: boolean;
  onPlayAll: () => void;
  onSpeedChange: (speed: number) => void;
  onLoopsChange: (loops: boolean) => void;
}>;

/**
 * Play all, a speed slider and a loop switch for the tab icon animations of the tab bar. They combine into one playback
 * policy, applied live: Play all restarts every icon from progress 0 (`playAllRequest`), the slider sets `playbackSpeed`,
 * the switch sets `playbackLoops`. TalkBack and VoiceOver read the button as "Play all", the slider as "Speed, 1.5 times"
 * (it adjusts with swipes up and down) and the switch as "Loop, on".
 * 为 TabBar 的 Tab 图标动画提供「全部播放」、倍速滑块与循环开关，三者组合成一个实时生效的播放策略。TalkBack 与 VoiceOver 把按钮
 * 读作「全部播放」，滑块读作「倍速，1.5 倍」（上下滑动调整），开关读作「循环播放，开」。
 */
export function CYLPlaybackControls({ colors, tint, speed, loops, onPlayAll, onSpeedChange, onLoopsChange }: Props) {
  const [width, setWidth] = useState(1);
  const state = useRef({ width: 1, speed, onSpeedChange });
  state.current = { width, speed, onSpeedChange };
  const fraction = (speed - CYL_MINIMUM_SPEED) / (CYL_MAXIMUM_SPEED - CYL_MINIMUM_SPEED);
  const speedFromTouch = (x: number) => {
    const ratio = Math.min(1, Math.max(0, x / state.current.width));
    return clampedStep(CYL_MINIMUM_SPEED + ratio * (CYL_MAXIMUM_SPEED - CYL_MINIMUM_SPEED));
  };
  const responder = useRef(
    PanResponder.create({
      onStartShouldSetPanResponder: () => true,
      onMoveShouldSetPanResponder: () => true,
      onPanResponderGrant: (event) => state.current.onSpeedChange(speedFromTouch(event.nativeEvent.locationX)),
      onPanResponderMove: (event) => state.current.onSpeedChange(speedFromTouch(event.nativeEvent.locationX)),
    }),
  ).current;
  const onAccessibilityAction = (event: AccessibilityActionEvent) => {
    const direction = event.nativeEvent.actionName === 'increment' ? 1 : -1;
    onSpeedChange(clampedStep(speed + direction * 0.25));
  };
  const speedText = CYLSpeedText(speed);

  return (
    <View style={styles.container}>
      <Text accessibilityRole="header" style={[styles.title, { color: colors.secondaryLabel }]}>{t('Playback').toUpperCase()}</Text>
      <View style={[styles.card, { backgroundColor: colors.card }]}>
        <Pressable accessibilityRole="button" accessibilityLabel={t('Play all')} onPress={onPlayAll} style={styles.row}>
          <Text style={[styles.text, { color: tint }]}>{t('Play all')}</Text>
        </Pressable>
        <View style={styles.row}>
          <Text style={[styles.text, { color: colors.label }]} accessibilityElementsHidden importantForAccessibility="no-hide-descendants">{t('Speed')}</Text>
          <View
            style={styles.slider}
            onLayout={(event: LayoutChangeEvent) => setWidth(Math.max(1, event.nativeEvent.layout.width))}
            accessible
            accessibilityRole="adjustable"
            accessibilityLabel={t('Speed')}
            accessibilityValue={{ min: 0, max: 100, now: Math.round(fraction * 100), text: t('{speed} times', { speed: speedText }) }}
            accessibilityActions={[{ name: 'increment' }, { name: 'decrement' }]}
            onAccessibilityAction={onAccessibilityAction}
            {...responder.panHandlers}
          >
            <View style={[styles.track, { backgroundColor: colors.separator }]} />
            <View style={[styles.track, styles.filled, { backgroundColor: tint, width: `${fraction * 100}%` }]} />
            <View style={[styles.thumb, { left: `${fraction * 100}%`, borderColor: colors.separator }]} />
          </View>
          <Text style={[styles.value, { color: colors.secondaryLabel }]} accessibilityElementsHidden importantForAccessibility="no-hide-descendants">{`${speedText}×`}</Text>
        </View>
        <View style={styles.row}>
          <Text style={[styles.text, { color: colors.label }]} accessibilityElementsHidden importantForAccessibility="no-hide-descendants">{t('Loop')}</Text>
          <Switch
            value={loops}
            onValueChange={onLoopsChange}
            trackColor={{ true: tint }}
            accessibilityLabel={t('Loop')}
            accessibilityState={{ checked: loops }}
          />
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { paddingHorizontal: 16, paddingTop: 8 },
  title: { fontSize: 13, marginLeft: 16, marginBottom: 6 },
  card: { borderRadius: 10, paddingHorizontal: 16 },
  row: { minHeight: 48, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  text: { fontSize: 17 },
  value: { fontSize: 17, width: 52, textAlign: 'right' },
  slider: { flex: 1, height: 44, marginHorizontal: 12, justifyContent: 'center' },
  track: { position: 'absolute', left: 0, right: 0, height: 4, borderRadius: 2 },
  filled: { right: undefined },
  thumb: { position: 'absolute', width: 24, height: 24, marginLeft: -12, borderRadius: 12, borderWidth: StyleSheet.hairlineWidth, backgroundColor: '#FFFFFF' },
});
