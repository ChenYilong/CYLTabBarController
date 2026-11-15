import { curves } from '@kit.ArkUI';

/**
 * [EN] Badges, ported from the Android sources (CYLBadge.kt, CYLBadgeExtensions.kt) with the iOS names
 *      (CYLBadgeView/CYLBadgeProtocol.h, CYLBadgeAppearance.h, UIView+CYLBadgeExtention.h).
 * [CN] 角标，从 Android 源码（CYLBadge.kt、CYLBadgeExtensions.kt）迁移，使用 iOS 名称。
 */

/**
 * [EN] CYLBadgeAnimationType. [CN] 角标动画类型。
 */
export enum CYLBadgeAnimationType {
  None = 0,
  Scale,
  Shake,
  Bounce,
  Breathe,
  LeftRightOnce,
  RightLeftOnce,
  FadeInOnce,
  RollingOnce,
  ScaleOnce,
}

/**
 * [EN] CYLOffset / CGPoint: an offset in vp. [CN] 偏移（vp）。
 */
export interface CYLOffset {
  horizontal: number;
  vertical: number;
}

const CYL_DEFAULT_RADIUS: number = 4;
const CYL_DEFAULT_MARGIN: number = 8;
const CYL_DEFAULT_FONT_SIZE: number = 9;

/**
 * [EN] CYLBadgeAppearance: the defaults of every badge (globalAppearance); a value set on a badge wins (#425).
 * [CN] CYLBadgeAppearance：所有角标的默认外观（globalAppearance）；角标上设置的值优先（#425）。
 */
export class CYLBadgeAppearance {
  static readonly globalAppearance: CYLBadgeAppearance = new CYLBadgeAppearance();
  backgroundColor: ResourceColor = '#FF0000';
  textColor: ResourceColor = '#FFFFFF';
  fontSize: number = CYL_DEFAULT_FONT_SIZE;
  centerOffset: CYLOffset = { horizontal: 0, vertical: 0 };
  private radiusValue: number = CYL_DEFAULT_RADIUS;
  private marginValue: number = CYL_DEFAULT_MARGIN;
  private maximumValue: number = 99;
  private cornerRadiusValue: number = 0;
  borderColor?: ResourceColor;
  private borderWidthValue: number = 0;

  /** [EN] Red dot radius (vp); 0, negative or not finite restores 4. [CN] 红点半径；非法值恢复为 4。 */
  get radius(): number {
    return this.radiusValue;
  }

  set radius(value: number) {
    this.radiusValue = value > 0 && Number.isFinite(value) ? value : CYL_DEFAULT_RADIUS;
  }

  /** [EN] Space added to the text's width and height (vp), 8 by default. [CN] 文字宽高各加的边距，默认 8。 */
  get margin(): number {
    return this.marginValue;
  }

  set margin(value: number) {
    this.marginValue = Number.isFinite(value) ? Math.max(0, value) : 0;
  }

  /** [EN] Numbers above it show as "<maximum>+"; below 1: 1. [CN] 超过它显示为 "<maximum>+"；小于 1 时为 1。 */
  get maximumBadgeNumber(): number {
    return this.maximumValue;
  }

  set maximumBadgeNumber(value: number) {
    this.maximumValue = Math.max(1, Math.floor(value));
  }

  /** [EN] Corner radius of number and text badges; 0 is a capsule. [CN] 数字与文字角标圆角；0 为胶囊形。 */
  get cornerRadius(): number {
    return this.cornerRadiusValue;
  }

  set cornerRadius(value: number) {
    this.cornerRadiusValue = Number.isFinite(value) ? Math.max(0, value) : 0;
  }

  /** [EN] Border width (vp); drawn only when > 0. [CN] 边框宽度；> 0 时才绘制。 */
  get borderWidth(): number {
    return this.borderWidthValue;
  }

  set borderWidth(value: number) {
    this.borderWidthValue = Number.isFinite(value) ? Math.max(0, value) : 0;
  }

  /** [EN] -reset: every property back to its default. [CN] 恢复所有默认值。 */
  reset(): void {
    this.backgroundColor = '#FF0000';
    this.textColor = '#FFFFFF';
    this.fontSize = CYL_DEFAULT_FONT_SIZE;
    this.centerOffset = { horizontal: 0, vertical: 0 };
    this.radiusValue = CYL_DEFAULT_RADIUS;
    this.marginValue = CYL_DEFAULT_MARGIN;
    this.maximumValue = 99;
    this.cornerRadiusValue = 0;
    this.borderColor = undefined;
    this.borderWidthValue = 0;
  }
}

