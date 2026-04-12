//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CYLConstants.h"

NS_ASSUME_NONNULL_BEGIN
@protocol UIKitPortalViewProtocol <NSObject>

@property(nonatomic) __weak UIView * _Nullable sourceView;
@property(nonatomic) _Bool forwardsClientHitTestingToSourceView;
@property(nonatomic) _Bool allowsHitTesting; // @dynamic allowsHitTesting;
@property(nonatomic) _Bool allowsBackdropGroups; // @dynamic allowsBackdropGroups;
@property(nonatomic) _Bool matchesPosition; // @dynamic matchesPosition;
@property(nonatomic) _Bool matchesTransform; // @dynamic matchesTransform;
@property(nonatomic) _Bool matchesAlpha; // @dynamic matchesAlpha;
@property(nonatomic) _Bool hidesSourceView; // @dynamic hidesSourceView;

@end

@interface UIView (CYLTabBarControllerExtention)

- (BOOL)cyl_isPlusButton;
- (BOOL)cyl_isTabButton;
- (BOOL)cyl_isPlatterView;
- (BOOL)cyl_isPlatterContentView;
- (BOOL)cyl_isPlatterSelectedContentView;
- (BOOL)cyl_isPlatterPortalView;
- (BOOL)cyl_isPlatterLiquidLensView;
- (BOOL)cyl_isPlatterDestOutView;

- (BOOL) cyl_isPlatterLiquidLensClearGlassView;

- (BOOL) cyl_isPlatterLiquidLensTabSelectionView;

- (BOOL) cyl_isPlatterLiquidLensBackdropView;
- (BOOL)cyl_isPlatterVisualProviderFloatingSelectedContentView;

- (BOOL)cyl_isTabImageView;
- (BOOL)cyl_isTabLabel;
- (BOOL)cyl_isTabBadgeView;
- (BOOL)cyl_isTabBackgroundView;
- (UIView *)cyl_tabBadgeView;
- (UIImageView *)cyl_tabImageView;
- (UILabel *)cyl_tabLabel;
- (UIImageView *)cyl_tabShadowImageView;
- (UIVisualEffectView *)cyl_tabEffectView;
- (BOOL)cyl_isLottieAnimationView;
- (UIView *)cyl_tabBackgroundView;
+ (UIView *)cyl_tabBadgePointViewWithClolor:(UIColor *)color radius:(CGFloat)radius;
- (NSArray *)cyl_allSubviews;
- (UIImageView *)cyl_imageViewInTabBarButton;
- (void)cyl_bringSubviewToFront:(UIView *)view;
//- (void)cyl_addThenBringSubviewToFront:(UIView *)view;
- (void)cyl_addPlatterViewThenBringSubviewToFront:(UIView *)view;
- (UIView * _Nullable)cyl_makePortalView:(BOOL)matchPosition portalView:(UIView<UIKitPortalViewProtocol> *)portalView  sourceView:(UIView *)sourceView;
- (UIView * _Nullable)cyl_getPortalViewSourceView:(UIView * _Nonnull)portalView;
- (UIImageView *)cyl_swappableImageViewViewInTabBarButton;
- (UIImage *)cyl_takeSnapshot;
- (void)cyl_setHidden:(BOOL)hidden;

@end

@interface UIView (CYLTabBarControllerExtentionDeprecated)
- (UIView *)cyl_tabBadgeBackgroundView CYL_DEPRECATED("Deprecated in 1.6.0. Use `+[CYLPlusButton cyl_tabBackgroundView]` instead.");
- (UIView *)cyl_tabBadgeBackgroundSeparator CYL_DEPRECATED("Deprecated in 1.6.0. Use `+[CYLPlusButton cyl_tabShadowImageView]` instead.");

@end

NS_ASSUME_NONNULL_END
