import BuildProfile from '../../../BuildProfile';
import { curves } from '@kit.ArkUI';
import { BadgeEvents } from './CYLBadgeEvents';

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
 *      (-showBadge, -showBadgeValue:animationType:, -clearBadge, -pauseBadge, -resumeBadge, ...).
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
   *      Breathe, once for the *Once types), -1 forever, n > 0 n times (shakeAnimationRepeatTimes,
   *      bounceAnimationRepeatTimes, CAAnimation+CYLBadgeExtention repeatCount).
   * [CN] 动画播放次数：undefined 用类型默认值（Scale/Shake/Bounce/Breathe 永久，*Once 一次），-1 永久，n > 0 播放 n 次。
   */
  repeatCount?: number;
  /**
   * [EN] An animation of CAAnimation+CYLBadgeExtention that no CYLBadgeAnimationType matches: 'rotation' (a full turn
   *      every 2 s, rotationAnimationWithDuration: around z) or 'flip' (half a turn around y). Wins over animationType.
   * [CN] 没有对应 CYLBadgeAnimationType 的 CAAnimation+CYLBadgeExtention 动画：'rotation'（每 2 秒绕 z 轴一圈）或 'flip'（绕 y 轴半圈）。优先于 animationType。
   */
  customAnimation?: string;
  /** [EN] badgeRespectsReduceMotion: no animation while the system reduces motion. [CN] 系统减少动态效果时不播放动画。 */
  respectsReduceMotion: boolean = false;
  /** [EN] Localized "new" / "NEW" (CYLLocalization). [CN] 本地化的 "new" / "NEW"。 */
  newText: string = 'new';
  newUppercaseText: string = 'NEW';

  /**
   * [EN] Where badge events go: set it to `(name, info) => controller.registry.postLifecycleEvent(name, info)` and the
   *      badge posts `cyl.badge.didShow` / `cyl.badge.didClear` (BadgeEvents, CYLBadgeEvents.ts).
   * [CN] 角标事件的去向：设置后角标会发出 `cyl.badge.didShow` / `cyl.badge.didClear`（BadgeEvents，见 CYLBadgeEvents.ts）。
   */
  eventPoster?: (name: string, info: Record<string, Object>) => void;

  /** [EN] -showBadge: a red dot. [CN] 显示红点。 */
  showBadge(): void {
    this.showBadgeValue('', this.animationType);
  }

  /** [EN] -showBadgeValue:animationType:; a number <= 0 clears the badge. [CN] 显示值；<= 0 的数字清除角标。 */
  showBadgeValue(value: string, animationType?: CYLBadgeAnimationType): void {
    const number = Number.parseInt(value, 10);
    if (`${number}` === value.trim() && number <= 0) {
      this.clearBadge();
      return;
    }
    this.value = value;
    this.animationType = animationType ?? this.animationType;
    this.generation += 1;
    // [EN] ArkTS: a typed record, not an object literal. [CN] ArkTS：使用带类型的 Record，而不是对象字面量。
    const info: Record<string, Object> = {};
    info['value'] = value;
    info['animationType'] = this.animationType;
    this.eventPoster?.(BadgeEvents.didShow, info);
  }

  /** [EN] -showNewBadge: "new" (uppercase: "NEW"). [CN] 显示 "new"。 */
  showNewBadge(uppercase?: boolean): void {
    this.showBadgeValue(uppercase ? 'NEW' : 'new');
  }

  /** [EN] -clearBadge. [CN] 移除角标。 */
  clearBadge(): void {
    const hadBadge: boolean = this.value !== null;
    this.value = null;
    this.paused = false;
    if (hadBadge) {
      this.eventPoster?.(BadgeEvents.didClear, {});
    }
  }

  /** [EN] -pauseBadge: hidden, kept. [CN] 暂停：隐藏但保留。 */
  pauseBadge(): void {
    this.paused = true;
  }

  /** [EN] -resumeBadge. [CN] 恢复显示。 */
  resumeBadge(): void {
    this.paused = false;
  }

  isShowBadge(): boolean {
    return this.value !== null && !this.paused;
  }

  isPauseBadge(): boolean {
    return this.paused;
  }

  /** [EN] -resetBadgeAppearance: back to the global appearance. [CN] 恢复为全局外观。 */
  resetBadgeAppearance(): void {
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
  displayText(): string | null {
    const value = this.value;
    if (value === null || value.length === 0) {
      return null;
    }
    const number = Number.parseInt(value, 10);
    const maximum = this.maximumNumber();
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

  maximumNumber(): number {
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
    // [EN] Reset inside a zero-length animation: it also stops a running infinite animation (e.g. Bounce on "100"). A plain
    //      assignment left that animation driving the transform, so the new badge (the dot after the tab was selected) was
    //      drawn about 13 vp below its place.
    // [CN] 在零时长动画中重置：同时停止正在运行的无限动画（如 "100" 的 Bounce）。直接赋值时那个动画仍在驱动变换，新的角标（选中 Tab
    //      后的红点）被画在原位下方约 13 vp 处。
    this.getUIContext().animateTo({ duration: 0 }, () => {
      this.scaleValue = 1;
      this.translateX = 0;
      this.translateY = 0;
      this.opacityValue = 1;
      this.rotateX = 0;
      this.rotateY = 0;
      this.rotateZ = 0;
    });
    // [EN] Badge debugging build option (docs/Badge-Debugging.md, cyltabbar/build-profile.json5): no badge animation, so a
    //      screenshot shows the badge at its laid-out place.
    // [CN] 角标调试编译选项（docs/Badge-Debugging.md，cyltabbar/build-profile.json5）：不播放角标动画，截图中的角标就在布局位置。
    if (BuildProfile.CYL_BADGE_ANIMATION_DISABLED) {
      return;
    }
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
        const scaleGeneration = this.badge.generation;
        // [EN] Starts from the resting size (1), grows to 1.4, then breathes 1.4 <-> 0.6 (iOS's scale animation). Setting
        //      1.4 first left the badge stuck large when the animation was cut off (the Liquid Glass bar re-lays its
        //      items out as its capsule moves): a cut-off animation now ends near 1. [CN] 从 1 开始放大到 1.4 再往返缩放；
        //      之前先设为 1.4，动画被打断时角标停在放大状态（液态玻璃）。
        animateTo({
          duration: 500, curve: Curve.EaseOut, onFinish: () => {
            // [EN] Only when this badge has not changed meanwhile (a new value plays its own animation).
            // [CN] 仅当期间角标未变化时（新的值会播放自己的动画）。
            if (this.playedGeneration === scaleGeneration && this.badge.animationType === CYLBadgeAnimationType.Scale) {
              animateTo({ duration: 1000, iterations: forever, playMode: PlayMode.Alternate }, () => { this.scaleValue = 0.6; });
            }
          }
        }, () => { this.scaleValue = 1.4; });
        break;
      case CYLBadgeAnimationType.Shake:
        // [EN] As iOS (shakeAnimationRepeatTimes, translation.x): 0, -w/4, 0, +w/4, 0 in 1 s, around the badge's place.
        // [CN] 与 iOS 相同（translation.x）：1 秒内 0、-w/4、0、+w/4、0，围绕角标原位。
        this.cylPlayAround(true, this.cylBadgeWidth() / 4, repeats);
        break;
      case CYLBadgeAnimationType.Bounce:
        // [EN] As iOS (bounceAnimationRepeatTimes, translation.y): 0, -h/4, 0, +h/4, 0 in 1 s, around the badge's place.
        //      It used to go only up, 8 vp every 250 ms, so the badge (e.g. "100" on Messages) sat about 4 vp too high.
        // [CN] 与 iOS 相同（translation.y）：1 秒内 0、-h/4、0、+h/4、0，围绕角标原位。此前只向上 8 vp、每 250 毫秒一次，
        //      角标（如「消息」上的 "100"）平均高出约 4 vp。
        this.cylPlayAround(false, this.cylBadgeHeight() / 4, repeats);
        break;
      case CYLBadgeAnimationType.Breathe:
        // [EN] As iOS (opacityForeverAnimation 1.4 s): opacity 1 to 0.1 and back, 1.4 s each way, linear.
        // [CN] 与 iOS 相同：透明度 1 到 0.1 再回到 1，每个方向 1.4 秒，线性。
        animateTo({ duration: 1400, iterations: forever, playMode: PlayMode.Alternate, curve: Curve.Linear },
          () => { this.opacityValue = 0.1; });
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

  /** [EN] The badge's height: a dot's diameter, or a text badge's height. [CN] 角标高度：红点直径或文字角标高度。 */
  private cylBadgeHeight(): number {
    if (this.badge.displayText() === null) {
      return (this.badge.radius ?? this.appearance().radius) * 2;
    }
    return (this.badge.fontSize ?? this.appearance().fontSize) * 1.2 + (this.badge.margin ?? this.appearance().margin);
  }

  /** [EN] The badge's width: a dot's diameter, or a text badge's width. [CN] 角标宽度：红点直径或文字角标宽度。 */
  private cylBadgeWidth(): number {
    return this.badge.displayText() === null ? (this.badge.radius ?? this.appearance().radius) * 2 : this.cylTextBadgeWidth();
  }

  /**
   * [EN] iOS translationAnimation: keyframes 0, -offset, 0, +offset, 0 over 1 s (250 ms each), relative to the badge's place;
   *      forever unless repeatCount is set. [CN] iOS 的 translationAnimation：1 秒内关键帧 0、-offset、0、+offset、0（各 250 毫秒），
   *      相对角标原位；未设置 repeatCount 时无限循环。
   */
  private cylPlayAround(horizontal: boolean, offset: number, repeats: number | undefined): void {
    const set = (value: number): void => {
      if (horizontal) {
        this.translateX = value;
      } else {
        this.translateY = value;
      }
    };
    this.getUIContext().keyframeAnimateTo({ iterations: repeats !== undefined && repeats > 0 ? repeats : -1 }, [
      { duration: 250, curve: Curve.Linear, event: () => set(-offset) },
      { duration: 250, curve: Curve.Linear, event: () => set(0) },
      { duration: 250, curve: Curve.Linear, event: () => set(offset) },
      { duration: 250, curve: Curve.Linear, event: () => set(0) },
    ]);
  }

  /**
   * [EN] The width of a text badge, as Android CYLBadge.onMeasure and iOS -adjustLabelWidth: the measured text width
   *      plus the margin, at least the badge height (a circle for one digit). Never fixed, so "NEW" stays on one line.
   * [CN] 文字角标宽度：测量的文字宽度加边距，至少为角标高度（一位数字为圆形）。不写死，"NEW" 保持单行。
   */
  cylTextBadgeWidth(): number {
    const fontSize = this.badge.fontSize ?? this.appearance().fontSize;
    const margin = this.badge.margin ?? this.appearance().margin;
    const height = fontSize * 1.2 + margin;
    const text = this.badge.displayText() ?? '';
    let textWidth = text.length * fontSize * 0.62;
    try {
      const px = this.getUIContext().getMeasureUtils().measureText({
        textContent: text, fontSize: fontSize, fontWeight: FontWeight.Bold,
      });
      textWidth = this.getUIContext().px2vp(px);
    } catch (e) {
      // [EN] Estimate when measuring is not available. [CN] 无法测量时估算。
    }
    // [EN] The border is drawn inside the width, so it is added on both sides or a bordered badge clips its text.
    // [CN] 描边绘制在宽度之内，因此两侧都要加上，否则带描边的角标会裁切文字。
    const border = this.badge.borderWidth ?? this.appearance().borderWidth;
    return Math.max(height, Math.ceil(textWidth) + margin + border * 2);
  }

  build() {
    if (this.badge.value !== null) {
      Stack() {
        if (this.badge.displayText() === null) {
          Circle()
            .width((this.badge.radius ?? this.appearance().radius) * 2)
            .height((this.badge.radius ?? this.appearance().radius) * 2)
            .fill(this.badge.backgroundColor ?? this.appearance().backgroundColor)
        } else {
          Text(this.badge.displayText())
            .fontSize(this.badge.fontSize ?? this.appearance().fontSize)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.badge.textColor ?? this.appearance().textColor)
            .textAlign(TextAlign.Center)
            // [EN] One line: the badge grows with its text (iOS sizeToFit, Android wrap_content), never wraps (issue list #1).
            // [CN] 单行：角标随文字变宽，不换行（问题 #1）。
            .maxLines(1)
            .padding({ left: (this.badge.margin ?? this.appearance().margin) / 2, right: (this.badge.margin ?? this.appearance().margin) / 2 })
            .height((this.badge.fontSize ?? this.appearance().fontSize) * 1.2 + (this.badge.margin ?? this.appearance().margin))
            .width(this.cylTextBadgeWidth())
            .backgroundColor(this.badge.backgroundColor ?? this.appearance().backgroundColor)
            .borderRadius((this.badge.cornerRadius ?? this.appearance().cornerRadius) > 0
              ? (this.badge.cornerRadius ?? this.appearance().cornerRadius) : 100)
            .border({ width: this.badge.borderWidth ?? this.appearance().borderWidth,
              color: this.badge.borderColor ?? this.appearance().borderColor ?? Color.Transparent })
        }
      }
      // [EN] Every badge (dot, number, text) is centred 2 vp right of the icon's top-right corner, plus centerOffset, as iOS
      //      (center 2 pt right of the host's right edge) and Android (badgeOrigin: anchorRight + 2 dp - width / 2):
      //      a wide badge grows to both sides of that point (issue list #25).
      // [CN] 所有角标（红点、数字、文字）的中心都在图标右上角右侧 2 vp 处，再加 centerOffset，与 iOS（宿主右边缘右侧 2 pt）和
      //      Android（badgeOrigin：anchorRight + 2 dp - 宽度 / 2）相同：宽角标向两侧延伸（问题 #25）。
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
      // [EN] Read as part of its host (badgeAccessibilityText), not on its own. [CN] 作为宿主的一部分读出，不单独读出。
      .accessibilityLevel('no')
      .onAppear(() => this.cylPlay())
      .onAttach(() => this.cylPlay())
      .id('cyl-badge')
    }
  }

  aboutToReuse(): void {
    this.cylPlay();
  }
}
