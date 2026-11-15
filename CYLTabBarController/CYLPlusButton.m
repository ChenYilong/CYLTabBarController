//
//  CYLPlusButton.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] The Objective-C shell of `CYLPlusButton` (docs/Swift-Migration.md, step 52): the implementation is Swift
//      (`Swift/CYLPlusButton+CYLImplementation.swift`). The class stays declared in Objective-C because apps subclass it in
//      Objective-C and `CYLTabBarController.h` names it. This file keeps the C globals of CYLTabBarController.h, the overrides
//      and the public methods, each a one-line forward to a `cyl_plusButton…` method of the Swift extension, and the calls to
//      `super` the Swift code needs (`-cyl_super…`).
// [CN] `CYLPlusButton` 的 Objective-C 外壳（docs/Swift-Migration.md，第 52 步）：实现位于 Swift（`Swift/CYLPlusButton+CYLImplementation.swift`）。
//      类仍在 Objective-C 中声明，因为 App 在 Objective-C 中继承它，`CYLTabBarController.h` 也引用了它。本文件保留 CYLTabBarController.h 中的
//      C 全局变量、重写方法与公开方法（每个都是一行转发到 Swift 扩展的 `cyl_plusButton…` 方法），以及 Swift 代码需要的 `super` 调用（`-cyl_super…`）。

#import "CYLPlusButton.h"
#import "CYLTabBarController.h"
#import <objc/runtime.h>

CGFloat CYLPlusButtonWidth = 0.0f;
CYLPlusButton<CYLPlusButtonSubclassing> *CYLExternPlusButton = nil;
UIViewController *CYLPlusChildViewController = nil;

/*!
 * [EN] Internal: the plus button's own page, found by `-initWithConfiguration:` (`CYLTabBarItemPageIdentifier`).
 * [CN] 内部使用：PlusButton 自己的页面，由 `-initWithConfiguration:` 查找（`CYLTabBarItemPageIdentifier`）。
 */
NSString *const CYLConfigurationPlusButtonPageKey = @"CYLConfigurationPlusButtonPage";

/*!
 * [EN] Implemented in UIControl+CYLBadgeExtention.swift (issue #779). [CN] 在 UIControl+CYLBadgeExtention.swift 中实现（issue #779）。
 */
@interface UIControl (CYLPlusButtonBadgeLayers)
- (void)cyl_showBadgeValue:(NSString *)value animationTypeValue:(NSNumber *)animationTypeValue;
@end

/*!
 * [EN] Implemented in Swift/CYLPlusButton+CYLImplementation.swift.
 * [CN] 在 Swift/CYLPlusButton+CYLImplementation.swift 中实现。
 */
@interface CYLPlusButton (CYLPlusButtonImplementation)
- (NSString *)cyl_plusButtonAccessibilityLabel;
- (void)cyl_plusButtonSetAccessibilityLabel:(nullable NSString *)accessibilityLabel;
- (UIAccessibilityTraits)cyl_plusButtonAccessibilityTraits:(UIAccessibilityTraits)superTraits;
- (void)cyl_setUpTabLikeInteractions;
- (nullable NSString *)cyl_plusButtonLargeContentTitle:(nullable NSString *)superTitle;
- (void)cyl_plusButtonSetUpWithImage:(nullable UIImage *)image title:(nullable NSString *)title
                       selectedTitle:(nullable NSString *)selectedTitle selectedTitleColor:(nullable UIColor *)selectedTitleColor;