/**
 * [EN] The badge of one view (a tab, the plus button or any view): CYLBadgeProtocol's state and methods
 *      (-cyl_showBadge, -cyl_showBadgeValue:animationType:, -cyl_clearBadge, -cyl_pauseBadge, -cyl_resumeBadge, ...).
 *      Unset appearance values follow CYLBadgeAppearance.globalAppearance. Shown by CYLBadgeView.
 * [CN] 单个视图（Tab、加号按钮或任意视图）的角标：CYLBadgeProtocol 的状态与方法。未设置的外观值跟随全局外观。由 CYLBadgeView 显示。
 */
@Observed
export class CYLBadge {
  /** [EN] The value: null no badge, "" a red dot, a number, "new" / "NEW", or any text. [CN] 值：null 无角标，"" 红点，数字、"new"/"NEW" 或文字。 */
  value: string | null = null;
  paused: boolean = false;
  animationType: CYLBadgeAnimationType = CYLBadgeAnimationType.None;
  /** [EN] Bumped on each show, so the animation plays again. [CN] 每次显示时递增，使动画重新播放。 */
  generation: number = 0;
  backgroundColor?: ResourceColor;
  textColor?: ResourceColor;
  fontSize?: number;
  centerOffset?: CYLOffset;
  radius?: number;
  margin?: number;
  maximumBadgeNumber?: number;
  cornerRadius?: number;
  borderColor?: ResourceColor;
  borderWidth?: number;
  /**
   * [EN] How many times the animation plays: undefined uses the type's default (forever for Scale / Shake / Bounce /
   *      Breathe, once for the *Once types), -1 forever, n > 0 n times (cyl_shakeAnimationRepeatTimes,
   *      cyl_bounceAnimationRepeatTimes, CAAnimation+CYLBadgeExtention repeatCount).
   * [CN] 动画播放次数：undefined 用类型默认值（Scale/Shake/Bounce/Breathe 永久，*Once 一次），-1 永久，n > 0 播放 n 次。
   */
  repeatCount?: number;
  /**
   * [EN] An animation of CAAnimation+CYLBadgeExtention that no CYLBadgeAnimationType matches: 'rotation' (a full turn
   *      every 2 s, cyl_rotationAnimationWithDuration: around z) or 'flip' (half a turn around y). Wins over animationType.
   * [CN] 没有对应 CYLBadgeAnimationType 的 CAAnimation+CYLBadgeExtention 动画：'rotation'（每 2 秒绕 z 轴一圈）或 'flip'（绕 y 轴半圈）。优先于 animationType。
   */
  customAnimation?: string;
  /** [EN] cyl_badgeRespectsReduceMotion: no animation while the system reduces motion. [CN] 系统减少动态效果时不播放动画。 */
  respectsReduceMotion: boolean = false;
  /** [EN] Localized "new" / "NEW" (CYLLocalization). [CN] 本地化的 "new" / "NEW"。 */
  newText: string = 'new';
  newUppercaseText: string = 'NEW';

  /** [EN] -cyl_showBadge: a red dot. [CN] 显示红点。 */
  cyl_showBadge(): void {
    this.cyl_showBadgeValue('', this.animationType);
  }

  /** [EN] -cyl_showBadgeValue:animationType:; a number <= 0 clears the badge. [CN] 显示值；<= 0 的数字清除角标。 */
  cyl_showBadgeValue(value: string, animationType?: CYLBadgeAnimationType): void {
    const number = Number.parseInt(value, 10);
    if (`${number}` === value.trim() && number <= 0) {
      this.cyl_clearBadge();
      return;
    }
    this.value = value;
    this.animationType = animationType ?? this.animationType;
    this.generation += 1;
  }

  /** [EN] -cyl_showNewBadge: "new" (uppercase: "NEW"). [CN] 显示 "new"。 */
  cyl_showNewBadge(uppercase?: boolean): void {
    this.cyl_showBadgeValue(uppercase ? 'NEW' : 'new');
  }

  /** [EN] -cyl_clearBadge. [CN] 移除角标。 */
  cyl_clearBadge(): void {
    this.value = null;
    this.paused = false;
  }

