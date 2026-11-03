//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLFlatDesignTabBarButton.h"
#import "CYLFlatDesignTabBarItem.h"
#import "CYLFlatDesignTabBar.h"
#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/CYLTabBarController.h>
#else
#import "CYLTabBarController.h"
#endif

@interface CYLFlatDesignTabBarButton ()

/// Drawn behind the selected item for `UITabBarAppearance.selectionIndicatorImage`.
/// 按 `UITabBarAppearance.selectionIndicatorImage` 绘制在选中 item 背后。
@property (nonatomic, strong, nullable) UIImageView *selectionIndicatorView;
/// The badge values this button set from an appearance, so they can be given back when it no longer sets them.
/// 本按钮按 appearance 设置过的角标属性，appearance 不再设置时可以还原。
@property (nonatomic, assign) BOOL appliedAppearanceBadgeBackgroundColor;
@property (nonatomic, assign) BOOL appliedAppearanceBadgeTextColor;
@property (nonatomic, assign) BOOL appliedAppearanceBadgeFont;
@property (nonatomic, assign) BOOL appliedAppearanceBadgeOffset;

@end

#pragma mark - UITabBarAppearance

/// A `UITabBarAppearance` as created, to tell values an app customized from the defaults. 新建的 `UITabBarAppearance`，用于区分 App 自定义的值与默认值。
API_AVAILABLE(ios(13.0))
static UITabBarItemAppearance *CYLDefaultTabBarItemAppearance(void) {
    static UITabBarItemAppearance *defaultAppearance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultAppearance = [[UITabBarAppearance alloc] init].stackedLayoutAppearance;
    });
    return defaultAppearance;
}

API_AVAILABLE(ios(13.0))
static UITabBarItemStateAppearance *CYLStateAppearanceForState(UITabBarItemAppearance *itemAppearance, UIControlState state) {
    if (state & UIControlStateDisabled) {
        return itemAppearance.disabled;
    }
    if (state & UIControlStateSelected) {
        return itemAppearance.selected;
    }
    return itemAppearance.normal;
}

static BOOL CYLAppearanceValueIsCustomized(id _Nullable value, id _Nullable defaultValue) {
    if (!value) {
        return NO;
    }
    return !(defaultValue && [value isEqual:defaultValue]);
}

@implementation CYLFlatDesignTabBarButton
@synthesize selected = _selected;
//@synthesize enabled = _enabled;

