//
//  CYLTabBarController-Swift.h
//  CYLTabBarItemAnimation tests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] Stand-in for the header Swift generates for the library, with only what the subspec sources under test use: the
//      protocols declared in Swift (Swift/CYLTabBarItemAnimationService.swift and
//      Swift/CYLTabBarItemAnimationPlayableView.swift), with their selectors. The real header needs the full UIKit, which
//      this macOS harness only stubs. Keep the selectors in step with the Swift declarations.
// [CN] 库的 Swift 生成头文件的替身，只包含被测试的子库源码用到的内容：在 Swift 中声明的协议（Swift/CYLTabBarItemAnimationService.swift 与
//      Swift/CYLTabBarItemAnimationPlayableView.swift）及其 selector。真实的头文件需要完整的 UIKit，而本 macOS 测试只有 UIKit 的桩。修改时请与
//      Swift 声明保持一致。

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CYLTabBarItemAnimationStyleSource <NSObject>
- (BOOL)hasStyleVariants;
- (BOOL)hasStyleVariantForURL:(nullable NSURL *)URL;
- (nullable NSURL *)URL:(nullable NSURL *)URL forTraitCollection:(nullable UITraitCollection *)traitCollection;
- (nullable NSDictionary<NSString *, UIColor *> *)darkColorsForURL:(nullable NSURL *)URL;
@optional
- (nullable NSDictionary<NSString *, UIColor *> *)colorsForURL:(nullable NSURL *)URL;
@end

@protocol CYLTabBarItemAnimationHost <NSObject>
- (BOOL)isPlusControl:(UIControl *)control;
- (BOOL)isAnimationView:(nullable UIView *)animationView readyInControl:(UIControl *)control;
- (CGSize)defaultAnimationSize;
- (void)showAnimationView:(UIView *)animationView inControl:(UIControl *)control;
- (void)replaceTrackedSubview:(UIView *)view withView:(UIView *)newView inSuperview:(UIView *)superview;
- (void)animationViewDidAddInControl:(UIControl *)control;
- (void)animationWillPlayInControl:(UIControl *)control;
@end

@protocol CYLTabBarItemAnimationService <NSObject>
- (nullable UIView *)animationViewInControl:(UIControl *)control;
- (BOOL)isAnimationView:(UIView *)view;
- (BOOL)isAnimationReadyInControl:(UIControl *)control;
- (void)addAnimationWithURL:(nullable NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode
             animationSpeed:(CGFloat)animationSpeed toControl:(UIControl *)control;
- (void)setAnimationSpeed:(CGFloat)animationSpeed inControl:(UIControl *)control;
- (void)reloadAnimationForCurrentStyleInControl:(UIControl *)control;
- (void)playAnimationWithURL:(NSURL *)URL size:(CGSize)size defaultSelected:(BOOL)defaultSelected
                 contentMode:(UIViewContentMode)contentMode inControl:(UIControl *)control;
- (void)stopAnimationInControl:(UIControl *)control;
- (nullable NSString *)attributeKeyForGenericKey:(NSString *)genericKey inAttributes:(NSDictionary *)attributes;
- (void)bindAnimationURL:(NSURL *)URL toAttributes:(NSDictionary *)attributes;
@optional
- (void)replaceAnimationWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode inControl:(UIControl *)control;
- (void)refreshAnimationColorsInControl:(UIControl *)control;
- (NSArray<NSString *> *)animationFileExtensions;
- (void)restartAnimationInControl:(UIControl *)control;
- (void)setAnimationLoops:(BOOL)loops inControl:(UIControl *)control;
@end

@protocol CYLTabBarItemAnimationPlayableView <NSObject>
- (void)cyl_playAnimationView;
- (void)cyl_showAnimationViewLastFrame;
- (void)cyl_stopAnimationView;
@optional
- (void)cyl_applyAnimationViewColors:(nullable NSDictionary<NSString *, UIColor *> *)colors;
@end

@protocol CYLTabBarItemAnimationViewProviding <NSObject>
+ (nullable UIView<CYLTabBarItemAnimationPlayableView> *)cyl_animationViewWithFileURL:(NSURL *)fileURL
                                                                             options:(NSDictionary<NSString *, NSString *> *)options
                                                                         contentMode:(UIViewContentMode)contentMode;
@end

NS_ASSUME_NONNULL_END