  /** [EN] -cyl_pauseBadge: hidden, kept. [CN] 暂停：隐藏但保留。 */
  cyl_pauseBadge(): void {
    this.paused = true;
  }

  /** [EN] -cyl_resumeBadge. [CN] 恢复显示。 */
  cyl_resumeBadge(): void {
    this.paused = false;
  }

  cyl_isShowBadge(): boolean {
    return this.value !== null && !this.paused;
  }

  cyl_isPauseBadge(): boolean {
    return this.paused;
  }

  /** [EN] -cyl_resetBadgeAppearance: back to the global appearance. [CN] 恢复为全局外观。 */
  cyl_resetBadgeAppearance(): void {
    this.backgroundColor = undefined;
    this.textColor = undefined;
    this.fontSize = undefined;
    this.centerOffset = undefined;
    this.radius = undefined;
    this.margin = undefined;
    this.maximumBadgeNumber = undefined;
    this.cornerRadius = undefined;
    this.borderColor = undefined;
    this.borderWidth = undefined;
  }

  /** [EN] The shown text: null for a red dot (as CYLBadge.kt). [CN] 显示的文字：红点为 null。 */
  cyl_displayText(): string | null {
    const value = this.value;
    if (value === null || value.length === 0) {
      return null;
    }
    const number = Number.parseInt(value, 10);
    const maximum = this.cyl_maximum();
    if (`${number}` === value.trim() && number > maximum) {
      return `${maximum}+`;
    }
    if (value === 'new') {
      return this.newText;
    }
    if (value === 'NEW') {
      return this.newUppercaseText;
    }
    return value;
  }

  cyl_maximum(): number {
    return this.maximumBadgeNumber !== undefined ? Math.max(1, this.maximumBadgeNumber)
      : CYLBadgeAppearance.globalAppearance.maximumBadgeNumber;
  }
}

/**
 * [EN] CYLBadgeView: draws a CYLBadge at the top-right corner of its parent (center 2 vp right of the corner, as iOS),
 *      moved by centerOffset; plays its animation type (CYLBadgeView.play of CYLBadge.kt).
 * [CN] CYLBadgeView：在父视图右上角绘制 CYLBadge（中心位于右上角右侧 2 vp，与 iOS 相同），按 centerOffset 移动；播放其动画类型。
 */
@Component
export struct CYLBadgeView {
  @ObjectLink @Watch('cylPlay') badge: CYLBadge;
  /** [EN] The anchor's width (the icon), to find its right edge. [CN] 锚点（图标）宽度，用于定位其右边缘。 */
  anchorWidth: number = 26;
  @State private scaleValue: number = 1;
  @State private translateX: number = 0;
  @State private translateY: number = 0;
  @State private opacityValue: number = 1;
  @State private rotateX: number = 0;
  @State private rotateY: number = 0;
  @State private rotateZ: number = 0;
  private playedGeneration: number = -1;

  private appearance(): CYLBadgeAppearance {
    return CYLBadgeAppearance.globalAppearance;
  }