- (instancetype)initWithTabBarItem:(CYLFlatDesignTabBarItem *)tabBarItem {
    if (self = [super init]) {
        _tabBarItem = tabBarItem;
        self.clipsToBounds = NO;
        if (tabBarItem) {
            [self _updateTabBarButton];
        }
        if (_tabBarItem) {
            [_tabBarItem cyl_setValue:self forKey:@"tabBarButton"];
        }
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _imageView = [[UIImageView alloc] init];
        _imageView.clipsToBounds = NO;
        [self addSubview:_imageView];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.clipsToBounds = NO;
//        [self.actualBadgeSuperView cyl_showBadgeValue:_tabBarItem.badgeValue];
        [self addSubview:_titleLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self _updateLayout];
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    if (self.isSelected) {
        _titleLabel.textColor = [self _titleTextAttributesForState][NSForegroundColorAttributeName];
        _imageView.tintColor = [self _iconColorForState];
    }
}

#pragma mark - UITabBarAppearance mapping

/// The flat design tab bar this button is on. 本按钮所在的扁平样式 TabBar。
- (nullable CYLFlatDesignTabBar *)_owningFlatDesignTabBar {
    UIView *view = self.superview;
    while (view && ![view isKindOfClass:[CYLFlatDesignTabBar class]]) {
        view = view.superview;
    }
    return (CYLFlatDesignTabBar *)view;
}

/*!
 * [EN] The appearance the bar is drawn with, see `-[CYLFlatDesignTabBar standardAppearance]`: the selected item's own,
 *      else the bar's. The selected item comes from the bar, so every button follows it.
 * [CN] TabBar 绘制所用的 appearance，见 `-[CYLFlatDesignTabBar standardAppearance]`：选中 item 自身的，否则为 TabBar 的。
 *      选中 item 取自 TabBar，因此所有按钮保持一致。
 */
- (nullable UITabBarAppearance *)_effectiveAppearance API_AVAILABLE(ios(13.0)) {
    CYLFlatDesignTabBar *tabBar = [self _owningFlatDesignTabBar];
    if (!tabBar) {
        return _tabBarItem.standardAppearance;
    }
    return tabBar.selectedItem.standardAppearance ?: tabBar.standardAppearance;
}

/// The state appearance of the current state, nil without an appearance. 当前状态的 state appearance，没有 appearance 时为 nil。
- (nullable UITabBarItemStateAppearance *)_stateAppearance API_AVAILABLE(ios(13.0)) {
    UITabBarAppearance *appearance = [self _effectiveAppearance];
    if (!appearance) {
        return nil;
    }
    return CYLStateAppearanceForState(appearance.stackedLayoutAppearance, [self _currentState]);
}

- (nullable UITabBarItemStateAppearance *)_defaultStateAppearance API_AVAILABLE(ios(13.0)) {
    return CYLStateAppearanceForState(CYLDefaultTabBarItemAppearance(), [self _currentState]);
}

/// `iconColor` of the appearance, else the flat design default (tint color when selected, gray otherwise).
/// appearance 的 `iconColor`，否则使用扁平样式默认值（选中为 tintColor，否则为灰色）。
- (UIColor *)_iconColorForState {
    if (@available(iOS 13.0, *)) {
        UIColor *iconColor = [self _stateAppearance].iconColor;
        if (iconColor) {
            return iconColor;
        }
    }
    return self.isSelected ? self.tintColor : [UIColor systemGrayColor];
}

/// `titlePositionAdjustment` of the appearance, used when the item has no offset of its own. item 没有自身偏移时使用的 appearance `titlePositionAdjustment`。
- (UIOffset)_appearanceTitlePositionAdjustment {
    if (@available(iOS 13.0, *)) {
        UITabBarItemStateAppearance *stateAppearance = [self _stateAppearance];
        if (stateAppearance) {
            return stateAppearance.titlePositionAdjustment;
        }
    }
    return UIOffsetZero;
}

/*!
 * [EN] `selectionIndicatorImage` / `selectionIndicatorTintColor` of the appearance, behind the selected item. A resizable
 *      image fills the button, any other is centered. Only shown while selected.
 * [CN] appearance 的 `selectionIndicatorImage` / `selectionIndicatorTintColor`，绘制在选中 item 背后。可拉伸图片铺满按钮，其他图片居中。
 *      仅在选中时显示。
 */
- (void)_updateSelectionIndicator {
    UIImage *image = nil;
    UIColor *tintColor = nil;
    if (@available(iOS 13.0, *)) {
        UITabBarAppearance *appearance = [self _effectiveAppearance];
        if (self.isSelected) {
            image = appearance.selectionIndicatorImage;
            tintColor = appearance.selectionIndicatorTintColor;
        }
    }
    if (!image) {
        [_selectionIndicatorView removeFromSuperview];
        _selectionIndicatorView = nil;
        return;
    }
    if (tintColor && image.renderingMode != UIImageRenderingModeAlwaysOriginal) {
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    UIImageView *selectionIndicatorView = _selectionIndicatorView;
    if (!selectionIndicatorView) {
        selectionIndicatorView = [[UIImageView alloc] init];
        selectionIndicatorView.userInteractionEnabled = NO;
        _selectionIndicatorView = selectionIndicatorView;
    }
    selectionIndicatorView.image = image;
    selectionIndicatorView.tintColor = tintColor;
    BOOL isResizable = !UIEdgeInsetsEqualToEdgeInsets(image.capInsets, UIEdgeInsetsZero);
    selectionIndicatorView.contentMode = isResizable ? UIViewContentModeScaleToFill : UIViewContentModeCenter;
    selectionIndicatorView.frame = self.bounds;
    [self insertSubview:selectionIndicatorView atIndex:0];
}

/*!
 * [EN] Badge values of the appearance: background color, text color and font, center offset. A value that is not
 *      customized (equal to a new `UITabBarAppearance`) is left to the badge's own settings and `CYLBadgeAppearance`; one
 *      set here earlier is given back to them (nil restores the global value).
 * [CN] appearance 的角标属性：背景色、文字颜色与字体、中心偏移。未自定义的值（与新建的 `UITabBarAppearance` 相同）交给角标自身设置
 *      与 `CYLBadgeAppearance`；之前在这里设置过的会还给它们（nil 恢复全局值）。
 */
- (void)_updateBadgeAppearance {
    UIColor *backgroundColor = nil;
    UIColor *textColor = nil;
    UIFont *font = nil;
    NSValue *offsetValue = nil;
    if (@available(iOS 13.0, *)) {
        UITabBarItemStateAppearance *stateAppearance = [self _stateAppearance];
        UITabBarItemStateAppearance *defaultStateAppearance = [self _defaultStateAppearance];
        if (stateAppearance) {
            if (CYLAppearanceValueIsCustomized(stateAppearance.badgeBackgroundColor, defaultStateAppearance.badgeBackgroundColor)) {
                backgroundColor = stateAppearance.badgeBackgroundColor;
            }
            NSDictionary<NSAttributedStringKey, id> *badgeTextAttributes = stateAppearance.badgeTextAttributes;
            NSDictionary<NSAttributedStringKey, id> *defaultBadgeTextAttributes = defaultStateAppearance.badgeTextAttributes;
            if (CYLAppearanceValueIsCustomized(badgeTextAttributes[NSForegroundColorAttributeName], defaultBadgeTextAttributes[NSForegroundColorAttributeName])) {
                textColor = badgeTextAttributes[NSForegroundColorAttributeName];
            }
            if (CYLAppearanceValueIsCustomized(badgeTextAttributes[NSFontAttributeName], defaultBadgeTextAttributes[NSFontAttributeName])) {
                font = badgeTextAttributes[NSFontAttributeName];
            }
            UIOffset offset = stateAppearance.badgePositionAdjustment;
            if (!UIOffsetEqualToOffset(offset, UIOffsetZero)) {
                offsetValue = [NSValue valueWithUIOffset:offset];
            }
        }
    }
    UIView *badgeSuperView = self.actualBadgeSuperView;
    if (backgroundColor || self.appliedAppearanceBadgeBackgroundColor) {
        [badgeSuperView cyl_setBadgeBackgroundColor:backgroundColor];
        self.appliedAppearanceBadgeBackgroundColor = (backgroundColor != nil);
    }
    if (textColor || self.appliedAppearanceBadgeTextColor) {
        [badgeSuperView cyl_setBadgeTextColor:textColor];
        self.appliedAppearanceBadgeTextColor = (textColor != nil);
    }
    if (font || self.appliedAppearanceBadgeFont) {
        [badgeSuperView cyl_setBadgeFont:font];
        self.appliedAppearanceBadgeFont = (font != nil);
    }
    if (offsetValue || self.appliedAppearanceBadgeOffset) {
        UIOffset offset = offsetValue ? offsetValue.UIOffsetValue : UIOffsetZero;
        [badgeSuperView cyl_setBadgeCenterOffset:CGPointMake(offset.horizontal, offset.vertical)];
        self.appliedAppearanceBadgeOffset = (offsetValue != nil);
    }
}

- (void)setTabBarItem:(CYLFlatDesignTabBarItem *)tabBarItem {
    if (![self.tabBarItem isKindOfClass:[CYLFlatDesignTabBarItem class]]) {
        return;
    }
    _tabBarItem = tabBarItem;
    [self _updateTabBarButton];
    if (_tabBarItem && !(_tabBarItem.tabBarButton)) {
        [_tabBarItem cyl_setValue:self forKey:@"tabBarButton"];
    }
#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
    if (_tabBarItem) {
        //        [_tabBarItem cyl_setTabButton:self];
    }
#else
#endif
}

- (void)setSelected:(BOOL)selected {
    if (self.selected != selected) {
        [super setSelected:selected];
        _selected = selected;
        [self _updateTabBarButton];
    }
}

/*!
 * // badge 请使用VC 调用， 暂不支持 _tabBarItem 设置。
 if (self.actualBadgeSuperView.cyl_isShowBadge) {
     if (_tabBarItem.badgeColor) {
         [self cyl_setBadgeBackgroundColor:_tabBarItem.badgeColor];
     }
     [self cyl_showBadgeValue:_tabBarItem.badgeValue];
     NSDictionary *badgeTextAttributes = [self _badgeTextAttributesForState];
     [self cyl_setBadgeFont:badgeTextAttributes[NSFontAttributeName]];
     [self cyl_setBadgeTextColor:badgeTextAttributes[NSForegroundColorAttributeName]];
     if (isCYLFlatDesignTabBarItem) {
         //            [self.actualBadgeSuperView setInset = _tabBarItem.badgeContentInset;
         [self cyl_setBadgeMargin:_tabBarItem.badgeContentInset.left];
     }
 }

 */
- (void)_updateTabBarButton {
    if (CGRectIsEmpty(self.bounds)) {
//        return;
    }
    BOOL isCYLFlatDesignTabBarItem = [_tabBarItem isKindOfClass:[CYLFlatDesignTabBarItem class]];
    self.enabled = _tabBarItem.enabled;
    
    // image
    UIImage *image = _tabBarItem.image;
    if (self.isSelected && _tabBarItem.selectedImage) {
        image = _tabBarItem.selectedImage;
    }
    _imageView.image = image;
    _imageView.tintColor = [self _iconColorForState];

    // title
    _titleLabel.text = _tabBarItem.title;
    _titleLabel.textColor = [self _titleTextAttributesForState][NSForegroundColorAttributeName];
    _titleLabel.font = [self _titleTextAttributesForState][NSFontAttributeName];
   
    // background
    if (isCYLFlatDesignTabBarItem) {
        UIColor *backgroundColor = _tabBarItem.backgroundColor;
        if (self.isSelected) {
            backgroundColor = _tabBarItem.selectedBackgroundColor ?: _tabBarItem.backgroundColor;
        }
        self.backgroundColor = backgroundColor;
    }
    [self _updateSelectionIndicator];
    [self _updateBadgeAppearance];
    [self updateLottie];
    [self setNeedsLayout];
//    [self layoutIfNeeded];
}

- (void)_updateLayout {
    if (CGRectIsEmpty(self.bounds)) {
        return;
    }
    _selectionIndicatorView.frame = self.bounds;
    
    // A Lottie-only item has no image, but the Lottie view is centered on `_imageView`,
    // so still lay the image slot out, sized to the Lottie size; otherwise it collapses to
    // CGRectZero and the animation is drawn around the button's top-left corner.
    CGSize lottieSize = [[self _lottieSizeValue] CGSizeValue];
    BOOL isLottieOnlyItem = (_imageView.image == nil) && (lottieSize.width > 0 && lottieSize.height > 0) && ([self _lottieURL] != nil);
    BOOL isShowImageView = (_imageView.image != nil) || isLottieOnlyItem;
    BOOL isShowTitleLabel = _titleLabel.text.length > 0;
    BOOL isCYLFlatDesignTabBarItem = [_tabBarItem isKindOfClass:[CYLFlatDesignTabBarItem class]];

    if (isLottieOnlyItem) {
        _imageView.frame = CGRectMake(0, 0, lottieSize.width, lottieSize.height);
    } else if (isShowImageView) {
        [_imageView sizeToFit];
    }
    
    NSString *title = isShowTitleLabel ? _titleLabel.text : @"height";
    CGSize titleSize = [title boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:_titleLabel.font} context:nil].size;
    
    CGFloat titleLabelWidth = titleSize.width;
    CGFloat titleLabelHeight = titleSize.height;
    CGFloat titleLabelX = (CGRectGetWidth(self.bounds) - titleLabelWidth) / 2;
    CGFloat titleLabelY = CGRectGetHeight(self.bounds) - titleLabelHeight - 2;
    if (!isShowImageView && _tabBarItem.layoutCentered) {
        titleLabelY = (CGRectGetHeight(self.bounds) - titleLabelHeight) / 2;
    }
    // The item's own offset (CYLTabBarController's `titlePositionAdjustment`) wins, else the appearance's: on the system
    // tab bar CYL writes its offset into the appearance (issue #475), so both styles show the same offset.
    // item 自身的偏移（CYLTabBarController 的 `titlePositionAdjustment`）优先，否则使用 appearance 的：系统 TabBar 上 CYL 会把偏移
    // 写入 appearance（issue #475），两种样式显示的偏移一致。
    UIOffset titlePositionAdjustment = _tabBarItem.titlePositionAdjustment;
    if (UIOffsetEqualToOffset(titlePositionAdjustment, UIOffsetZero)) {
        titlePositionAdjustment = [self _appearanceTitlePositionAdjustment];
    }
    titleLabelX += titlePositionAdjustment.horizontal;
    titleLabelY += titlePositionAdjustment.vertical;
    _titleLabel.frame = CGRectMake(titleLabelX, titleLabelY, titleLabelWidth, titleLabelHeight);
    
    if (isShowImageView) {
        CGFloat imageViewWidth = CGRectGetWidth(_imageView.frame);
        CGFloat imageViewHeight = CGRectGetHeight(_imageView.frame);
        
        CGFloat imageViewX = (CGRectGetWidth(self.bounds) - imageViewWidth) / 2;
        CGFloat imageViewY = (CGRectGetMinY(_titleLabel.frame) - imageViewHeight) / 2;
        if (!isShowTitleLabel && isCYLFlatDesignTabBarItem && _tabBarItem.layoutCentered) {
            imageViewY = (CGRectGetHeight(self.bounds) - imageViewHeight) / 2;
        }
        if (isCYLFlatDesignTabBarItem) {
            imageViewX += _tabBarItem.imagePositionAdjustment.horizontal;
            imageViewY += _tabBarItem.imagePositionAdjustment.vertical;
        }
        _imageView.frame = CGRectMake(imageViewX, imageViewY, imageViewWidth, imageViewHeight);
        
        UIEdgeInsets imageInsets = _tabBarItem.imageInsets;
        if (!UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsetsZero, imageInsets)) {
            //仅修改的size,xy值不变
            _imageView.frame = ({
                CGRect frame = _imageView.frame;
                frame.size.width = frame.size.width - imageInsets.left - imageInsets.right;
                frame.size.height = frame.size.height - imageInsets.top - imageInsets.bottom;
                
                frame;
            });
        }
    } else {
        _imageView.frame = CGRectZero;
    }
    [self initLottie];
}

