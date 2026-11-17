package com.cyl.animateditem;

/**
 * [EN] The animation file keys the animation engine reads (`CYLAnimatedItem`). `CYLConstants` keeps the same fields,
 *      with the same values, for the tab bar; both can be used.
 * [CN] 动画引擎（`CYLAnimatedItem`）读取的动画文件 key。`CYLConstants` 为 TabBar 保留同名、同值的字段，两者均可使用。
 */
public final class CYLTabBarItemAnimationKeys {
    private CYLTabBarItemAnimationKeys() {}

    public static final String CYLTabBarAnimationDarkColors = "CYLTabBarAnimationDarkColors";
    public static final String CYLTabBarAnimationDarkFilePath = "CYLTabBarAnimationDarkFilePath";
    public static final String CYLTabBarAnimationDarkURL = "CYLTabBarAnimationDarkURL";
    public static final String CYLTabBarAnimationFilePath = "CYLTabBarAnimationFilePath";
    public static final String CYLTabBarAnimationOptionRiveActiveDuration = "duration";
    public static final String CYLTabBarAnimationOptionRiveActiveProperty = "active";
    public static final String CYLTabBarAnimationOptionRiveAnimation = "animation";
    public static final String CYLTabBarAnimationOptionRiveArtboard = "artboard";
    public static final String CYLTabBarAnimationOptionRiveInput = "input";
    /**
     * [EN] A state machine number input set to the next of `values` on each play (house.riv: "Rooms").
     * [CN] 每次播放设为 `values` 中下一个值的状态机数字输入（house.riv："Rooms"）。
     */
    public static final String CYLTabBarAnimationOptionRiveNumberInput = "numberInput";
    /**
     * [EN] The values the number input steps through, "3,4,5,6", cycling; without it, +1.
     * [CN] 数字输入依次使用的值，"3,4,5,6"，循环；没有时 +1。
     */
    public static final String CYLTabBarAnimationOptionRiveNumberValues = "values";
    public static final String CYLTabBarAnimationOptionRiveStateMachine = "stateMachine";
    public static final String CYLTabBarAnimationOptionRiveTriggerInput = "triggerInput";
    public static final String CYLTabBarAnimationOptionRiveTriggerProperty = "trigger";
    /**
     * [EN] Option of a tab's animation (`CYLTabBarAnimationOptions` / the URL fragment): a one-color tint drawn over the
     *      animation, like a template image. "title" follows the tab's title color (normal / selected); a color such as
     *      "#007AFF" is fixed. Played by the Rive view (bug B12, docs/Animated-Item.md).
     * [CN] Tab 动画的选项（`CYLTabBarAnimationOptions` / URL 片段）：像模板图片一样的单色着色。"title" 跟随 Tab 标题颜色（普通 / 选中）；
     *      "#007AFF" 这样的颜色为固定色。由 Rive 视图实现（问题 B12）。
     */
    public static final String CYLTabBarAnimationOptionTint = "tint";
    public static final String CYLTabBarAnimationSize = "CYLTabBarAnimationSize";
    public static final String CYLTabBarAnimationURL = "CYLTabBarAnimationURL";
    public static final String CYLTabBarGIFDarkFilePath = "CYLTabBarGIFDarkFilePath";
    public static final String CYLTabBarGIFDarkURL = "CYLTabBarGIFDarkURL";
    public static final String CYLTabBarGIFFilePath = "CYLTabBarGIFFilePath";
    public static final String CYLTabBarGIFSize = "CYLTabBarGIFSize";
    public static final String CYLTabBarGIFURL = "CYLTabBarGIFURL";
    public static final String CYLTabBarLottieDarkColors = "CYLTabBarLottieDarkColors";
    public static final String CYLTabBarLottieDarkFilePath = "CYLTabBarLottieDarkFilePath";
    public static final String CYLTabBarLottieDarkURL = "CYLTabBarLottieDarkURL";
    public static final String CYLTabBarLottieFilePath = "CYLTabBarLottieFilePath";
    public static final String CYLTabBarLottieSize = "CYLTabBarLottieSize";
    public static final String CYLTabBarLottieURL = "CYLTabBarLottieURL";
    public static final String CYLTabBarPAGDarkFilePath = "CYLTabBarPAGDarkFilePath";
    public static final String CYLTabBarPAGDarkURL = "CYLTabBarPAGDarkURL";
    public static final String CYLTabBarPAGFilePath = "CYLTabBarPAGFilePath";
    public static final String CYLTabBarPAGSize = "CYLTabBarPAGSize";
    public static final String CYLTabBarPAGURL = "CYLTabBarPAGURL";
    public static final String CYLTabBarRiveDarkColors = "CYLTabBarRiveDarkColors";
    public static final String CYLTabBarRiveDarkFilePath = "CYLTabBarRiveDarkFilePath";
    public static final String CYLTabBarRiveDarkURL = "CYLTabBarRiveDarkURL";
    public static final String CYLTabBarRiveFilePath = "CYLTabBarRiveFilePath";
    public static final String CYLTabBarRiveSize = "CYLTabBarRiveSize";
    public static final String CYLTabBarRiveURL = "CYLTabBarRiveURL";
    public static final String CYLTabBarSVGADarkFilePath = "CYLTabBarSVGADarkFilePath";
    public static final String CYLTabBarSVGADarkURL = "CYLTabBarSVGADarkURL";
    public static final String CYLTabBarSVGAFilePath = "CYLTabBarSVGAFilePath";
    public static final String CYLTabBarSVGASize = "CYLTabBarSVGASize";
    public static final String CYLTabBarSVGAURL = "CYLTabBarSVGAURL";
}