- (void)cyl_plusButtonSetImage:(nullable UIImage *)image forState:(UIControlState)state;
- (nullable UIImage *)cyl_plusButtonKeptImageForState:(UIControlState)state;
- (void)cyl_plusButtonSetBackgroundImage:(nullable UIImage *)image forState:(UIControlState)state;
- (void)cyl_plusButtonSetConfiguration:(nullable UIButtonConfiguration *)configuration API_AVAILABLE(ios(15.0));
- (void)cyl_plusButtonShowBadgeValue:(NSString *)value animationTypeValue:(NSNumber *)animationTypeValue;
- (void)cyl_plusButtonClearBadge;
- (NSArray<UIControl *> *)cyl_plusButtonBadgeLayerControls;
- (void)cyl_plusButtonLayoutSublayers;
- (void)cyl_plusButtonSetNeedsTitleAlignment;
- (BOOL)cyl_plusButtonShowsTitleInTabBarItem;
- (void)cyl_plusButtonTraitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection;
- (CGPoint)cyl_plusButtonCenterForCenter:(CGPoint)center;
- (void)cyl_plusButtonDidSetCenterMoved:(BOOL)moved;
- (nullable NSValue *)cyl_plusButtonDidSetFrameMoved:(BOOL)moved;
- (void)cyl_plusButtonUpdateTouchableAreaIfShown;
- (void)cyl_plusButtonDidSetSelected;
- (void)cyl_plusButtonLayoutSubviews;
- (void)cyl_plusButtonPlusChildViewControllerButtonClicked:(UIButton *)sender;
- (CGFloat)cyl_plusButtonMultiplierOfTabBarHeight:(CGFloat)tabBarHeight;
- (CGFloat)cyl_plusButtonConstantOfPlusButtonCenterYOffsetForTabBarHeight:(CGFloat)tabBarHeight;
- (BOOL)cyl_plusButtonAppliesCenterYOffsetWithoutTitle;
- (void)cyl_plusButtonSetAppliesCenterYOffsetWithoutTitle:(BOOL)appliesCenterYOffsetWithoutTitle;
- (nullable UIView *)cyl_plusButtonHitTestInteractiveSubview:(CGPoint)point withEvent:(nullable UIEvent *)event;
- (CGRect)cyl_plusButtonTouchableRectInView:(nullable UIView *)view;
- (BOOL)cyl_plusButtonTouchableAreaContainsPoint:(CGPoint)point;
- (BOOL)cyl_plusButtonReportsTapsToDelegate;
- (void)cyl_plusButtonSetReportsTapsToDelegate:(BOOL)reportsTapsToDelegate;
- (UIEdgeInsets)cyl_plusButtonTouchableAreaOutsets;
- (void)cyl_plusButtonSetTouchableAreaOutsets:(UIEdgeInsets)touchableAreaOutsets;
- (CGFloat)cyl_plusButtonTouchableAreaScale;
- (void)cyl_plusButtonSetTouchableAreaScale:(CGFloat)touchableAreaScale;
- (BOOL)cyl_plusButtonShowsTouchableArea;
- (void)cyl_plusButtonSetShowsTouchableArea:(BOOL)showsTouchableArea;
- (nullable UIColor *)cyl_plusButtonTouchableAreaColor;
- (void)cyl_plusButtonSetTouchableAreaColor:(nullable UIColor *)touchableAreaColor;
- (void)cyl_plusButtonDidMoveToSuperview;
- (void)cyl_plusButtonWillRemoveFromSuperview;
- (nullable UIButton *)cyl_plusButtonSelectedContentView;
- (void)cyl_plusButtonSetSelectedContentView:(nullable UIButton *)selectedContentView;
- (nullable NSString *)cyl_plusButtonTitle;
- (void)cyl_plusButtonUpdateTitle:(nullable NSString *)title image:(nullable UIImage *)image selectedImage:(nullable UIImage *)selectedImage;
- (void)cyl_plusButtonSetTabLabelHidden:(BOOL)hidden;
- (nullable UIImage *)cyl_plusButtonSelectedContentImage;
- (void)cyl_plusButtonSetSelectedContentImage:(nullable UIImage *)image;
- (nullable UIImage *)cyl_plusButtonContentImage;
- (void)cyl_plusButtonSetContentImage:(nullable UIImage *)image;
+ (void)cyl_plusButtonRegister;
+ (void)cyl_plusButtonRemove;
+ (void)cyl_plusButtonRemoveForTabBarContext:(nullable NSString *)tabBarContext;
+ (void)cyl_plusButtonAddSelectViewControllerTarget:(UIButton *)plusButton;
+ (nullable UIButton *)cyl_plusButtonClassSelectedContentView;
+ (nullable CYLPlusButton *)cyl_plusButtonForTabBarContext:(nullable NSString *)tabBarContext;
+ (nullable UIViewController *)cyl_plusChildViewControllerForTabBarContext:(nullable NSString *)tabBarContext;
+ (CGFloat)cyl_plusButtonWidthForTabBarContext:(nullable NSString *)tabBarContext;
+ (BOOL)cyl_plusButtonIsPlusButtonView:(nullable UIView *)view;
+ (nullable NSString *)cyl_plusButtonTabBarContextForOwner:(nullable id)owner;
+ (nullable CYLPlusButton *)cyl_plusButtonForOwner:(nullable id)owner;
+ (nullable UIViewController *)cyl_plusChildViewControllerForOwner:(nullable id)owner;
+ (CGFloat)cyl_plusButtonWidthForOwner:(nullable id)owner;
+ (NSString *)cyl_plusButtonMatchedTabBarContext;
+ (NSUInteger)cyl_plusButtonIndexForTabbarItemsCount:(NSUInteger)tabbarItemsCount;
- (void)cyl_configurationPlusButtonSetUpWithAttributes:(nullable NSDictionary<NSString *, id> *)attributes;
+ (BOOL)cyl_configurationPlusButtonAlignsTitleWithAttributes:(nullable NSDictionary<NSString *, id> *)attributes;
@end