- (NSDictionary *)_titleTextAttributesForState {
    UIControlState state = [self _currentState];
    NSMutableDictionary *titleAttributes = [_tabBarItem titleTextAttributesForState:state].mutableCopy;
    if (!titleAttributes) {
        titleAttributes = [_tabBarItem titleTextAttributesForState:UIControlStateNormal].mutableCopy;
    }
    if (@available(iOS 13.0, *)) {
        // The appearance's attributes override the item's, as on `UITabBar` (which ignores the item's once it has an
        // appearance). appearance 的属性覆盖 item 的属性，与 `UITabBar` 相同（有 appearance 后忽略 item 的属性）。
        NSDictionary<NSAttributedStringKey, id> *appearanceAttributes = [self _stateAppearance].titleTextAttributes;
        if (appearanceAttributes.count > 0) {
            titleAttributes = titleAttributes ?: [NSMutableDictionary dictionary];
            [titleAttributes addEntriesFromDictionary:appearanceAttributes];
        }
    }
    if (!titleAttributes) {
        if (state == UIControlStateSelected) {
            titleAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:10 weight:UIFontWeightMedium], NSForegroundColorAttributeName:self.tintColor}.mutableCopy;
        } else {
            titleAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:10 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[UIColor systemGrayColor]}.mutableCopy;
        }
        
    }
    if (titleAttributes[NSFontAttributeName] == nil) {
        titleAttributes[NSFontAttributeName] = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    }
    if (titleAttributes[NSForegroundColorAttributeName] == nil) {
        if (state == UIControlStateSelected) {
            titleAttributes[NSForegroundColorAttributeName] = self.tintColor;
        } else {
            titleAttributes[NSForegroundColorAttributeName] = [UIColor systemGrayColor];
        }
    }
    return [titleAttributes copy];
}

