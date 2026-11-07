package com.cyl.tabbar;

/**
 * [EN] The enums of CYLTabBarController, with the iOS names and raw values.
 * [CN] CYLTabBarController 的枚举，与 iOS 同名、同原始值。
 */
public final class CYLEnums {

    private CYLEnums() {
    }

    /** [EN] CYLTabBarStyleType. On Android, Default / System / LiquidGlass share one classic layout; FlatDesign is the same layout with the flat tab buttons. [CN] CYLTabBarStyleType。Android 上 Default / System / LiquidGlass 共用经典布局；FlatDesign 为同一布局加扁平 Tab 按钮。 */
    public enum CYLTabBarStyleType {
        Default(0), System(1), FlatDesign(2), LiquidGlass(3);

        public final int rawValue;

        CYLTabBarStyleType(int rawValue) {
            this.rawValue = rawValue;
        }

        public static CYLTabBarStyleType fromRawValue(int rawValue) {
            for (CYLTabBarStyleType type : values()) {
                if (type.rawValue == rawValue) {
                    return type;
                }
            }
            return Default;
        }

        /** [EN] "default", "system", "flatDesign", "liquidGlass" (a configuration file). [CN] 配置文件中的名称。 */
        public static CYLTabBarStyleType fromName(String name) {
            if (name == null) {
                return Default;
            }
            switch (name.trim().toLowerCase(java.util.Locale.ROOT)) {
                case "system": return System;
                case "flatdesign": return FlatDesign;
                case "liquidglass": return LiquidGlass;
                default: return Default;
            }
        }
    }

    /** [EN] CYLTabBarMinimizeBehavior (issue #13). [CN] 滚动时缩小 / 隐藏 TabBar 的行为（issue #13）。 */
    public enum CYLTabBarMinimizeBehavior {
        Automatic(0), Never(1), OnScrollDown(2), OnScrollUp(3);

        public final int rawValue;

        CYLTabBarMinimizeBehavior(int rawValue) {
            this.rawValue = rawValue;
        }
    }

    /** [EN] CYLTabBarReselectBehavior: what a tap on the selected tab does. [CN] 重复点击已选中 Tab 的行为。 */
    public enum CYLTabBarReselectBehavior {
        None(0), PopToRoot(1), ScrollToTop(2), PopToRootThenScrollToTop(3);

        public final int rawValue;

        CYLTabBarReselectBehavior(int rawValue) {
            this.rawValue = rawValue;
        }
    }

    /** [EN] CYLTabBarItemGesture: the gestures a tab button reports to the delegate. [CN] Tab 按钮上报给代理的手势。 */
    public enum CYLTabBarItemGesture {
        Tap(0), DoubleTap(1), LongPress(2), SwipeLeft(3), SwipeRight(4);

        public final int rawValue;

        CYLTabBarItemGesture(int rawValue) {
            this.rawValue = rawValue;
        }
    }

    /** [EN] CYLTabButtonTapAnimationType (issue #535). [CN] 点击 Tab 的动画类型（issue #535）。 */
    public enum CYLTabButtonTapAnimationType {
        None(0), Scale(1), ZoomIn(2), Bounce(3), BounceWithFireworks(4), Rotation(5), Flip(6), Fume(7), Frame(8), Lottie(9);

        public final int rawValue;

        CYLTabButtonTapAnimationType(int rawValue) {
            this.rawValue = rawValue;
        }
    }

    /** [EN] CYLBadgeStyle. [CN] 角标样式。 */
    public enum CYLBadgeStyle {
        RedDot(0), Number(1), New(2);

        public final int rawValue;

        CYLBadgeStyle(int rawValue) {
            this.rawValue = rawValue;
        }
    }

    /** [EN] CYLBadgeAnimationType. [CN] 角标动画类型。 */
    public enum CYLBadgeAnimationType {
        None(0), Scale(1), Shake(2), Bounce(3), Breathe(4);

        public final int rawValue;

        CYLBadgeAnimationType(int rawValue) {
            this.rawValue = rawValue;
        }
    }

    /** [EN] UIImpactFeedbackStyle, for cyl_tabButtonHapticFeedbackStyle. [CN] 触感反馈强度。 */
    public enum CYLImpactFeedbackStyle {
        Light(0), Medium(1), Heavy(2), Soft(3), Rigid(4);

        public final int rawValue;

        CYLImpactFeedbackStyle(int rawValue) {
            this.rawValue = rawValue;
        }
    }
}
