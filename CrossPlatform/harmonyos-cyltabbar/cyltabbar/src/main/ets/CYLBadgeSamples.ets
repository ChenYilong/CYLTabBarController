import { CYLBadge, CYLBadgeAnimationType } from './CYLBadge';

/**
 * [EN] The badge samples of the iOS Example (UITableViewCell+CYLBadgeExtention, CYLBadgeHelperTableViewController),
 *      ported from CYLBadgeExtensions.kt: every badge style and animation, in the iOS order.
 * [CN] iOS Example 的角标样例（UITableViewCell+CYLBadgeExtention、CYLBadgeHelperTableViewController），从 CYLBadgeExtensions.kt
 *      迁移：每种角标样式与动画，顺序与 iOS 相同。
 */
export interface CYLBadgeSample {
  title: string;
  api?: string;
  value: string;
  animationType?: CYLBadgeAnimationType;
  repeats?: number;
  maximum?: number;
  colors?: boolean;
  font?: boolean;
  border?: boolean;
  radius?: number;
  margin?: number;
  cornerRadius?: number;
  reduceMotion?: boolean;
  /** [EN] 'topLeft' | 'bottomLeft' | 'bottomRight'. [CN] 角标位置。 */
  position?: string;
  /** [EN] 'rotation' | 'flip' (CYLBadge.customAnimation). [CN] 自定义动画。 */
  custom?: string;
}

const A = CYLBadgeAnimationType;

export const CYLBadgeSamples: CYLBadgeSample[] = [
  { title: 'Scale (forever)', api: 'CYLBadgeAnimationTypeScale', value: '3', animationType: A.Scale },
  { title: 'Shake (forever)', api: 'CYLBadgeAnimationTypeShake', value: '3', animationType: A.Shake },
  { title: 'Bounce (forever)', api: 'CYLBadgeAnimationTypeBounce', value: '3', animationType: A.Bounce },
  { title: 'Breathe (forever)', api: 'CYLBadgeAnimationTypeBreathe', value: '', animationType: A.Breathe },
  { title: 'Shake, stops with Reduce Motion', api: 'cyl_badgeRespectsReduceMotion', value: '3', animationType: A.Shake, reduceMotion: true },
  { title: 'Rotation (forever)', api: 'cyl_rotationAnimationWithDuration:', value: 'new', custom: 'rotation' },
  { title: 'Spring (forever)', api: 'cyl_springAnimationForDuration:', value: '3', animationType: A.ScaleOnce, repeats: -1 },
  { title: 'Shake ×3 (cyl_shakeAnimationRepeatTimes)', value: '3', animationType: A.Shake, repeats: 3 },
  { title: 'Bounce ×3 (cyl_bounceAnimationRepeatTimes)', value: '3', animationType: A.Bounce, repeats: 3 },
  { title: 'Scale ×3', api: 'cyl_scaleAnimationFromScale:', value: '3', animationType: A.Scale, repeats: 3 },
  { title: 'Blink ×3', api: 'cyl_opacityTimesAnimationRepeatTimes:', value: '', animationType: A.Breathe, repeats: 3 },
  { title: 'Flip ×2', api: 'cyl_rotationAnimationWithDuration:', value: '3', custom: 'flip' },
  { title: 'Left to right once', api: 'CYLBadgeAnimationTypeLeftRightOnce', value: '3', animationType: A.LeftRightOnce },
  { title: 'Right to left once', api: 'CYLBadgeAnimationTypeRightLeftOnce', value: '3', animationType: A.RightLeftOnce },
  { title: 'Fade in once', api: 'CYLBadgeAnimationTypeFadeInOnce', value: '3', animationType: A.FadeInOnce },
  { title: 'Rolling once', api: 'CYLBadgeAnimationTypeRollingOnce', value: '3', animationType: A.RollingOnce },
  { title: 'Scale once', api: 'CYLBadgeAnimationTypeScaleOnce', value: '3', animationType: A.ScaleOnce },
  { title: 'Spring once', api: 'cyl_springAnimationForDuration:', value: '3', animationType: A.ScaleOnce },
  { title: 'Red dot', api: 'cyl_showBadge', value: '' },
  { title: 'Number', api: 'cyl_showBadgeValue:', value: '8' },
  { title: 'Number above maximum', api: 'cyl_badgeMaximumBadgeNumber', value: '100' },
  { title: 'Custom maximum (9)', api: 'cyl_badgeMaximumBadgeNumber', value: '10', maximum: 9 },
  { title: 'New', api: 'cyl_showBadgeValue:@"new"', value: 'new' },
  { title: 'NEW', api: 'cyl_showBadgeValue:@"NEW"', value: 'NEW' },
  { title: 'Other text', api: 'cyl_showBadgeValue:', value: 'hot' },
  { title: 'Custom colors', api: 'cyl_badgeBackgroundColor / cyl_badgeTextColor', value: '5', colors: true },
  { title: 'Custom font', api: 'cyl_badgeFont', value: '5', font: true },
  { title: 'Border', api: 'cyl_badgeBorderColor / cyl_badgeBorderWidth', value: '5', border: true },
  { title: 'Border following Dark Mode', api: 'cyl_badgeBorderColor', value: '5', border: true },
  { title: 'Red dot radius', api: 'cyl_badgeRadius', value: '', radius: 6 },
  { title: 'Margin', api: 'cyl_badgeMargin', value: '5', margin: 7 },
  { title: 'Corner radius', api: 'cyl_badgeCornerRadius', value: 'new', cornerRadius: 3 },
  { title: 'Top left', api: 'cyl_badgeCenterOffset', value: '5', position: 'topLeft' },
  { title: 'Bottom left', api: 'cyl_badgeCenterOffset', value: '5', position: 'bottomLeft' },
  { title: 'Bottom right', api: 'cyl_badgeCenterOffset', value: '5', position: 'bottomRight' },
];