- (NSDictionary *)_badgeTextAttributesForState {
    UIControlState state = [self _currentState];
    NSMutableDictionary *badgeAttributes = [_tabBarItem badgeTextAttributesForState:state].mutableCopy;
    if (!badgeAttributes) {
        badgeAttributes = [_tabBarItem badgeTextAttributesForState:UIControlStateNormal].mutableCopy;
    }
    if (!badgeAttributes) {
        badgeAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:11], NSForegroundColorAttributeName:[UIColor whiteColor]}.mutableCopy;
    }
    if (badgeAttributes[NSFontAttributeName] == nil) {
        badgeAttributes[NSFontAttributeName] = [UIFont systemFontOfSize:11];
    }
    if (badgeAttributes[NSForegroundColorAttributeName] == nil) {
        badgeAttributes[NSForegroundColorAttributeName] = [UIColor whiteColor];
    }
    return badgeAttributes;
}

- (UIControlState)_currentState {
    UIControlState state = self.state;
    if (UIControlStateSelected & self.state) {
        state = UIControlStateSelected;
    }
    if (UIControlStateDisabled & self.state) {
        state = UIControlStateDisabled;
    }
    return state;
}

#pragma mark - initLottie

- (NSValue *)_lottieSizeValue {
    NSValue *lottieSizeValue;
    if ([_tabBarItem isKindOfClass:[CYLFlatDesignTabBarItem class]]) {
        lottieSizeValue = _tabBarItem.lottieSizeValue;
    }
    return lottieSizeValue;
}

