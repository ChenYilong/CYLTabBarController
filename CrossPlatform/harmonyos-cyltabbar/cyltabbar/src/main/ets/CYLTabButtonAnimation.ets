/**
 * [EN] Tap animations of tab buttons and the plus button (CYLTabButtonAnimation.h, issue #535), ported from
 *      CYLTabButtonAnimation.swift. ArkUI has no UIControl / UIView / UILabel: each method gets a CYLTabButtonView, the
 *      animatable properties of one button (icon scale, rotation, flip, vertical offset, title opacity and scale, a frame
 *      image, fireworks) that CYLTabBarController draws. Set `CYLTabBarController.tabButtonAnimation` to use one.
 * [CN] Tab 按钮与 PlusButton 的点击动画（issue #535），从 CYLTabButtonAnimation.swift 迁移。ArkUI 没有 UIControl / UIView / UILabel：
 *      每个方法收到一个 CYLTabButtonView，即一个按钮可动画的属性（图标缩放、旋转、翻转、纵向偏移、标题透明度与缩放、帧图片、烟花），
 *      由 CYLTabBarController 绘制。设置 `CYLTabBarController.tabButtonAnimation` 即可使用。
 */

/** [EN] The animatable properties of a button. [CN] 按钮可动画的属性。 */
export enum CYLTabButtonProperty {
  IconScale = 'iconScale',
  /** [EN] Degrees around z. [CN] 绕 z 轴的角度。 */
  IconAngle = 'iconAngle',
  /** [EN] Degrees around y (flip). [CN] 绕 y 轴的角度（翻转）。 */
  IconFlipY = 'iconFlipY',
  /** [EN] Degrees around x (flip from top / bottom). [CN] 绕 x 轴的角度。 */
  IconFlipX = 'iconFlipX',
  IconOffsetY = 'iconOffsetY',
  TitleOpacity = 'titleOpacity',
  TitleScale = 'titleScale',
  /** [EN] The badge's scale. [CN] 角标缩放。 */
  BadgeScale = 'badgeScale',
}

/**
 * [EN] One button as the animations see it (the button, iconView and titleLabel / badgeView arguments of iOS).
 * [CN] 动画看到的一个按钮（对应 iOS 的 button、iconView 与 titleLabel / badgeView 参数）。
 */
export interface CYLTabButtonView {
  /** [EN] The tab index (CYLPlusButtonPageIndex for the plus button). [CN] Tab 下标（PlusButton 为 CYLPlusButtonPageIndex）。 */
  readonly index: number;
  /** [EN] Whether the button has a title. [CN] 是否有标题。 */
  readonly hasTitle: boolean;
  /** [EN] The current value of a property. [CN] 属性当前值。 */
  valueOf(property: CYLTabButtonProperty): number;
  /** [EN] Sets a property, animated over `duration` ms (0: at once). [CN] 设置属性，在 `duration` 毫秒内动画（0 为立即）。 */
  setValue(property: CYLTabButtonProperty, value: number, duration?: number, curve?: Curve): void;
  /** [EN] Plays keyframes evenly or at `keyTimes` (0...1) over `duration` ms; values[0] is set at once. [CN] 关键帧动画。 */
  keyframes(property: CYLTabButtonProperty, values: number[], duration: number, keyTimes?: number[]): void;
  /** [EN] Shows `image` instead of the icon (undefined: the icon again). [CN] 用 `image` 替代图标（undefined 恢复图标）。 */
  setFrameImage(image: ResourceStr | undefined): void;
  /** [EN] Fireworks around the icon; `image` is the particle (default: a dot in the tint color). [CN] 图标周围的烟花。 */
  playFireworks(image?: ResourceStr): void;
}

/** @internal [EN] The CYLTabButtonView CYLTabBarController hands to the animations. [CN] 控制器传给动画的按钮视图。 */
export class CYLTabButtonViewImpl implements CYLTabButtonView {
  readonly index: number;
  readonly hasTitle: boolean;
  private readonly valueFn: (property: CYLTabButtonProperty) => number;
  private readonly setFn: (property: CYLTabButtonProperty, value: number, duration?: number, curve?: Curve) => void;
  private readonly keyframesFn: (property: CYLTabButtonProperty, values: number[], duration: number, keyTimes?: number[]) => void;
  private readonly frameFn: (image: ResourceStr | undefined) => void;
  private readonly fireworksFn: (image?: ResourceStr) => void;

  constructor(index: number, hasTitle: boolean, valueFn: (property: CYLTabButtonProperty) => number,
    setFn: (property: CYLTabButtonProperty, value: number, duration?: number, curve?: Curve) => void,
    keyframesFn: (property: CYLTabButtonProperty, values: number[], duration: number, keyTimes?: number[]) => void,
    frameFn: (image: ResourceStr | undefined) => void, fireworksFn: (image?: ResourceStr) => void) {
    this.index = index;
    this.hasTitle = hasTitle;
    this.valueFn = valueFn;
    this.setFn = setFn;
    this.keyframesFn = keyframesFn;
    this.frameFn = frameFn;
    this.fireworksFn = fireworksFn;
  }

