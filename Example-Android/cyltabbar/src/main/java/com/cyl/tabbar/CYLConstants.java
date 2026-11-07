package com.cyl.tabbar;

import androidx.annotation.NonNull;

/**
 * [EN] The constants of CYLTabBarController, with the iOS names (CYLConstants.h, CYLTabBarController.h): the keys of
 *      the tab bar item attributes and of a configuration, the notifications and the placeholder sizes.
 * [CN] CYLTabBarController 的常量，与 iOS 同名（CYLConstants.h、CYLTabBarController.h）：TabBarItem 属性与配置的键、通知名与占位尺寸。
 */
public final class CYLConstants {

    private CYLConstants() {
    }

    // MARK: - Tab bar item attributes 属性键

    public static final String CYLTabBarItemTitle = "CYLTabBarItemTitle";
    public static final String CYLTabBarItemImage = "CYLTabBarItemImage";
    public static final String CYLTabBarItemSelectedImage = "CYLTabBarItemSelectedImage";
    public static final String CYLTabBarItemDarkImage = "CYLTabBarItemDarkImage";
    public static final String CYLTabBarItemSelectedDarkImage = "CYLTabBarItemSelectedDarkImage";
    public static final String CYLTabBarItemImageURL = "CYLTabBarItemImageURL";
    public static final String CYLTabBarItemSelectedImageURL = "CYLTabBarItemSelectedImageURL";
    public static final String CYLTabBarItemImageURLSize = "CYLTabBarItemImageURLSize";
    public static final String CYLTabBarItemImageInsets = "CYLTabBarItemImageInsets";
    public static final String CYLTabBarItemTitlePositionAdjustment = "CYLTabBarItemTitlePositionAdjustment";
    public static final String CYLTabBarItemImagePositionAdjustment = "CYLTabBarItemImagePositionAdjustment";
    public static final String CYLTabBarItemIdentifier = "CYLTabBarItemIdentifier";
    public static final String CYLTabBarItemSelectedTitle = "CYLTabBarItemSelectedTitle";
    public static final String CYLTabBarItemTitleColor = "CYLTabBarItemTitleColor";
    public static final String CYLTabBarItemSelectedTitleColor = "CYLTabBarItemSelectedTitleColor";
    public static final String CYLTabBarItemIconColor = "CYLTabBarItemIconColor";
    public static final String CYLTabBarItemSelectedIconColor = "CYLTabBarItemSelectedIconColor";
    public static final String CYLTabBarItemBackgroundColor = "CYLTabBarItemBackgroundColor";
    public static final String CYLTabBarItemSelectedBackgroundColor = "CYLTabBarItemSelectedBackgroundColor";
    public static final String CYLTabBarItemTitleFont = "CYLTabBarItemTitleFont";
    public static final String CYLTabBarItemSelectedTitleFont = "CYLTabBarItemSelectedTitleFont";
    public static final String CYLTabBarItemAccessibilityIdentifier = "CYLTabBarItemAccessibilityIdentifier";
    public static final String CYLTabBarItemAccessibilityLabel = "CYLTabBarItemAccessibilityLabel";
    public static final String CYLTabBarItemAccessibilityHint = "CYLTabBarItemAccessibilityHint";
    public static final String CYLTabBarItemPageIdentifier = "CYLTabBarItemPageIdentifier";
    public static final String CYLTabBarItemPageParameters = "CYLTabBarItemPageParameters";
    public static final String CYLTabBarItemPlatforms = "CYLTabBarItemPlatforms";
    public static final String CYLTabBarItemMinimumAppVersion = "CYLTabBarItemMinimumAppVersion";

    // MARK: - Tab animations 动画键 (Lottie, the generic keys, PAG, Rive, options)

