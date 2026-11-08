/**
 * A badge on a view, drawn by React Native: the JavaScript twin of `UIView+CYLBadgeExtention` for the demo list's badge
 * samples (UITableViewCell+CYLBadgeExtention.m). Same defaults as `CYLBadgeAppearance`: red, bold 9 pt text, dot radius 4,
 * margin 8, maximum 99; centered 2 pt right of the host's top-right corner, moved by `offset`.
 * React Native 绘制的视图角标：`UIView+CYLBadgeExtention` 的 JavaScript 版本，用于演示列表的角标样例。默认值与 `CYLBadgeAppearance` 相同：
 * 红色、粗体 9pt 文字、红点半径 4、边距 8、最大值 99；中心位于宿主右上角右侧 2pt，可用 `offset` 移动。
 */
import { useEffect, useRef, useState } from 'react';
import { AccessibilityInfo, Animated, Easing, StyleSheet, Text, useColorScheme } from 'react-native';

export type CYLBadgeSample = {
  value: string;
  animation?: string;
  reduceMotion?: boolean;
  maximum?: number;
  color?: string;
  textColor?: string;
  italic?: boolean;
  fontSize?: number;
  borderColor?: string;
  borderWidth?: number;
  radius?: number;
  margin?: number;
  cornerRadius?: number;
  position?: 'topLeft' | 'bottomLeft' | 'bottomRight';
};

/** The text a value shows: numbers above the maximum become "99+". 数值超过最大值时显示为「99+」。 */
function badgeText(value: string, maximum: number) {
  const number = Number(value);
  return value !== '' && Number.isInteger(number) && number > maximum ? `${maximum}+` : value;
}

/** One loop of an animation, as the CAAnimation factories of the library. 与库中 CAAnimation 工厂方法对应的一次动画。 */
function animationFor(name: string, progress: Animated.Value): Animated.CompositeAnimation | null {
  const timing = (toValue: number, duration: number, easing = Easing.inOut(Easing.ease)) =>
    Animated.timing(progress, { toValue, duration, easing, useNativeDriver: true });
  const forever = (animation: Animated.CompositeAnimation) => Animated.loop(animation);
  const times = (count: number, animation: Animated.CompositeAnimation) => Animated.loop(animation, { iterations: count });
  const swing = (duration: number) => Animated.sequence([timing(1, duration / 4), timing(-1, duration / 2), timing(0, duration / 4)]);
  switch (name) {
    case 'scale':
    case 'breathe':
      return forever(Animated.sequence([timing(1, 600), timing(0, 600)]));
    case 'shake':
    case 'bounce':
      return forever(swing(800));
    case 'rotation':
      return forever(timing(1, 2000, Easing.linear));
    case 'springForever':
      return forever(Animated.sequence([Animated.spring(progress, { toValue: 1, useNativeDriver: true }), timing(0, 1)]));
    case 'shake3':
    case 'bounce3':
      return times(3, swing(1000 / 3));
    case 'scale3':
      return times(3, Animated.sequence([timing(1, 500), timing(0, 500)]));
    case 'blink3':
      return times(3, Animated.sequence([timing(1, 400), timing(0, 400)]));
    case 'flip2':
      return times(2, Animated.sequence([timing(1, 500, Easing.linear), timing(0, 0)]));
    case 'leftRightOnce':
    case 'rightLeftOnce':
    case 'fadeInOnce':
    case 'rollingOnce':
    case 'scaleOnce':
      return Animated.sequence([timing(0, 0), timing(1, 400)]);
    case 'springOnce':
      return Animated.sequence([timing(0, 0), Animated.spring(progress, { toValue: 1, useNativeDriver: true })]);
    default:
      return null;
  }
}