  valueOf(property: CYLTabButtonProperty): number {
    return this.valueFn(property);
  }

  setValue(property: CYLTabButtonProperty, value: number, duration?: number, curve?: Curve): void {
    this.setFn(property, value, duration, curve);
  }

  keyframes(property: CYLTabButtonProperty, values: number[], duration: number, keyTimes?: number[]): void {
    this.keyframesFn(property, values, duration, keyTimes);
  }

  setFrameImage(image: ResourceStr | undefined): void {
    this.frameFn(image);
  }

  playFireworks(image?: ResourceStr): void {
    this.fireworksFn(image);
  }
}

/** [EN] CYLTabButtonAnimationBlock. [CN] 动画闭包。 */
export type CYLTabButtonAnimationBlock = (button: CYLTabButtonView) => void;
/** [EN] CYLTabButtonBadgeAnimationBlock. [CN] 角标动画闭包。 */
export type CYLTabButtonBadgeAnimationBlock = (button: CYLTabButtonView) => void;

const CYLTabButtonAnimationDuration: number = 500;

/**
 * [EN] The protocol CYLTabButtonAnimation as a base class: override the methods you need (each does nothing here).
 *      The cylPlay… names (without the underscore) call the cyl_play… ones.
 * [CN] 协议 CYLTabButtonAnimation 的基类：覆盖需要的方法（这里均为空实现）。cylPlay…（无下划线）调用 cyl_play…。
 */
export class CYLTabButtonAnimation {
  /** [EN] cyl_fromLeft: set before select; the button selected before is on the left. [CN] 之前选中的按钮在左侧。 */
  cyl_fromLeft: boolean = false;
  /** [EN] cyl_toRight: set before deselect; the button selected next is on the right. [CN] 之后选中的按钮在右侧。 */
  cyl_toRight: boolean = false;

  cyl_playSelectAnimationWithTabButton(button: CYLTabButtonView): void {
  }

  cyl_playDeselectAnimationWithTabButton(button: CYLTabButtonView): void {
  }

  /** [EN] Not overridden: the select animation plays again. [CN] 未覆盖时重新播放选中动画。 */
  cyl_playReselectAnimationWithTabButton(button: CYLTabButtonView): void {
    this.cyl_playSelectAnimationWithTabButton(button);
  }

  cyl_playHighlightAnimationWithTabButton(button: CYLTabButtonView): void {
  }

  cyl_playDehighlightAnimationWithTabButton(button: CYLTabButtonView): void {
  }

  /** [EN] A badge appeared or changed. [CN] 角标出现或变化。 */
  cyl_playBadgeChangedAnimationWithTabButton(button: CYLTabButtonView): void {
  }

  /** [EN] Undoes what the animation left (held frame, hidden title, moved icon). [CN] 撤销动画留下的状态。 */
  cyl_resetTabButton(button: CYLTabButtonView): void {
    button.setValue(CYLTabButtonProperty.IconScale, 1);
    button.setValue(CYLTabButtonProperty.IconAngle, 0);
    button.setValue(CYLTabButtonProperty.IconFlipX, 0);
    button.setValue(CYLTabButtonProperty.IconFlipY, 0);
    button.setValue(CYLTabButtonProperty.IconOffsetY, 0);
    button.setValue(CYLTabButtonProperty.TitleOpacity, 1);
    button.setValue(CYLTabButtonProperty.TitleScale, 1);
    button.setFrameImage(undefined);
  }

  cylPlaySelectAnimationWithTabButton(button: CYLTabButtonView): void {
    this.cyl_playSelectAnimationWithTabButton(button);
  }

  cylPlayDeselectAnimationWithTabButton(button: CYLTabButtonView): void {
    this.cyl_playDeselectAnimationWithTabButton(button);
  }

  cylPlayReselectAnimationWithTabButton(button: CYLTabButtonView): void {
    this.cyl_playReselectAnimationWithTabButton(button);
  }

  cylPlayHighlightAnimationWithTabButton(button: CYLTabButtonView): void {
    this.cyl_playHighlightAnimationWithTabButton(button);
  }

  cylPlayDehighlightAnimationWithTabButton(button: CYLTabButtonView): void {
    this.cyl_playDehighlightAnimationWithTabButton(button);
  }

  cylPlayBadgeChangedAnimationWithTabButton(button: CYLTabButtonView): void {
    this.cyl_playBadgeChangedAnimationWithTabButton(button);
  }
}