- (NSString *)_lottieFilePath {
    NSString *lottieFilePath;
    
    if ([_tabBarItem isKindOfClass:[CYLFlatDesignTabBarItem class]]) {
        lottieFilePath = _tabBarItem.lottieFilePath;
    }
    return lottieFilePath;
}

- (NSURL *)_lottieURL {
    NSURL *lottieURL;
    if ([_tabBarItem isKindOfClass:[CYLFlatDesignTabBarItem class]]) {
        // Keep the URL-first behavior used by the default tab bar, then fall back to the local path.
        lottieURL = _tabBarItem.lottieURL;
        if (!lottieURL) {
            lottieURL = [CYLConstants cyl_getURLFromString:[self _lottieFilePath]];
        }
    }
    return lottieURL;
}

/*!
 * Resolves the `contentMode` for this button's Lottie view from the owning `CYLTabBarController`,
 * so the default (`UIViewContentModeScaleAspectFit`) and any subclass override of
 * `-lottieAnimationViewContentMode` also apply in flat-design mode.
 *
 * Problem this solves:
 * The previous code passed `self.cyl_tabBarController.lottieAnimationViewContentMode`, but
 * `-cyl_tabBarController` only returns controllers whose `tabBarStyleType` is NOT
 * `CYLTabBarStyleTypeFlatDesign` (see `-cyl_isSystemStyleTabBar`). For this button it is always nil,
 * and messaging nil returns 0, i.e. `UIViewContentModeScaleToFill`. As a result the Lottie animation
 * was stretched whenever `lottieSizeValue`'s aspect ratio differed from the animation's own, and a
 * subclass override of `-lottieAnimationViewContentMode` was silently ignored.
 *
 * Why it is written this way:
 * - Every style (system and flat design) is the same `CYLTabBarController` class, so the style cannot
 *   be told apart by class, and walking the responder chain for a `CYLTabBarController` is not reliable.
 *   Instead the flat-design controller is read from the explicit `cylflatdesign_tabBarController`
 *   references, the same approach `CYLPlusButton` uses for issue #650.
 * - Only the first call matters: `-cyl_addLottieImageWithLottieURL:size:contentMode:` returns early once
 *   the Lottie view exists, so a wrong mode picked here would stick for the button's lifetime. That is why
 *   an unresolved controller falls back to the documented default instead of 0.
 */