  cylPlay(): void {
    if (this.playedGeneration === this.badge.generation) {
      return;
    }
    this.playedGeneration = this.badge.generation;
    this.scaleValue = 1;
    this.translateX = 0;
    this.translateY = 0;
    this.opacityValue = 1;
    this.rotateX = 0;
    this.rotateY = 0;
    this.rotateZ = 0;
    const repeats = this.badge.repeatCount;
    // [EN] Alternate play counts each direction as one iteration. [CN] 往返播放时每个方向计一次。
    const forever = repeats !== undefined && repeats > 0 ? repeats * 2 : -1;
    const once = repeats === undefined ? 1 : (repeats > 0 ? repeats : -1);
    if (this.badge.customAnimation === 'rotation') {
      animateTo({ duration: 2000, iterations: once === 1 && repeats === undefined ? -1 : once, curve: Curve.Linear },
        () => { this.rotateZ = 360; });
      return;
    }
    if (this.badge.customAnimation === 'flip') {
      animateTo({ duration: 1000, iterations: repeats ?? 2 }, () => { this.rotateY = 180; });
      return;
    }
    switch (this.badge.animationType) {
      case CYLBadgeAnimationType.Scale:
        this.scaleValue = 1.4;
        animateTo({ duration: 1000, iterations: forever, playMode: PlayMode.Alternate }, () => { this.scaleValue = 0.6; });
        break;
      case CYLBadgeAnimationType.Shake:
        this.translateX = -6;
        animateTo({ duration: 125, iterations: forever, playMode: PlayMode.Alternate }, () => { this.translateX = 6; });
        break;
      case CYLBadgeAnimationType.Bounce:
        animateTo({ duration: 250, iterations: forever, playMode: PlayMode.Alternate }, () => { this.translateY = -8; });
        break;
      case CYLBadgeAnimationType.Breathe:
        animateTo({ duration: 600, iterations: forever, playMode: PlayMode.Alternate }, () => { this.opacityValue = 0.1; });
        break;
      case CYLBadgeAnimationType.LeftRightOnce:
        this.translateX = -10;
        animateTo({ duration: 400, iterations: once }, () => { this.translateX = 0; });
        break;
      case CYLBadgeAnimationType.RightLeftOnce:
        this.translateX = 10;
        animateTo({ duration: 400, iterations: once }, () => { this.translateX = 0; });
        break;
      case CYLBadgeAnimationType.FadeInOnce:
        this.opacityValue = 0;
        animateTo({ duration: 400, iterations: once }, () => { this.opacityValue = 1; });
        break;
      case CYLBadgeAnimationType.RollingOnce:
        this.rotateX = 90;
        animateTo({ duration: 400, iterations: once }, () => { this.rotateX = 0; });
        break;
      case CYLBadgeAnimationType.ScaleOnce:
        this.scaleValue = 0;
        animateTo({ duration: 300, iterations: once, curve: curves.springMotion() }, () => { this.scaleValue = 1; });
        break;
      default:
        break;
    }
  }

  build() {
    if (this.badge.value !== null) {
      Stack() {
        if (this.badge.cyl_displayText() === null) {
          Circle()
            .width((this.badge.radius ?? this.appearance().radius) * 2)
            .height((this.badge.radius ?? this.appearance().radius) * 2)
            .fill(this.badge.backgroundColor ?? this.appearance().backgroundColor)
        } else {
          Text(this.badge.cyl_displayText())
            .fontSize(this.badge.fontSize ?? this.appearance().fontSize)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.badge.textColor ?? this.appearance().textColor)
            .textAlign(TextAlign.Center)
            .padding({ left: (this.badge.margin ?? this.appearance().margin) / 2, right: (this.badge.margin ?? this.appearance().margin) / 2 })
            .height((this.badge.fontSize ?? this.appearance().fontSize) * 1.2 + (this.badge.margin ?? this.appearance().margin))
            .constraintSize({ minWidth: (this.badge.fontSize ?? this.appearance().fontSize) * 1.2 + (this.badge.margin ?? this.appearance().margin) })
            .backgroundColor(this.badge.backgroundColor ?? this.appearance().backgroundColor)
            .borderRadius((this.badge.cornerRadius ?? this.appearance().cornerRadius) > 0
              ? (this.badge.cornerRadius ?? this.appearance().cornerRadius) : 100)
            .border({ width: this.badge.borderWidth ?? this.appearance().borderWidth,
              color: this.badge.borderColor ?? this.appearance().borderColor ?? Color.Transparent })
        }
      }
      .markAnchor({ x: '50%', y: '50%' })
      .position({ x: this.anchorWidth + 2 + (this.badge.centerOffset ?? this.appearance().centerOffset).horizontal,
        y: (this.badge.centerOffset ?? this.appearance().centerOffset).vertical })
      .visibility(this.badge.paused ? Visibility.Hidden : Visibility.Visible)
      .scale({ x: this.scaleValue, y: this.scaleValue })
      .translate({ x: this.translateX, y: this.translateY })
      .opacity(this.opacityValue)
      .rotate({ x: 1, y: 0, z: 0, angle: this.rotateX })
      .rotate({ x: 0, y: this.rotateY !== 0 ? 1 : 0, z: this.rotateZ !== 0 ? 1 : 0,
        angle: this.rotateY !== 0 ? this.rotateY : this.rotateZ })
      .onAppear(() => this.cylPlay())
      .onAttach(() => this.cylPlay())
      .id('cyl-badge')
    }
  }

  aboutToReuse(): void {
    this.cylPlay();
  }
}