    public static final String CYLTabBarLottieFilePath = "CYLTabBarLottieFilePath";
    public static final String CYLTabBarLottieURL = "CYLTabBarLottieURL";
    public static final String CYLTabBarLottieSize = "CYLTabBarLottieSize";
    public static final String CYLTabBarLottieDarkURL = "CYLTabBarLottieDarkURL";
    public static final String CYLTabBarLottieDarkFilePath = "CYLTabBarLottieDarkFilePath";
    public static final String CYLTabBarLottieDarkColors = "CYLTabBarLottieDarkColors";
    public static final String CYLTabBarLottieLoopsWhenUnselected = "CYLTabBarLottieLoopsWhenUnselected";
    public static final String CYLTabBarAnimationURL = "CYLTabBarAnimationURL";
    public static final String CYLTabBarAnimationFilePath = "CYLTabBarAnimationFilePath";
    public static final String CYLTabBarAnimationSize = "CYLTabBarAnimationSize";
    public static final String CYLTabBarAnimationDarkURL = "CYLTabBarAnimationDarkURL";
    public static final String CYLTabBarAnimationDarkFilePath = "CYLTabBarAnimationDarkFilePath";
    public static final String CYLTabBarAnimationDarkColors = "CYLTabBarAnimationDarkColors";
    public static final String CYLTabBarAnimationColors = "CYLTabBarAnimationColors";
    public static final String CYLTabBarAnimationOptions = "CYLTabBarAnimationOptions";
    public static final String CYLTabBarPAGURL = "CYLTabBarPAGURL";
    public static final String CYLTabBarPAGFilePath = "CYLTabBarPAGFilePath";
    public static final String CYLTabBarPAGSize = "CYLTabBarPAGSize";
    public static final String CYLTabBarPAGDarkURL = "CYLTabBarPAGDarkURL";
    public static final String CYLTabBarPAGDarkFilePath = "CYLTabBarPAGDarkFilePath";
    public static final String CYLTabBarRiveURL = "CYLTabBarRiveURL";
    public static final String CYLTabBarRiveFilePath = "CYLTabBarRiveFilePath";
    public static final String CYLTabBarRiveSize = "CYLTabBarRiveSize";
    public static final String CYLTabBarRiveDarkURL = "CYLTabBarRiveDarkURL";
    public static final String CYLTabBarRiveDarkFilePath = "CYLTabBarRiveDarkFilePath";
    public static final String CYLTabBarRiveDarkColors = "CYLTabBarRiveDarkColors";
    /** [EN] Rive options of `CYLTabBarAnimationURLWithOptions()` (CYLRiveTabBarItemAnimator.h); every value is a string. [CN] `CYLTabBarAnimationURLWithOptions()` 的 Rive 选项；值都是字符串。 */
    public static final String CYLTabBarAnimationOptionRiveArtboard = "artboard";
    public static final String CYLTabBarAnimationOptionRiveStateMachine = "stateMachine";
    public static final String CYLTabBarAnimationOptionRiveActiveProperty = "active";
    public static final String CYLTabBarAnimationOptionRiveActiveDuration = "duration";
    public static final String CYLTabBarAnimationOptionRiveTriggerProperty = "trigger";
    public static final String CYLTabBarAnimationOptionRiveColor = "color";
    public static final String CYLTabBarAnimationOptionRiveInput = "input";
    public static final String CYLTabBarAnimationOptionRiveTriggerInput = "triggerInput";
    public static final String CYLTabBarAnimationOptionRiveAnimation = "animation";
    public static final String CYLTabBarAnimationOptionRiveLegacyRuntime = "legacy";

    // MARK: - Configuration keys 配置键 (CYLTabBarController (CYLConfiguration))