@interface CYLPlusButton ()
@property (nonatomic, weak) UIButton *selectedContentView;
@property (nonatomic, strong) UIImage *selectedContentImage;
@property (nonatomic, strong) UIImage *contentImage;
@end

@implementation CYLPlusButton
@dynamic selectedContentView, selectedContentImage, contentImage;

#pragma mark - Life cycle, accessibility

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self cyl_setUpTabLikeInteractions];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self cyl_setUpTabLikeInteractions];
    }
    return self;
}

- (NSString *)accessibilityLabel { return [self cyl_plusButtonAccessibilityLabel]; }
- (void)setAccessibilityLabel:(NSString *)accessibilityLabel { [self cyl_plusButtonSetAccessibilityLabel:accessibilityLabel]; }
- (UIAccessibilityTraits)accessibilityTraits { return [self cyl_plusButtonAccessibilityTraits:[super accessibilityTraits]]; }
- (NSString *)largeContentTitle { return [self cyl_plusButtonLargeContentTitle:[super largeContentTitle]]; }
- (UIImage *)largeContentImage { return [super largeContentImage] ?: self.currentImage; }

+ (instancetype)cyl_plusButtonWithImage:(UIImage *)image
                                  title:(NSString *)title
                          selectedTitle:(NSString *)selectedTitle
                     selectedTitleColor:(UIColor *)selectedTitleColor {
    CYLPlusButton *button = [[self alloc] init];
    [button cyl_plusButtonSetUpWithImage:image title:title selectedTitle:selectedTitle selectedTitleColor:selectedTitleColor];
    return button;
}

#pragma mark - Overrides

- (void)setImage:(UIImage *)image forState:(UIControlState)state { [self cyl_plusButtonSetImage:image forState:state]; }
- (UIImage *)imageForState:(UIControlState)state { return [self cyl_plusButtonKeptImageForState:state] ?: [super imageForState:state]; }
- (void)setBackgroundImage:(UIImage *)image forState:(UIControlState)state { [self cyl_plusButtonSetBackgroundImage:image forState:state]; }
- (void)setConfiguration:(UIButtonConfiguration *)configuration { [self cyl_plusButtonSetConfiguration:configuration]; }
- (void)cyl_showBadgeValue:(NSString *)value animationTypeValue:(NSNumber *)animationTypeValue {
    [self cyl_plusButtonShowBadgeValue:value animationTypeValue:animationTypeValue];
}
- (void)cyl_clearBadge { [self cyl_plusButtonClearBadge]; }
- (NSArray<UIControl *> *)cyl_badgeLayerControls { return [self cyl_plusButtonBadgeLayerControls]; }

/// [EN] A subclass's `-layoutSubviews` runs inside this call, so the alignment comes after every layout. [CN] 子类的 `-layoutSubviews` 在此调用之内执行，对齐总在每次布局之后。
- (void)layoutSublayersOfLayer:(CALayer *)layer {
    [super layoutSublayersOfLayer:layer];
    if (layer == self.layer) {
        [self cyl_plusButtonLayoutSublayers];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self cyl_plusButtonTraitCollectionDidChange:previousTraitCollection];
}