/** The style an animation gives the badge for a progress value. 动画在某个进度下给角标的样式。 */
function animatedStyle(name: string, progress: Animated.Value, width: number) {
  const map = (outputRange: number[] | string[], inputRange = [0, 1]) => progress.interpolate({ inputRange, outputRange } as never);
  switch (name) {
    case 'scale':
      return { transform: [{ scale: map([1, 1.2]) }] };
    case 'breathe':
      return { opacity: map([1, 0.3]) };
    case 'shake':
    case 'shake3':
      return { transform: [{ translateX: map([-width / 4, 0, width / 4], [-1, 0, 1]) }] };
    case 'bounce':
    case 'bounce3':
      return { transform: [{ translateY: map([-4, 0, 4], [-1, 0, 1]) }] };
    case 'rotation':
    case 'rollingOnce':
      return { transform: [{ rotate: map(['0deg', '360deg']) }] };
    case 'springForever':
    case 'springOnce':
      return { transform: [{ scale: map([0.5, 1]) }] };
    case 'scale3':
      return { transform: [{ scale: map([1.4, 0.6]) }] };
    case 'blink3':
      return { opacity: map([1, 0]) };
    case 'flip2':
      return { transform: [{ perspective: 200 }, { rotateY: map(['0deg', '180deg']) }] };
    case 'leftRightOnce':
      return { transform: [{ translateX: map([-width, 0]) }] };
    case 'rightLeftOnce':
      return { transform: [{ translateX: map([width, 0]) }] };
    case 'fadeInOnce':
      return { opacity: map([0, 1]) };
    case 'scaleOnce':
      return { transform: [{ scale: map([0, 1]) }] };
    default:
      return {};
  }
}

/** The badge, absolutely placed over a host of `hostSize`. 放在 `hostSize` 大小宿主上的角标（绝对定位）。 */
export function CYLBadgeView({ sample, hostSize }: { sample: CYLBadgeSample; hostSize: number }) {
  const dark = useColorScheme() === 'dark';
  const progress = useRef(new Animated.Value(0)).current;
  const [size, setSize] = useState({ width: 0, height: 0 });
  const [reduceMotion, setReduceMotion] = useState(false);
  useEffect(() => {
    if (sample.reduceMotion) AccessibilityInfo.isReduceMotionEnabled().then(setReduceMotion);
  }, [sample.reduceMotion]);
  const animationName = sample.animation && !(sample.reduceMotion && reduceMotion) ? sample.animation : '';
  useEffect(() => {
    progress.setValue(0);
    const animation = animationName ? animationFor(animationName, progress) : null;
    animation?.start();
    return () => animation?.stop();
  }, [animationName, progress]);

  const text = badgeText(sample.value, sample.maximum ?? 99);
  const margin = sample.margin ?? 8;
  const fontSize = sample.fontSize ?? 9;
  const isDot = text === '';
  const dotSide = (sample.radius ?? 4) * 2;
  const height = isDot ? dotSide : Math.ceil(fontSize * 1.2) + margin;
  // `CYLBadgeHelperCenterOffset`: from the top-right corner to the other corners. 从右上角移到其他角。
  const offsets: Record<string, [number, number]> = {
    topLeft: [-(hostSize + 4), 0],
    bottomLeft: [-(hostSize + 4), hostSize],
    bottomRight: [0, hostSize],
  };
  const offset = (sample.position && offsets[sample.position]) || [0, 0];
  const centerX = hostSize + 2 + offset[0]!;
  const centerY = offset[1]!;
  const borderColor = sample.borderColor === 'dynamic' ? (dark ? '#FFFFFF' : '#000000') : sample.borderColor;
  return (
    <Animated.View
      onLayout={(event) => setSize(event.nativeEvent.layout)}
      style={[
        styles.badge,
        {
          left: centerX - size.width / 2,
          top: centerY - size.height / 2,
          height,
          minWidth: height,
          paddingHorizontal: isDot ? 0 : margin / 2,
          borderRadius: sample.cornerRadius ?? height / 2,
          backgroundColor: sample.color ?? '#FF0000',
          borderColor,
          borderWidth: borderColor ? (sample.borderWidth ?? 0) : 0,
          opacity: size.width ? 1 : 0,
        },
        animatedStyle(animationName, progress, size.width),
      ]}
    >
      {!isDot && (
        <Text
          style={[
            styles.text,
            { fontSize, color: sample.textColor ?? '#FFFFFF', fontStyle: sample.italic ? 'italic' : 'normal', fontWeight: sample.italic ? '400' : '700' },
          ]}
        >
          {text}
        </Text>
      )}
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  badge: { position: 'absolute', alignItems: 'center', justifyContent: 'center' },
  text: { textAlign: 'center' },
});