    public static final String CYLTabBarControllerViewControllers = "CYLTabBarControllerViewControllers";
    public static final String CYLTabBarControllerTabBarItemsAttributes = "CYLTabBarControllerTabBarItemsAttributes";
    public static final String CYLTabBarControllerImageInsets = "CYLTabBarControllerImageInsets";
    public static final String CYLTabBarControllerTitlePositionAdjustment = "CYLTabBarControllerTitlePositionAdjustment";
    public static final String CYLTabBarControllerStyleType = "CYLTabBarControllerStyleType";
    public static final String CYLTabBarControllerContext = "CYLTabBarControllerContext";
    public static final String CYLTabBarControllerPageRegistry = "CYLTabBarControllerPageRegistry";
    public static final String CYLTabBarControllerPageResolver = "CYLTabBarControllerPageResolver";
    public static final String CYLTabBarControllerPageLookupOrder = "CYLTabBarControllerPageLookupOrder";
    public static final String CYLTabBarControllerAutomaticPageRegistration = "CYLTabBarControllerAutomaticPageRegistration";
    public static final String CYLTabBarControllerTabBarItemAnimationSpeed = "CYLTabBarControllerTabBarItemAnimationSpeed";

    // MARK: - Notifications 通知 (names, posted through CYLNotificationCenter)

    public static final String CYLTabBarItemAnimationPlayingNotification = "CYLTabBarItemAnimationPlayingNotification";
    public static final String CYLTabBarItemAnimationViewDidAddNotification = "CYLTabBarItemAnimationViewDidAddNotification";
    public static final String CYLThemeDidChangeNotification = "CYLThemeDidChangeNotification";
    public static final String CYLTabBarMinimizeDidChangeNotification = "CYLTabBarMinimizeDidChangeNotification";

    // MARK: - Sizes 尺寸 (dp)

    /** [EN] The icon placeholder size, in dp (iOS: 30 pt). [CN] 图标占位尺寸（dp；iOS 为 30 pt）。 */
    public static final float CYLTabBarItemImagePlaceholderWidth = 30f;
    public static final float CYLTabBarItemImagePlaceholderHeight = 30f;
    /** [EN] The default tab bar height, in dp (iOS: 49 pt). [CN] 默认 TabBar 高度（dp；iOS 为 49 pt）。 */
    public static final float CYLTabBarHeight = 49f;

    /** [EN] The default plus button index: the middle of the tabs. [CN] 默认 PlusButton 下标：Tab 的中间。 */
    public static int defaultPlusButtonIndex(int tabsCount) {
        return tabsCount / 2;
    }

    @NonNull
    public static String describe(@NonNull Object value) {
        return String.valueOf(value);
    }

    // MARK: - Tab animations (CYLConstants.h) 动画

    /**
     * [EN] `+cyl_tabBarItemAnimationSizeValue:fromNormalImage:`: the animation size, else the normal image's size (dp), else the
     *      icon placeholder size.
     * [CN] 动画尺寸，否则普通图片的尺寸（dp），否则图标占位尺寸。
     */
    public static CYLSize cyl_tabBarItemAnimationSizeValue(@androidx.annotation.Nullable CYLSize animationSize, @androidx.annotation.Nullable android.graphics.drawable.Drawable normalImage) {
        if (animationSize != null && (animationSize.getWidth() != 0f || animationSize.getHeight() != 0f)) {
            return animationSize;
        }
        if (normalImage != null && normalImage.getIntrinsicWidth() > 0 && normalImage.getIntrinsicHeight() > 0) {
            float density = android.content.res.Resources.getSystem().getDisplayMetrics().density;
            return new CYLSize(normalImage.getIntrinsicWidth() / density, normalImage.getIntrinsicHeight() / density);
        }
        return new CYLSize(CYLTabBarItemImagePlaceholderWidth, CYLTabBarItemImagePlaceholderHeight);
    }

    /** [EN] `+cyl_getTureLottieSizeValue:fromNormalImage:` (deprecated): use `cyl_tabBarItemAnimationSizeValue`. [CN] 请使用 `cyl_tabBarItemAnimationSizeValue`。 */
    @Deprecated
    public static CYLSize cyl_getTureLottieSizeValue(@androidx.annotation.Nullable CYLSize lottieSize, @androidx.annotation.Nullable android.graphics.drawable.Drawable normalImage) {
        return cyl_tabBarItemAnimationSizeValue(lottieSize, normalImage);
    }