- (UIViewContentMode)_lottieContentMode {
    CYLTabBarController *tabBarController = [self _lottieTabBarController];
    // Never let a missing controller become 0 (UIViewContentModeScaleToFill);
    // fall back to the documented default instead.
    if (!tabBarController) {
        return UIViewContentModeScaleAspectFit;
    }
    return [tabBarController lottieAnimationViewContentMode];
}

/// FIX: issue #428 — `-[CYLTabBarController lottieAnimationSpeed]` in flat design, resolved like `-_lottieContentMode`.
- (CGFloat)_lottieAnimationSpeed {
    CYLTabBarController *tabBarController = [self _lottieTabBarController];
    if (!tabBarController) {
        return 1.0;
    }
    return [tabBarController lottieAnimationSpeed];
}

/// The tab bar controller that owns this button, in any style; see `-_lottieContentMode`.
- (CYLTabBarController *)_lottieTabBarController {
    // Non-flat styles: the regular lookup finds the controller (nil for flat design, by design).
    CYLTabBarController *tabBarController = [self cyl_tabBarController];
    if (!tabBarController) {
        // Flat design: CYLTabBarController hands itself to each flat item via
        // -cylflatdesign_setTabBarController: when it builds the items.
        tabBarController = _tabBarItem.cylflatdesign_tabBarController;
        if (!tabBarController) {
            // Fallback: the item passes the same reference on to its child view controller in
            // -setChildViewController:, mirroring how CYLPlusButton resolves the controller.
            tabBarController = _tabBarItem.childViewController.cylflatdesign_tabBarController;
        }
    }
    if (![tabBarController isKindOfClass:[CYLTabBarController class]]) {
        return nil;
    }
    return tabBarController;
}