- (void)setCenter:(CGPoint)center {
    center = [self cyl_plusButtonCenterForCenter:center];
    BOOL moved = !CGPointEqualToPoint(center, self.center);
    [super setCenter:center];
    [self cyl_plusButtonDidSetCenterMoved:moved];
}

- (void)setFrame:(CGRect)frame {
    BOOL moved = !CGRectEqualToRect(frame, self.frame);
    [super setFrame:frame];
    NSValue *center = [self cyl_plusButtonDidSetFrameMoved:moved];
    if (center) {
        [super setCenter:center.CGPointValue];
    }
    [self cyl_plusButtonUpdateTouchableAreaIfShown];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    [self cyl_plusButtonDidSetSelected];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self cyl_plusButtonLayoutSubviews];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return [super pointInside:point withEvent:event] || [self cyl_plusButtonTouchableAreaContainsPoint:point];
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self cyl_plusButtonDidMoveToSuperview];
}

- (void)removeFromSuperview {
    [self cyl_plusButtonWillRemoveFromSuperview];
    [super removeFromSuperview];
}

- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    [self cyl_plusButtonUpdateTouchableAreaIfShown];
}

#pragma mark - For the Swift extension

/*!
 * [EN] Points the C globals at a registration (nil clears them); they are nonnull in CYLTabBarController.h, so Swift cannot.
 * [CN] 让 C 全局变量指向某个注册内容（nil 时清空）；它们在 CYLTabBarController.h 中为 nonnull，Swift 无法置空。
 */
+ (void)cyl_mirrorLegacyGlobalsWithPlusButton:(CYLPlusButton *)plusButton
                      plusChildViewController:(UIViewController *)plusChildViewController
                                        width:(CGFloat)width {
    CYLExternPlusButton = (CYLPlusButton<CYLPlusButtonSubclassing> *)plusButton;
    CYLPlusChildViewController = plusChildViewController;
    CYLPlusButtonWidth = width;
}


- (UIImage *)cyl_superImageForState:(UIControlState)state { return [super imageForState:state]; }
- (void)cyl_superSetImage:(UIImage *)image forState:(UIControlState)state { [super setImage:image forState:state]; }
- (UIImage *)cyl_superBackgroundImageForState:(UIControlState)state { return [super backgroundImageForState:state]; }
- (void)cyl_superSetBackgroundImage:(UIImage *)image forState:(UIControlState)state { [super setBackgroundImage:image forState:state]; }
- (void)cyl_superSetConfiguration:(UIButtonConfiguration *)configuration { [super setConfiguration:configuration]; }
- (void)cyl_superShowBadgeValue:(NSString *)value animationTypeValue:(NSNumber *)animationTypeValue {
    [super cyl_showBadgeValue:value animationTypeValue:animationTypeValue];
}
- (void)cyl_superClearBadge { [super cyl_clearBadge]; }

#pragma mark - Public API