    /** [EN] `+cyl_registerDarkLottieURL:forLottieURL:` (deprecated): use the `CYLTabBarAnimationDarkURL` key. [CN] 请使用 `CYLTabBarAnimationDarkURL` 键。 */
    @Deprecated
    public static void cyl_registerDarkLottieURL(@androidx.annotation.NonNull String darkLottieURL, @androidx.annotation.NonNull String lottieURL) {
        CYLTabBarItemAnimationStyleSource.INSTANCE.registerDarkURL(darkLottieURL, lottieURL);
    }

    /** [EN] `+cyl_registerLottieDarkColors:forLottieURL:` (deprecated): use the `CYLTabBarAnimationDarkColors` key. [CN] 请使用 `CYLTabBarAnimationDarkColors` 键。 */
    @Deprecated
    public static void cyl_registerLottieDarkColors(@androidx.annotation.NonNull java.util.Map<String, Integer> darkColors, @androidx.annotation.NonNull String lottieURL) {
        CYLTabBarItemAnimationStyleSource.INSTANCE.registerDarkColors(darkColors, lottieURL);
    }

    /** [EN] `+cyl_lottieDarkColorsForLottieURL:` (deprecated). [CN] 已废弃。 */
    @Deprecated
    @androidx.annotation.Nullable
    public static java.util.Map<String, Integer> cyl_lottieDarkColorsForLottieURL(@androidx.annotation.NonNull String lottieURL) {
        return CYLTabBarItemAnimationStyleSource.INSTANCE.darkColorsForURL(lottieURL);
    }

    /** [EN] `+cyl_hasDarkLottieURLs` (deprecated). [CN] 已废弃。 */
    @Deprecated
    public static boolean cyl_hasDarkLottieURLs() {
        return CYLTabBarItemAnimationStyleSource.INSTANCE.hasDarkURLs();
    }

    /** [EN] `+cyl_hasDarkLottieForLottieURL:` (deprecated). [CN] 已废弃。 */
    @Deprecated
    public static boolean cyl_hasDarkLottieForLottieURL(@androidx.annotation.NonNull String lottieURL) {
        return CYLTabBarItemAnimationStyleSource.INSTANCE.hasDarkStyleForURL(lottieURL);
    }

    /**
     * [EN] `+isTabBarItemAnimationEnabledWithURLs:tabBarItemsAttributes:`: an animation library is in the app, and `urls` is
     *      not empty or a tab names an animation file (#477, any tab).
     * [CN] App 中有动画库，且 `urls` 非空或有 Tab 指定了动画文件（#477，任一 Tab）。
     */
    public static boolean isTabBarItemAnimationEnabledWithURLs(@androidx.annotation.Nullable java.util.List<String> urls, @androidx.annotation.Nullable java.util.List<? extends java.util.Map<String, ?>> tabBarItemsAttributes) {
        if (CYLTabBarItemAnimatorRegistry.Companion.animators().isEmpty()) {
            return false;
        }
        if (urls != null && !urls.isEmpty()) {
            return true;
        }
        if (tabBarItemsAttributes != null) {
            for (java.util.Map<String, ?> item : tabBarItemsAttributes) {
                if (item != null && CYLTabBarItemAnimationHostKt.CYLTabBarItemAttributesHaveAnimationFile(castAttributes(item))) {
                    return true;
                }
            }
        }
        return false;
    }

    /** [EN] `+isLottieEnabledFromlottieURLs:tabBarItemsAttributes:` (deprecated). [CN] 已废弃。 */
    @Deprecated
    public static boolean isLottieEnabledFromlottieURLs(@androidx.annotation.Nullable java.util.List<String> lottieURLs, @androidx.annotation.Nullable java.util.List<? extends java.util.Map<String, ?>> tabBarItemsAttributes) {
        return isTabBarItemAnimationEnabledWithURLs(lottieURLs, tabBarItemsAttributes);
    }

    @SuppressWarnings("unchecked")
    private static java.util.Map<String, Object> castAttributes(java.util.Map<String, ?> item) {
        return (java.util.Map<String, Object>) item;
    }
}
