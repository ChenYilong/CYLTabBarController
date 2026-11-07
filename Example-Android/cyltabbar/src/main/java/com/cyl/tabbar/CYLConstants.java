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
}