- (void)cyl_setNeedsTitleAlignment { [self cyl_plusButtonSetNeedsTitleAlignment]; }
- (BOOL)cyl_showsTitleInTabBarItem { return [self cyl_plusButtonShowsTitleInTabBarItem]; }
- (UIEdgeInsets)touchableAreaOutsets { return [self cyl_plusButtonTouchableAreaOutsets]; }
- (void)setTouchableAreaOutsets:(UIEdgeInsets)outsets { [self cyl_plusButtonSetTouchableAreaOutsets:outsets]; }
- (BOOL)reportsTapsToDelegate { return [self cyl_plusButtonReportsTapsToDelegate]; }
- (void)setReportsTapsToDelegate:(BOOL)reports { [self cyl_plusButtonSetReportsTapsToDelegate:reports]; }
- (CGFloat)touchableAreaScale { return [self cyl_plusButtonTouchableAreaScale]; }
- (void)setTouchableAreaScale:(CGFloat)scale { [self cyl_plusButtonSetTouchableAreaScale:scale]; }
- (BOOL)showsTouchableArea { return [self cyl_plusButtonShowsTouchableArea]; }
- (void)setShowsTouchableArea:(BOOL)shows { [self cyl_plusButtonSetShowsTouchableArea:shows]; }
- (UIColor *)touchableAreaColor { return [self cyl_plusButtonTouchableAreaColor]; }
- (void)setTouchableAreaColor:(UIColor *)color { [self cyl_plusButtonSetTouchableAreaColor:color]; }
- (CGRect)touchableRectInView:(UIView *)view { return [self cyl_plusButtonTouchableRectInView:view]; }
- (UIView *)hitTestInteractiveSubview:(CGPoint)point withEvent:(UIEvent *)event {
    return [self cyl_plusButtonHitTestInteractiveSubview:point withEvent:event];
}
- (BOOL)cyl_appliesCenterYOffsetWithoutTitle { return [self cyl_plusButtonAppliesCenterYOffsetWithoutTitle]; }
- (void)cyl_setAppliesCenterYOffsetWithoutTitle:(BOOL)applies { [self cyl_plusButtonSetAppliesCenterYOffsetWithoutTitle:applies]; }
- (void)plusChildViewControllerButtonClicked:(UIButton<CYLPlusButtonSubclassing> *)sender {
    [self cyl_plusButtonPlusChildViewControllerButtonClicked:sender];
}
- (CGFloat)multiplierOfTabBarHeight:(CGFloat)tabBarHeight { return [self cyl_plusButtonMultiplierOfTabBarHeight:tabBarHeight]; }
- (CGFloat)constantOfPlusButtonCenterYOffsetForTabBarHeight:(CGFloat)tabBarHeight {
    return [self cyl_plusButtonConstantOfPlusButtonCenterYOffsetForTabBarHeight:tabBarHeight];
}
- (void)setTabLabelHidden:(BOOL)hidden { [self cyl_plusButtonSetTabLabelHidden:hidden]; }
- (NSString *)cyl_title { return [self cyl_plusButtonTitle]; }
- (void)cyl_updateTitle:(NSString *)title image:(UIImage *)image selectedImage:(UIImage *)selectedImage {
    [self cyl_plusButtonUpdateTitle:title image:image selectedImage:selectedImage];
}
- (UIButton *)selectedContentView { return [self cyl_plusButtonSelectedContentView]; }
- (void)setSelectedContentView:(UIButton *)view { [self cyl_plusButtonSetSelectedContentView:view]; }
- (UIImage *)selectedContentImage { return [self cyl_plusButtonSelectedContentImage]; }
- (void)setSelectedContentImage:(UIImage *)image { [self cyl_plusButtonSetSelectedContentImage:image]; }
- (UIImage *)contentImage { return [self cyl_plusButtonContentImage]; }
- (void)setContentImage:(UIImage *)image { [self cyl_plusButtonSetContentImage:image]; }

+ (void)registerPlusButton { [self cyl_plusButtonRegister]; }
+ (void)removePlusButton { [self cyl_plusButtonRemove]; }
+ (void)removePlusButtonForTabBarContext:(NSString *)tabBarContext { [self cyl_plusButtonRemoveForTabBarContext:tabBarContext]; }
+ (void)addSelectViewControllerTarget:(UIButton<CYLPlusButtonSubclassing> *)plusButton { [self cyl_plusButtonAddSelectViewControllerTarget:plusButton]; }
+ (UIButton *)selectedContentView { return [self cyl_plusButtonClassSelectedContentView]; }
+ (UIImage *)contentImage { return nil; }
+ (UIImage *)selectedContentImage { return nil; }
+ (BOOL)hasPlusButtonForTabBarContext:(NSString *)tabBarContext { return [self plusButtonForTabBarContext:tabBarContext] != nil; }
+ (BOOL)hasPlusChildViewControllerForTabBarContext:(NSString *)tabBarContext {
    return [self plusChildViewControllerForTabBarContext:tabBarContext] != nil;
}
+ (CYLPlusButton<CYLPlusButtonSubclassing> *)plusButtonForTabBarContext:(NSString *)tabBarContext {
    return (CYLPlusButton<CYLPlusButtonSubclassing> *)[self cyl_plusButtonForTabBarContext:tabBarContext];
}
+ (UIViewController *)plusChildViewControllerForTabBarContext:(NSString *)tabBarContext {
    return [self cyl_plusChildViewControllerForTabBarContext:tabBarContext];
}
+ (CGFloat)plusButtonWidthForTabBarContext:(NSString *)tabBarContext { return [self cyl_plusButtonWidthForTabBarContext:tabBarContext]; }
+ (BOOL)isPlusButtonView:(UIView *)view { return [self cyl_plusButtonIsPlusButtonView:view]; }
+ (NSString *)tabBarContextForOwner:(id)owner { return [self cyl_plusButtonTabBarContextForOwner:owner]; }
+ (CYLPlusButton<CYLPlusButtonSubclassing> *)plusButtonForOwner:(id)owner {
    return (CYLPlusButton<CYLPlusButtonSubclassing> *)[self cyl_plusButtonForOwner:owner];
}
+ (UIViewController *)plusChildViewControllerForOwner:(id)owner { return [self cyl_plusChildViewControllerForOwner:owner]; }
+ (CGFloat)plusButtonWidthForOwner:(id)owner { return [self cyl_plusButtonWidthForOwner:owner]; }
+ (NSString *)matchedTabBarContext { return [self cyl_plusButtonMatchedTabBarContext]; }
+ (NSUInteger)indexForTabbarItemsCount:(NSUInteger)count { return [self cyl_plusButtonIndexForTabbarItemsCount:count]; }