/** [EN] Scale up then down: 1.0 → 1.5 → 0.8 → 1.0. [CN] 先放大再缩小。 */
export class CYLTabButtonScaleAnimation extends CYLTabButtonAnimation {
  /** [EN] Milliseconds, default 500. [CN] 时长（毫秒），默认 500。 */
  duration: number = CYLTabButtonAnimationDuration;

  cyl_playSelectAnimationWithTabButton(button: CYLTabButtonView): void {
    button.keyframes(CYLTabButtonProperty.IconScale, [1.0, 1.5, 0.8, 1.0], this.duration, [0, 1 / 3, 2 / 3, 1]);
  }
}

/** [EN] The icon grows from small with a slight overshoot: 0.1 → 1.2 → 0.9 → 1.0. [CN] 图片从小放大。 */
export class CYLTabButtonZoomInAnimation extends CYLTabButtonAnimation {
  duration: number = CYLTabButtonAnimationDuration;

  cyl_playSelectAnimationWithTabButton(button: CYLTabButtonView): void {
    button.keyframes(CYLTabButtonProperty.IconScale, [0.1, 1.2, 0.9, 1.0], this.duration, [0, 0.5, 0.75, 1]);
  }
}

/** [EN] Elastic bounce of the icon, optionally with fireworks. [CN] 图标弹性弹跳，可选烟花。 */
export class CYLTabButtonBounceAnimation extends CYLTabButtonAnimation {
  playsFireworks: boolean = false;
  /** [EN] The particle; undefined: a dot in the tint color. [CN] 烟花粒子；undefined 为主题色圆点。 */
  fireworksImage?: ResourceStr;

  cyl_playSelectAnimationWithTabButton(button: CYLTabButtonView): void {
    button.keyframes(CYLTabButtonProperty.IconScale, [1.0, 0.85, 1.15, 0.95, 1.02, 1.0], CYLTabButtonAnimationDuration);
    if (this.playsFireworks) {
      button.playFireworks(this.fireworksImage);
    }
  }
}

/** [EN] One full turn of the icon. [CN] 图标旋转一圈。 */
export class CYLTabButtonRotationAnimation extends CYLTabButtonAnimation {
  cyl_playSelectAnimationWithTabButton(button: CYLTabButtonView): void {
    button.keyframes(CYLTabButtonProperty.IconAngle, [0, -360], CYLTabButtonAnimationDuration);
  }
}

/** [EN] The icon moves down while the title floats up and fades out; deselecting brings them back. [CN] 图标下移、标题上浮淡出。 */
export class CYLTabButtonFumeAnimation extends CYLTabButtonAnimation {
  cyl_playSelectAnimationWithTabButton(button: CYLTabButtonView): void {
    if (!button.hasTitle) {
      return;
    }
    button.keyframes(CYLTabButtonProperty.IconOffsetY, [0, 8], CYLTabButtonAnimationDuration / 2);
    button.keyframes(CYLTabButtonProperty.TitleScale, [1.0, 2.0], CYLTabButtonAnimationDuration);
    button.keyframes(CYLTabButtonProperty.TitleOpacity, [1.0, 0.0], CYLTabButtonAnimationDuration);
  }

  cyl_playDeselectAnimationWithTabButton(button: CYLTabButtonView): void {
    button.keyframes(CYLTabButtonProperty.IconOffsetY, [button.valueOf(CYLTabButtonProperty.IconOffsetY), 0], CYLTabButtonAnimationDuration / 2);
    button.setValue(CYLTabButtonProperty.TitleScale, 1);
    button.keyframes(CYLTabButtonProperty.TitleOpacity, [0.0, 1.0], CYLTabButtonAnimationDuration);
  }
}

/** [EN] The icon shrinks while pressed and springs back; no select animation. [CN] 按下时图标缩小、松手回弹；选中时不播放。 */
export class CYLTabButtonPressAnimation extends CYLTabButtonAnimation {
  /** [EN] The scale while pressed, default 0.85. [CN] 按下时的缩放，默认 0.85。 */
  pressedScale: number = 0.85;

  cyl_playSelectAnimationWithTabButton(button: CYLTabButtonView): void {
  }

  cyl_playReselectAnimationWithTabButton(button: CYLTabButtonView): void {
  }

  cyl_playHighlightAnimationWithTabButton(button: CYLTabButtonView): void {
    button.setValue(CYLTabButtonProperty.IconScale, this.pressedScale, 100, Curve.EaseOut);
  }

  cyl_playDehighlightAnimationWithTabButton(button: CYLTabButtonView): void {
    button.setValue(CYLTabButtonProperty.IconScale, 1, 350, Curve.Friction);
  }
}