- (void)initLottie {
    NSURL *lottieURL = [self _lottieURL];
    if (!lottieURL) {
        return;
    }

    if (lottieURL) {
#if __has_include(<Lottie/Lottie.h>)
        CGSize lottieSize = [[self _lottieSizeValue] CGSizeValue];
        [self cyl_addLottieImageWithLottieURL:lottieURL size:lottieSize contentMode:[self _lottieContentMode] animationSpeed:[self _lottieAnimationSpeed]];
#endif
     
#if __has_include(<Lottie/Lottie-Swift.h>)
        CGSize lottieSize = [[self _lottieSizeValue] CGSizeValue];
        [self cyl_addLottieImageWithLottieURL:lottieURL size:lottieSize contentMode:[self _lottieContentMode] animationSpeed:[self _lottieAnimationSpeed]];
#endif
    }
}

- (void)updateLottie {
    if (![self.tabBarItem isKindOfClass:[CYLFlatDesignTabBarItem class]]) {
        return;
    }
    if (self.isSelected) {
        CGSize lottieSize = [[self _lottieSizeValue] CGSizeValue];
        NSURL *lottieURL = [self _lottieURL];
        if (!lottieURL) {
            return;
        }
        // The selected button can get here before `-initLottie`; add the view with the speed first (issue #428).
        [self cyl_addLottieImageWithLottieURL:lottieURL size:lottieSize contentMode:[self _lottieContentMode] animationSpeed:[self _lottieAnimationSpeed]];
        [self cyl_animationLottieImageWithLottieURL:lottieURL size:lottieSize defaultSelected:NO contentMode:[self _lottieContentMode]];
    }
    else {
//        [self cyl_stopAnimationOfLottieView];
    }
}

- (UIView *)actualBadgeSuperView {
    return self.cyl_getActualBadgeSuperView;
}

#pragma mark - VoiceOver

/*!
 * [EN] VoiceOver: the flat design tab bar is made of plain views, so a tab was read as loose pieces (its badge, then its
 *      title) with no button role or selected state. Each button is now one element: its title, the button and selected
 *      traits, and its badge as the value (set by `UIView+CYLBadgeExtention`, e.g. "Messages, 3 new messages"). A slot
 *      without a title (the one under the plus button) is not an element; the plus button is.
 * [CN] VoiceOver：扁平样式 TabBar 由普通视图组成，Tab 会被拆成零散的内容（先读角标再读标题），没有按钮角色和选中状态。现在每个按钮
 *      是一个元素：标题、按钮与选中特征，角标作为值（由 `UIView+CYLBadgeExtention` 设置，如“消息，3 条新消息”）。没有标题的位置
 *      （加号按钮下方）不作为元素，由加号按钮代替。
 */
- (BOOL)isAccessibilityElement {
    return self.accessibilityLabel.length > 0;
}

- (NSString *)accessibilityLabel {
    return [super accessibilityLabel] ?: (self.tabBarItem.title.length > 0 ? self.tabBarItem.title : self.titleLabel.text);
}

- (UIAccessibilityTraits)accessibilityTraits {
    return [super accessibilityTraits] | UIAccessibilityTraitButton | (self.isSelected ? UIAccessibilityTraitSelected : UIAccessibilityTraitNone);
}

@end