CYL_DEPRECATED_IGNORED_IMPLEMENTATIONS_PUSH
+ (void)registerSubclass {
    [self registerPlusButton];
}
CYL_DEPRECATED_IGNORED_IMPLEMENTATIONS_POP

@end

#pragma mark - A plus button from attributes (CYLTabBarControllerPlusButton)

static const void *CYLConfigurationPlusButtonEntryKey = &CYLConfigurationPlusButtonEntryKey;
static NSString *const CYLConfigurationPlusButtonAttributesKey = @"attributes";
static NSString *const CYLConfigurationPlusButtonActionKey = @"action";
static NSString *const CYLConfigurationPlusButtonContextKey = @"context";
static NSString *const CYLConfigurationPlusButtonDefaultContext = @"CYLTabBarController";

/*!
 * [EN] The plus button of `CYLTabBarControllerPlusButton`. Each registration makes a subclass of its own at run time, which holds
 *      that configuration's attributes, action and context, and gets only the class methods its keys ask for: optional methods
 *      such as `+indexOfPlusButtonInTabBar` change the library's behavior just by being there. It stays in Objective-C: Swift's
 *      `type(of:)` and class methods skip run-time subclasses of a Swift class (docs/Swift-Migration.md, step 52). The button's
 *      setup is Swift (`-cyl_configurationPlusButtonSetUpWithAttributes:`).
 * [CN] `CYLTabBarControllerPlusButton` 的 PlusButton。每次注册在运行时生成一个自己的子类，保存该配置的属性、点击回调与 context，并且只添加其键所需的
 *      类方法：`+indexOfPlusButtonInTabBar` 等可选方法只要存在就会改变库的行为。它保留在 Objective-C 中：Swift 的 `type(of:)` 与类方法会跳过 Swift 类的
 *      运行时子类（docs/Swift-Migration.md，第 52 步）。按钮的设置在 Swift 中（`-cyl_configurationPlusButtonSetUpWithAttributes:`）。
 */
@interface CYLConfigurationPlusButton : CYLPlusButton <CYLPlusButtonSubclassing>
@end

@implementation CYLConfigurationPlusButton

+ (NSDictionary *)cyl_configurationEntry {
    return objc_getAssociatedObject(self, CYLConfigurationPlusButtonEntryKey);
}

+ (id)plusButton {
    CYLConfigurationPlusButton *button = [[self alloc] init];
    [button cyl_configurationPlusButtonSetUpWithAttributes:[self cyl_configurationEntry][CYLConfigurationPlusButtonAttributesKey]];
    return button;
}

+ (NSString *)tabBarContext {
    return [self cyl_configurationEntry][CYLConfigurationPlusButtonContextKey] ?: CYLConfigurationPlusButtonDefaultContext;
}

