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
    /**
     * [EN] FIX: issue #787. How a tab's icon takes its colors: "template" (tinted with the icon colors, else the bar's tint;
     *      one image serves both states), "original" (keeps its own colors, even with an icon color set) or "automatic"
     *      (default: tinted when it has an icon color). The controller keys are the defaults of every tab without its own.
     * [CN] FIX: issue #787。Tab 图标如何取色："template"（用图标颜色着色，否则用 TabBar 的着色；一张图用于两种状态）、"original"
     *      （保持原色，即使设置了图标颜色）或 "automatic"（默认：有图标颜色时着色）。Controller 级的键是没有单独设置的所有 Tab 的默认值。
     */
    public static final String CYLTabBarItemIconRenderingMode = "CYLTabBarItemIconRenderingMode";
    public static final String CYLTabBarControllerIconRenderingMode = "CYLTabBarControllerIconRenderingMode";
    public static final String CYLTabBarControllerIconColor = "CYLTabBarControllerIconColor";
    public static final String CYLTabBarControllerSelectedIconColor = "CYLTabBarControllerSelectedIconColor";
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
    /**
     * [EN] GIF keys (#605, CYLGIFTabBarItemAnimator.h): a GIF plays once when its tab is selected. [CN] GIF 键（#605）：选中 Tab 时播放一次。
     */
    public static final String CYLTabBarGIFURL = "CYLTabBarGIFURL";
    public static final String CYLTabBarGIFFilePath = "CYLTabBarGIFFilePath";
    public static final String CYLTabBarGIFSize = "CYLTabBarGIFSize";
    public static final String CYLTabBarGIFDarkURL = "CYLTabBarGIFDarkURL";
    public static final String CYLTabBarGIFDarkFilePath = "CYLTabBarGIFDarkFilePath";
    /**
     * [EN] Rive options of `CYLTabBarAnimationURLWithOptions()` (CYLRiveTabBarItemAnimator.h); every value is a string. [CN] `CYLTabBarAnimationURLWithOptions()` 的 Rive 选项；值都是字符串。
     */
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
    /**
     * [EN] The plus button of a configuration (CYLConfigurationPlusButton): a map, and a code-only tap action.
     * [CN] 配置中的 PlusButton（CYLConfigurationPlusButton）：一个 map，以及仅代码可用的点击回调。
     */
    public static final String CYLTabBarControllerPlusButton = "CYLTabBarControllerPlusButton";
    public static final String CYLTabBarControllerPlusButtonAction = "CYLTabBarControllerPlusButtonAction";
    /**
     * [EN] More keys of the plus button map: a background image with the title on it, its place, its vertical center, title
     *      alignment, a title kept visible, and a page of its own (CYLTabBarItemPageIdentifier). Same names as iOS.
     * [CN] PlusButton map 的更多键：标题画在其上的背景图、位置、垂直中心、标题对齐、保持显示标题，以及自己的页面（CYLTabBarItemPageIdentifier）。与 iOS 同名。
     */
    public static final String CYLPlusButtonBackgroundImage = "CYLPlusButtonBackgroundImage";
    public static final String CYLPlusButtonIndexInTabBar = "CYLPlusButtonIndexInTabBar";
    public static final String CYLPlusButtonCenterYMultiplier = "CYLPlusButtonCenterYMultiplier";
    public static final String CYLPlusButtonCenterYOffset = "CYLPlusButtonCenterYOffset";
    public static final String CYLPlusButtonAlignsTitle = "CYLPlusButtonAlignsTitle";
    public static final String CYLPlusButtonKeepsTitleVisible = "CYLPlusButtonKeepsTitleVisible";
    /**
     * [EN] iOS Liquid Glass: shows the selection under the plus button while its own page is selected. Android always shows
     *      it, so the key is read only on iOS; same name for one configuration on both.
     * [CN] iOS 液态玻璃：选中 PlusButton 自己的页面时，在其下方显示选中效果。Android 总是显示，因此只有 iOS 读取该键；同名以便两端共用一份配置。
     */
    public static final String CYLPlusButtonShowsSelection = "CYLPlusButtonShowsSelection";
    /**
     * [EN] The plus button's size in dp ("{55, 80}" or [55, 80]), as a subclass sets it. [CN] PlusButton 的尺寸（dp，"{55, 80}" 或 [55, 80]），与子类设置的相同。
     */
    public static final String CYLPlusButtonSize = "CYLPlusButtonSize";
    /**
     * [EN] The size (dp) the plus button's images are drawn at, aspect fit. [CN] PlusButton 图片的绘制尺寸（dp），等比缩放。
     */
    public static final String CYLPlusButtonImageSize = "CYLPlusButtonImageSize";
    /**
     * [EN] Appearance and interactions: "light" / "dark" / "system" (iOS only: Android follows the system), a tap animation
     *      name ("bounce"...), swiping on the tab bar to switch tabs.
     * [CN] 外观与交互："light" / "dark" / "system"（仅 iOS：Android 跟随系统）、点击动画名称（"bounce" 等）、在 TabBar 上滑动切换 Tab。
     */
    public static final String CYLTabBarControllerUserInterfaceStyle = "CYLTabBarControllerUserInterfaceStyle";
    public static final String CYLTabBarControllerTabButtonTapAnimation = "CYLTabBarControllerTabButtonTapAnimation";
    public static final String CYLTabBarControllerSwipeToSwitchTab = "CYLTabBarControllerSwipeToSwitchTab";
    /**
     * [EN] The identifiers of the tabs that need login (`cyl_loginRequiredTabBarItemIdentifiers`, #19). [CN] 需要登录的 Tab 的标识（#19）。
     */
    public static final String CYLTabBarControllerLoginRequiredTabBarItemIdentifiers = "CYLTabBarControllerLoginRequiredTabBarItemIdentifiers";
    /**
     * [EN] A memory warning unloads the unselected tabs (`unloadsUnselectedViewsOnMemoryWarning`, #426). [CN] 内存警告时卸载未选中的 Tab（#426）。
     */
    public static final String CYLTabBarControllerUnloadsUnselectedViewsOnMemoryWarning = "CYLTabBarControllerUnloadsUnselectedViewsOnMemoryWarning";
    /**
     * [EN] The tabs a memory warning never unloads (`cyl_keepsLoadedTabBarItemIdentifiers`). [CN] 内存警告时不卸载的 Tab（`cyl_keepsLoadedTabBarItemIdentifiers`）。
     */
    public static final String CYLTabBarControllerKeepsLoadedTabBarItemIdentifiers = "CYLTabBarControllerKeepsLoadedTabBarItemIdentifiers";
    /**
     * [EN] Skins of a configuration (see CYLTabBarConfigurationTheme). [CN] 配置中的皮肤（见 CYLTabBarConfigurationTheme）。
     */
    public static final String CYLTabBarControllerThemes = "CYLTabBarControllerThemes";
    public static final String CYLTabBarControllerThemeIdentifier = "CYLTabBarControllerThemeIdentifier";
    public static final String CYLTabBarControllerDarkThemeIdentifier = "CYLTabBarControllerDarkThemeIdentifier";
    public static final String CYLTabBarControllerThemeManagerName = "CYLTabBarControllerThemeManagerName";
    /**
     * [EN] Localized texts of a configuration (see CYLTabBarConfigurationLocalization, docs/Configuration-File.md).
     * [CN] 配置中的本地化文本（见 CYLTabBarConfigurationLocalization、docs/Configuration-File.md）。
     */
    public static final String CYLTabBarControllerLocalization = "CYLTabBarControllerLocalization";
    /**
     * [EN] A resource route to a configuration file (CYLResourceRoute, docs/Resource-Routes.md); the other keys win over the file's.
     * [CN] 指向配置文件的资源路由（CYLResourceRoute，docs/Resource-Routes.md）；其他键覆盖文件中的键。
     */
    public static final String CYLTabBarControllerConfigurationRoute = "CYLTabBarControllerConfigurationRoute";
    /**
     * [EN] A resource route to a tab bar manifest (CYLTabBarManifest); the other keys win over its configuration.
     * [CN] 指向 TabBar 配置清单的资源路由（CYLTabBarManifest）；其他键覆盖清单的配置。
     */
    public static final String CYLTabBarControllerManifestRoute = "CYLTabBarControllerManifestRoute";
    public static final String CYLTabBarLocalizationTableName = "CYLTabBarLocalizationTableName";
    public static final String CYLTabBarLocalizationPath = "CYLTabBarLocalizationPath";
    public static final String CYLTabBarLocalizationBundleName = "CYLTabBarLocalizationBundleName";
    public static final String CYLTabBarThemeIdentifier = "CYLTabBarThemeIdentifier";
    public static final String CYLTabBarThemeValues = "CYLTabBarThemeValues";
    public static final String CYLTabBarBackgroundColor = "CYLTabBarBackgroundColor";
    public static final String CYLTabBarShadowColor = "CYLTabBarShadowColor";
    /**
     * [EN] Skin value names of the bar's images and item layout, as on iOS (`UITabBarAppearance`). [CN] TabBar 图片与 Item 布局的皮肤值名称，与 iOS 相同（`UITabBarAppearance`）。
     */
    public static final String CYLTabBarBackgroundImage = "CYLTabBarBackgroundImage";
    public static final String CYLTabBarShadowImage = "CYLTabBarShadowImage";
    /**
     * [EN] "centered", "fill" or "automatic". [CN] "centered"、"fill" 或 "automatic"。
     */
    public static final String CYLTabBarStackedItemPositioning = "CYLTabBarStackedItemPositioning";
    /**
     * [EN] dp; 0: an equal share. [CN] dp；0 表示平分。
     */
    public static final String CYLTabBarStackedItemWidth = "CYLTabBarStackedItemWidth";
    /**
     * [EN] dp between centered items. [CN] 居中的 Item 之间的间距（dp）。
     */
    public static final String CYLTabBarStackedItemSpacing = "CYLTabBarStackedItemSpacing";

    // MARK: - Notifications 通知 (names, posted through CYLNotificationCenter)

    public static final String CYLTabBarItemAnimationPlayingNotification = "CYLTabBarItemAnimationPlayingNotification";
    public static final String CYLTabBarItemAnimationViewDidAddNotification = "CYLTabBarItemAnimationViewDidAddNotification";
    public static final String CYLThemeDidChangeNotification = "CYLThemeDidChangeNotification";
    public static final String CYLTabBarMinimizeDidChangeNotification = "CYLTabBarMinimizeDidChangeNotification";

    // MARK: - Tab change notifications Tab 变化通知 (as on iOS; observe with CYLNotificationCenter)

    /**
     * [EN] A tab's title (or selected title) changed in place; object: the tab's page. [CN] Tab 的标题（或选中标题）原地变化；object 为该 Tab 的页面。
     */
    public static final String CYLTabBarItemTitleDidChangeNotification = "CYLTabBarItemTitleDidChangeNotification";
    /**
     * [EN] A tab's icon changed (image keys, URLs, `setTabBarItemIcon`, an icon view provider); object: the tab's page. [CN] Tab 的图标变化；object 为该 Tab 的页面。
     */
    public static final String CYLTabBarItemIconDidChangeNotification = "CYLTabBarItemIconDidChangeNotification";
    /**
     * [EN] Any in-place change of a tab, after the two above; object: the tab's page. [CN] Tab 的任何原地变化，在上面两个之后发送；object 为该 Tab 的页面。
     */
    public static final String CYLTabBarItemDidChangeNotification = "CYLTabBarItemDidChangeNotification";
    /**
     * [EN] A skin was applied (or removed); object: the tab bar controller. [CN] 应用（或移除）了皮肤；object 为 TabBarController。
     */
    public static final String CYLTabBarControllerThemeDidApplyNotification = "CYLTabBarControllerThemeDidApplyNotification";
    /**
     * [EN] userInfo keys. [CN] userInfo 的 key。
     */
    public static final String CYLTabBarControllerKey = "CYLTabBarControllerKey";
    public static final String CYLTabBarItemIndexKey = "CYLTabBarItemIndexKey";
    public static final String CYLTabBarItemViewControllerKey = "CYLTabBarItemViewControllerKey";
    public static final String CYLTabBarItemKey = "CYLTabBarItemKey";
    public static final String CYLTabBarItemChangedAttributesKey = "CYLTabBarItemChangedAttributesKey";
    public static final String CYLTabBarItemOldTitleKey = "CYLTabBarItemOldTitleKey";
    public static final String CYLTabBarItemIconViewProviderKey = "CYLTabBarItemIconViewProviderKey";
    public static final String CYLPlusButtonKey = "CYLPlusButtonKey";
    public static final String CYLTabBarThemeKey = "CYLTabBarThemeKey";
    /**
     * [EN] The tab indexes a skin applies to (`List<Int>`; iOS: `NSIndexSet`). [CN] 皮肤作用的 Tab 下标（`List<Int>`；iOS 为 `NSIndexSet`）。
     */
    public static final String CYLTabBarItemIndexesKey = "CYLTabBarItemIndexesKey";
    public static final String CYLTabBarItemIdentifiersKey = "CYLTabBarItemIdentifiersKey";

    // MARK: - Sizes 尺寸 (dp)

    /**
     * [EN] The icon placeholder size, in dp (iOS: 30 pt). [CN] 图标占位尺寸（dp；iOS 为 30 pt）。
     */
    public static final float CYLTabBarItemImagePlaceholderWidth = 30f;
    public static final float CYLTabBarItemImagePlaceholderHeight = 30f;
    /**
     * [EN] The default tab bar height, in dp (iOS: 49 pt). [CN] 默认 TabBar 高度（dp；iOS 为 49 pt）。
     */
    public static final float CYLTabBarHeight = 49f;

    /**
     * [EN] The default plus button index: the middle of the tabs. [CN] 默认 PlusButton 下标：Tab 的中间。
     */
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

    /**
     * [EN] `+cyl_getTureLottieSizeValue:fromNormalImage:` (deprecated): use `cyl_tabBarItemAnimationSizeValue`. [CN] 请使用 `cyl_tabBarItemAnimationSizeValue`。
     */
    @Deprecated
    public static CYLSize cyl_getTureLottieSizeValue(@androidx.annotation.Nullable CYLSize lottieSize, @androidx.annotation.Nullable android.graphics.drawable.Drawable normalImage) {
        return cyl_tabBarItemAnimationSizeValue(lottieSize, normalImage);
    }

    /**
     * [EN] `+cyl_registerDarkLottieURL:forLottieURL:` (deprecated): use the `CYLTabBarAnimationDarkURL` key. [CN] 请使用 `CYLTabBarAnimationDarkURL` 键。
     */
    @Deprecated
    public static void cyl_registerDarkLottieURL(@androidx.annotation.NonNull String darkLottieURL, @androidx.annotation.NonNull String lottieURL) {
        CYLTabBarItemAnimationStyleSource.INSTANCE.registerDarkURL(darkLottieURL, lottieURL);
    }

    /**
     * [EN] `+cyl_registerLottieDarkColors:forLottieURL:` (deprecated): use the `CYLTabBarAnimationDarkColors` key. [CN] 请使用 `CYLTabBarAnimationDarkColors` 键。
     */
    @Deprecated
    public static void cyl_registerLottieDarkColors(@androidx.annotation.NonNull java.util.Map<String, Integer> darkColors, @androidx.annotation.NonNull String lottieURL) {
        CYLTabBarItemAnimationStyleSource.INSTANCE.registerDarkColors(darkColors, lottieURL);
    }

    /**
     * [EN] `+cyl_lottieDarkColorsForLottieURL:` (deprecated). [CN] 已废弃。
     */
    @Deprecated
    @androidx.annotation.Nullable
    public static java.util.Map<String, Integer> cyl_lottieDarkColorsForLottieURL(@androidx.annotation.NonNull String lottieURL) {
        return CYLTabBarItemAnimationStyleSource.INSTANCE.darkColorsForURL(lottieURL);
    }

    /**
     * [EN] `+cyl_hasDarkLottieURLs` (deprecated). [CN] 已废弃。
     */
    @Deprecated
    public static boolean cyl_hasDarkLottieURLs() {
        return CYLTabBarItemAnimationStyleSource.INSTANCE.hasDarkURLs();
    }

    /**
     * [EN] `+cyl_hasDarkLottieForLottieURL:` (deprecated). [CN] 已废弃。
     */
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

    /**
     * [EN] `+isLottieEnabledFromlottieURLs:tabBarItemsAttributes:` (deprecated). [CN] 已废弃。
     */
    @Deprecated
    public static boolean isLottieEnabledFromlottieURLs(@androidx.annotation.Nullable java.util.List<String> lottieURLs, @androidx.annotation.Nullable java.util.List<? extends java.util.Map<String, ?>> tabBarItemsAttributes) {
        return isTabBarItemAnimationEnabledWithURLs(lottieURLs, tabBarItemsAttributes);
    }

    @SuppressWarnings("unchecked")
    private static java.util.Map<String, Object> castAttributes(java.util.Map<String, ?> item) {
        return (java.util.Map<String, Object>) item;
    }
}