function sampleForRow(row: number): CYLBadgeSample {
  return CYLBadgeSamples[Math.max(0, row) % CYLBadgeSamples.length];
}

/**
 * [EN] +cyl_badgeTitleForRow:: "<row + 1>. <title> (<API>)". [CN] 第 row 行样例的标题与核心 API。
 */
export function cyl_badgeTitleForRow(row: number): string {
  const sample = sampleForRow(row);
  const title = sample.api !== undefined && sample.title.indexOf(sample.api) < 0 ? `${sample.title} (${sample.api})` : sample.title;
  return `${row + 1}. ${title}`;
}

/**
 * [EN] +cyl_badgeStyleCount: the number of samples. [CN] 样例数量。
 */
export function cyl_badgeStyleCount(): number {
  return CYLBadgeSamples.length;
}

/**
 * [EN] -cyl_showBadgeSampleForRow: shows the sample of `row` on `badge` (an icon of `iconSize` vp).
 * [CN] 在 `badge` 上显示第 row 行的样例（图标尺寸 iconSize vp）。
 */
export function cyl_applyBadgeSample(badge: CYLBadge, row: number, iconSize: number = 30): void {
  const sample = sampleForRow(row);
  badge.cyl_resetBadgeAppearance();
  badge.repeatCount = sample.repeats;
  badge.customAnimation = sample.custom;
  badge.respectsReduceMotion = sample.reduceMotion === true;
  if (sample.maximum !== undefined) {
    badge.maximumBadgeNumber = sample.maximum;
  }
  if (sample.colors) {
    badge.backgroundColor = '#007AFF';
    badge.textColor = '#FFFF00';
  }
  if (sample.font) {
    badge.fontSize = 13;
  }
  if (sample.border) {
    badge.borderColor = '#FFFFFF';
    badge.borderWidth = 1.5;
  }
  if (sample.radius !== undefined) {
    badge.radius = sample.radius;
  }
  if (sample.margin !== undefined) {
    badge.margin = sample.margin;
  }
  if (sample.cornerRadius !== undefined) {
    badge.cornerRadius = sample.cornerRadius;
  }
  if (sample.position === 'topLeft') {
    badge.centerOffset = { horizontal: -iconSize - 4, vertical: 0 };
  } else if (sample.position === 'bottomLeft') {
    badge.centerOffset = { horizontal: -iconSize - 4, vertical: iconSize };
  } else if (sample.position === 'bottomRight') {
    badge.centerOffset = { horizontal: 0, vertical: iconSize };
  }
  badge.cyl_showBadgeValue(sample.value, sample.animationType ?? CYLBadgeAnimationType.None);
}