+ (BOOL)alignsTitleWithTabBarItemTitles {
    return [self cyl_configurationPlusButtonAlignsTitleWithAttributes:[self cyl_configurationEntry][CYLConfigurationPlusButtonAttributesKey]];
}

- (void)cyl_configurationPlusButtonTapped {
    void (^action)(CYLPlusButton *) = [[self class] cyl_configurationEntry][CYLConfigurationPlusButtonActionKey];
    !action ?: action(self);
}

/// [EN] Adds the optional class methods the attributes ask for. [CN] 添加属性所需的可选类方法。
+ (void)cyl_addClassMethodsForAttributes:(NSDictionary<NSString *, id> *)attributes {
    Class metaClass = object_getClass(self);
    if ([attributes[CYLPlusButtonIndexInTabBar] isKindOfClass:[NSNumber class]]) {
        NSUInteger index = [attributes[CYLPlusButtonIndexInTabBar] unsignedIntegerValue];
        class_addMethod(metaClass, @selector(indexOfPlusButtonInTabBar), imp_implementationWithBlock(^NSUInteger(id cls) {
            return index;
        }), "Q@:");
    }
    if ([attributes[CYLPlusButtonCenterYMultiplier] isKindOfClass:[NSNumber class]]) {
        CGFloat multiplier = [attributes[CYLPlusButtonCenterYMultiplier] doubleValue];
        class_addMethod(metaClass, @selector(multiplierOfTabBarHeight:), imp_implementationWithBlock(^CGFloat(id cls, CGFloat tabBarHeight) {
            return multiplier;
        }), "d@:d");
    }
    if ([attributes[CYLPlusButtonCenterYOffset] isKindOfClass:[NSNumber class]]) {
        CGFloat offset = [attributes[CYLPlusButtonCenterYOffset] doubleValue];
        class_addMethod(metaClass, @selector(constantOfPlusButtonCenterYOffsetForTabBarHeight:), imp_implementationWithBlock(^CGFloat(id cls, CGFloat tabBarHeight) {
            return offset;
        }), "d@:d");
    }
    NSString *identifier = attributes[CYLTabBarItemIdentifier];
    if ([identifier isKindOfClass:[NSString class]] && identifier.length > 0) {
        class_addMethod(metaClass, @selector(tabBarItemIdentifier), imp_implementationWithBlock(^NSString *(id cls) {
            return identifier;
        }), "@@:");
    }
    UIViewController *page = attributes[CYLConfigurationPlusButtonPageKey];
    if ([page isKindOfClass:[UIViewController class]]) {
        class_addMethod(metaClass, @selector(plusChildViewController), imp_implementationWithBlock(^UIViewController *(id cls) {
            return page;
        }), "@@:");
    }
}

@end

@implementation CYLPlusButton (CYLConfigurationPlusButton)

+ (void)cyl_registerPlusButtonWithAttributes:(NSDictionary<NSString *, id> *)attributes
                                      action:(void (^)(CYLPlusButton *))action
                                     context:(NSString *)context {
    BOOL hasImage = [attributes[CYLTabBarItemImage] isKindOfClass:[UIImage class]]
        || [attributes[CYLPlusButtonBackgroundImage] isKindOfClass:[UIImage class]];
    if (!hasImage) {
        return;
    }
    static NSUInteger counter = 0;
    NSString *className = [NSString stringWithFormat:@"CYLConfigurationPlusButton_%lu", (unsigned long)++counter];
    Class class = objc_allocateClassPair([CYLConfigurationPlusButton class], className.UTF8String, 0);
    if (!class) {
        return;
    }
    objc_registerClassPair(class);
    NSMutableDictionary *entry = [NSMutableDictionary dictionary];
    entry[CYLConfigurationPlusButtonAttributesKey] = [attributes copy];
    entry[CYLConfigurationPlusButtonContextKey] = context.length > 0 ? [context copy] : CYLConfigurationPlusButtonDefaultContext;
    if (action) {
        entry[CYLConfigurationPlusButtonActionKey] = [action copy];
    }
    objc_setAssociatedObject(class, CYLConfigurationPlusButtonEntryKey, [entry copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [(Class)class cyl_addClassMethodsForAttributes:attributes];
    [(Class)class registerPlusButton];
}

@end