/** [EN] An animation made of closures; a closure left undefined plays nothing. [CN] 由闭包组成的动画；未设置的闭包不播放。 */
export class CYLTabButtonBlockAnimation extends CYLTabButtonAnimation {
  selectAnimation?: CYLTabButtonAnimationBlock;
  deselectAnimation?: CYLTabButtonAnimationBlock;
  reselectAnimation?: CYLTabButtonAnimationBlock;
  highlightAnimation?: CYLTabButtonAnimationBlock;
  dehighlightAnimation?: CYLTabButtonAnimationBlock;
  badgeChangedAnimation?: CYLTabButtonBadgeAnimationBlock;

  cyl_playSelectAnimationWithTabButton(button: CYLTabButtonView): void {
    this.selectAnimation?.(button);
  }

  cyl_playDeselectAnimationWithTabButton(button: CYLTabButtonView): void {
    this.deselectAnimation?.(button);
  }

  /** [EN] No reselect closure: the select closure, as an unimplemented iOS method. [CN] 没有 reselect 闭包时播放 select 闭包。 */
  cyl_playReselectAnimationWithTabButton(button: CYLTabButtonView): void {
    (this.reselectAnimation ?? this.selectAnimation)?.(button);
  }

  cyl_playHighlightAnimationWithTabButton(button: CYLTabButtonView): void {
    this.highlightAnimation?.(button);
  }

  cyl_playDehighlightAnimationWithTabButton(button: CYLTabButtonView): void {
    this.dehighlightAnimation?.(button);
  }

  cyl_playBadgeChangedAnimationWithTabButton(button: CYLTabButtonView): void {
    this.badgeChangedAnimation?.(button);
  }
}

/**
 * [EN] Flips the icon. `direction` 1–6: flip from left, from right, from top, from bottom, curl up, curl down (curls are
 *      drawn as flips around x on HarmonyOS).
 * [CN] 翻转图标。`direction` 1–6：从左、从右、从上、从下翻转，向上、向下卷页（鸿蒙上卷页以绕 x 轴翻转绘制）。
 */
export class CYLTabButtonFlipAnimation extends CYLTabButtonAnimation {
  direction: number = 1;
  disablesDeselectAnimation: boolean = false;

  private play(button: CYLTabButtonView, direction: number): void {
    const clamped = Math.min(6, Math.max(1, Math.round(direction)));
    const sign = clamped % 2 === 1 ? 1 : -1;
    const property = clamped <= 2 ? CYLTabButtonProperty.IconFlipY : CYLTabButtonProperty.IconFlipX;
    button.keyframes(property, [0, 180 * sign, 360 * sign], CYLTabButtonAnimationDuration);
  }

  cyl_playSelectAnimationWithTabButton(button: CYLTabButtonView): void {
    this.play(button, this.direction);
  }

  cyl_playDeselectAnimationWithTabButton(button: CYLTabButtonView): void {
    if (!this.disablesDeselectAnimation) {
      const clamped = Math.min(6, Math.max(1, Math.round(this.direction)));
      this.play(button, clamped % 2 === 1 ? clamped + 1 : clamped - 1);
    }
  }
}

/**
 * [EN] Plays `images` as frames on the icon and keeps the last one while selected; deselecting plays them in reverse and
 *      shows the icon again.
 * [CN] 在图标上逐帧播放 `images`，选中期间保持最后一帧；取消选中时倒序播放并恢复图标。
 */
export class CYLTabButtonFrameAnimation extends CYLTabButtonAnimation {
  images?: ResourceStr[];
  playsFireworks: boolean = false;
  fireworksImage?: ResourceStr;
  private timers: Map<number, number> = new Map<number, number>();

  private playFrames(button: CYLTabButtonView, frames: ResourceStr[], keepsLast: boolean): void {
    const running = this.timers.get(button.index);
    if (running !== undefined) {
      clearInterval(running);
    }
    if (frames.length === 0) {
      return;
    }
    const step = CYLTabButtonAnimationDuration / frames.length;
    let frame = 0;
    button.setFrameImage(frames[0]);
    const timer = setInterval(() => {
      frame++;
      if (frame < frames.length) {
        button.setFrameImage(frames[frame]);
        return;
      }
      clearInterval(timer);
      this.timers.delete(button.index);
      if (!keepsLast) {
        button.setFrameImage(undefined);
      }
    }, step);
    this.timers.set(button.index, timer);
  }

  cyl_playSelectAnimationWithTabButton(button: CYLTabButtonView): void {
    this.playFrames(button, this.images ?? [], true);
    if (this.playsFireworks) {
      button.playFireworks(this.fireworksImage);
    }
  }

  cyl_playDeselectAnimationWithTabButton(button: CYLTabButtonView): void {
    this.playFrames(button, (this.images ?? []).slice().reverse(), false);
  }

  cyl_resetTabButton(button: CYLTabButtonView): void {
    const running = this.timers.get(button.index);
    if (running !== undefined) {
      clearInterval(running);
      this.timers.delete(button.index);
    }
    super.cyl_resetTabButton(button);
  }
}
