//
//  CYLTabBar.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLFlatDesignTabBar.h"
#import "CYLTabBar.h"
#import "CYLPlusButton.h"
#import "CYLTabBarController.h"
#import "CYLConstants.h"
#import "UIControl+CYLTabBarControllerExtention.h"
#import "CYLTabBar+CYLTabBarControllerExtention.h"
#import "UIImage+CYLTabBarControllerExtention.h"

@interface CYLFlatDesignTabBar ()
@property (nonatomic, weak) UIVisualEffectView *blurView;
@property (nonatomic, weak) UIView *backgroundView;

@property (nonatomic, weak) UILongPressGestureRecognizer *lpGR;
@property (nonatomic, strong) UIColor *lightBlackWhiteColor;
@end

@implementation CYLFlatDesignTabBar
{
    CGSize _tabBarItemSize;
    CGSize _popBtnSize;
    CGFloat _blurPlusY;
}

- (NSMutableArray<CYLFlatDesignTabBarItem *> *)tabBarItems {
    if (!_tabBarItems) { _tabBarItems = [NSMutableArray array]; }
    return _tabBarItems;
}

- (UIColor *)lightBlackWhiteColor {
    if (!_lightBlackWhiteColor) {
        _lightBlackWhiteColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return CYLRGBColor(207, 208, 227);
            } else {
                return CYLRGBColor(74, 74, 74);
            }
        }];
    }
    return _lightBlackWhiteColor;
}

#pragma mark - plusFrame and tabBarItemFrameWithIndex

- (CGFloat)tabItemWidth {
    CYLTabBarItemWidth = (CYLScreenWidth() - CYLPlusButtonWidth) / CYLTabbarItemsCount;
    //        CYLTabBarItemWidth = (tabBarWidth) / CYLTabbarItemsCount;
    return CYLTabBarItemWidth;
}

- (CGFloat)plusWidth {
    return CYLPlusButtonWidth;
}

- (CGRect)plusFrame {
    return CGRectMake(CYLHalfOfDiff(CYLScreenWidth(), [self plusWidth]), 0, [self plusWidth], CYLTabBarHeight);
}

- (CGRect)tabBarItemFrameWithIndex:(NSInteger)index {
    CGFloat w = [self tabItemWidth];
    CGFloat h = CYLTabBarHeight;
    CGFloat x = 0;
    if (index > 1) {
        x = CYLScreenWidth() - w - (3 - index) * (w + CYLScaleValue(2));
    } else {
        x = index * (w + CYLScaleValue(2));
    }
    CGFloat y = 0;
    
    return CGRectMake(x, y, w, h);
}

#pragma mark -

- (instancetype)init {
    if (self = [super initWithFrame:CGRectMake(0, 0, CYLScreenWidth(), self.cyl_fullHeight)]) {
        
#if defined(DEBUG) || defined(BETA)
        //        self.backgroundColor = UIColor.redColor;
        self.backgroundColor = UIColor.clearColor;
        
#else
        self.backgroundColor = UIColor.clearColor;
#endif
        
        if (@available(iOS 26.0, *)) {
            UIGlassEffect *effect = [UIGlassEffect effectWithStyle:UIGlassEffectStyleRegular];
            UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:effect];
            blurView.frame = CGRectMake(0, 0, CYLScreenWidth(), CYLScreenWidth());
            blurView.layer.cornerRadius = CYLScaleValue(16);
            blurView.layer.masksToBounds = YES;
            blurView.clipsToBounds = NO;

            [self addSubview:blurView];
            self.blurView = blurView;
        } else {
            UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
            UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:effect];
            blurView.frame = CGRectMake(0, 0, CYLScreenWidth(), CYLScreenWidth());
            blurView.layer.cornerRadius = CYLScaleValue(16);
            blurView.layer.masksToBounds = YES;
            blurView.clipsToBounds = NO;

            [self addSubview:blurView];
            self.blurView = blurView;
        }
        
        _tabBarItemSize = CGSizeMake([self tabItemWidth]?: CYLScaleValue(70),  CYLTabBarHeight);
        _popBtnSize = CGSizeMake(CYLScaleValue(80),  CYLTabBarHeight);
        UIView *plusSuperView = [[UIView alloc]
                                 initWithFrame:[self plusFrame]
                                 
        ];
        plusSuperView.clipsToBounds = NO;

        self.clipsToBounds = NO;
        // UIView *plusSuperView = CYLExternPlusButton;
        [self addSubview:plusSuperView];
        
#if defined(DEBUG) || defined(BETA)
        plusSuperView.backgroundColor = [UIColor clearColor];
#else
#endif
        
        self.plusSuperView = plusSuperView;
        UIButton<CYLPlusButtonSubclassing> *plusView = (UIButton<CYLPlusButtonSubclassing> *)CYLExternPlusButton;
        plusView.frame = plusSuperView.bounds;
        
        //        CYLBaseView *plusView = [[CYLBaseView alloc] initWithFrame:plusSuperView.bounds];
        plusView.layer.contentsGravity = kCAGravityCenter;
        
        if (@available(iOS 13.0, *)) {
            plusView.layer.contentsScale = CYLGetRootWindow().windowScene.screen.scale;
        }
        //        plusView.image = [UIImage imageNamed:@"home_normal"];
        //        plusView.scale = 1.15;
        //        plusView.scaleDuration = 0.2;
        //        plusView.isJudgeBegin = YES;
        [plusSuperView cyl_bringSubviewToTop:plusView];
        self.plusView = plusView;
        
        //        __weak typeof(self) wSelf = self;
        //        plusView.viewTouchUpInside = ^(CYLBaseView *bounceView) {
        //            __strong typeof(wSelf) sSelf = wSelf;
        //            if (!sSelf) return;
        //            [sSelf didClickPlus];
        //        };
        
        UILongPressGestureRecognizer *lpGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        lpGR.minimumPressDuration = 0.4;
//        [plusView addGestureRecognizer:lpGR];
        self.lpGR = lpGR;
        
        _blurPlusY = -(CYLScaleValue(212) + CYLGetRootWindow().safeAreaInsets.bottom);
//        [self setSelectedIndex:0];
        _defaultSelectedIndex = 0;
    }
    return self;
}

#pragma mark - 重写父类方法

- (void)addSubview:(UIView *)view {
    if (![self isKindOfClass:[UITabBar class]]) {
        [super addSubview:view];
        return;
    }
    if ([view isKindOfClass:[UITabBar class]]) {
        //为了防止类似这样的异常代码，自己添加自己：`[self.tabBar addSubview:myTabBar]`(这是异常逻辑， 解决办法是请使用  KVC: `[self cyl_setValue:myTabBar forKey:@"tabBar"]`)
        return;
    }
    if ([view cyl_isPlatterView]) {
        //不再添加 cyl_PlatterView。效果与隐藏  cyl_PlatterView（ `[view cyl_setHidden:YES];` ）相同，
        // [view cyl_setHidden:YES];
        return;
    }
    //plusButton可能会超出TabBar，故设置不裁剪
    if (YES == view.clipsToBounds) {
        view.clipsToBounds = NO;
    }
    [super addSubview:view];
}

- (void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if ([self isKindOfClass:[UITabBar class]]) {
        if ([gestureRecognizer cyl_isContinuousGestureRecognizer]) {
            gestureRecognizer.enabled = NO;
        }
        if ([gestureRecognizer cyl_isLongGestureRecognizer]) {
//            gestureRecognizer.delegate = self;
            gestureRecognizer.enabled = NO;

        }

    }
//
    [super addGestureRecognizer:gestureRecognizer];
}

//- (void)addSubview:(UIView *)view {
//    if ([self isKindOfClass:[UITabBar class]]) {
//        if ([view isKindOfClass:NSClassFromString(@"UIKit._UITabBarPlatterView")]) {
//            [view cyl_setHidden:YES];
//        }
//    }
//    if (![view isKindOfClass:[UITabBar class]]) {
//        [super addSubview:view];
//    }
//
//}
//
//- (void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
//    if ([self isKindOfClass:[UITabBar class]]) {
//        if ([gestureRecognizer isKindOfClass:NSClassFromString(@"_UIContinuousSelectionGestureRecognizer")]) {
//            gestureRecognizer.enabled = NO;
//        }
//    }
//    [super addGestureRecognizer:gestureRecognizer];
//}


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint location = [gestureRecognizer locationInView:self];
    UIView *hitView = [self hitTest:location withEvent:nil];
    if ([hitView isKindOfClass:[CYLFlatDesignTabBarItem class]]) {
        return NO;
    }
    if ([hitView isKindOfClass:[CYLPlusButton class]]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.plusing) {
        return YES;
    }
    BOOL inside = [super pointInside:point withEvent:event];
    if (inside) {
        if (CGRectContainsPoint(self.plusSuperView.frame, point)) {
            //TODO: plus button vs touch event?
            // self.plusView.isTouching = YES;
            return inside;
        }
        for (CYLFlatDesignTabBarItem *item in self.tabBarItems) {
            if (CGRectContainsPoint(item.frame, point)) {
                //TODO:   plus button vs touch event?
                item.isTouching = YES;
                
                return inside;
            }
        }
    }
    return inside;
}

#pragma mark - 添加贴吧

- (CYLFlatDesignTabBarItem *)addItemWithTitle:(NSString *)title
                              tabBarItemImage:(id)tabBarItemImage
                      tabBarItemSelectedImage:(id)tabBarItemSelectedImage
                                        index:(NSInteger)index
                      titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                                  imageInsets:(UIEdgeInsets)imageInsets
                               lottieFilePath:(NSString *)lottieFilePath
                              lottieSizeValue:(NSValue *)lottieSizeValue {
    CYLFlatDesignTabBarItem *tabBarItem = [[CYLFlatDesignTabBarItem alloc] initWithFrame:[self tabBarItemFrameWithIndex:index]
                                                                                   title:title
                                                                         tabBarItemImage:tabBarItemImage
                                                                 tabBarItemSelectedImage:tabBarItemSelectedImage
                                                                                   index:index
                                                                 titlePositionAdjustment:titlePositionAdjustment
                                                                             imageInsets:imageInsets
                                                                          lottieFilePath:lottieFilePath
                                                                         lottieSizeValue:lottieSizeValue];
    tabBarItem.tag = index;
    tabBarItem.isSelected = index == 0;
    
    __weak typeof(self) wSelf = self;
    
    void (^viewTouchUpInside)(CYLBaseView *bounceView) =
    ^(CYLBaseView *bounceView) {
        __strong typeof(wSelf) sSelf = wSelf;
        NSInteger tag = bounceView.tag;
        if (tag < 0) {
            tag = 0;
        }
        if (!sSelf ) {
            return;
        }
        
        sSelf.selectedIndex = tag;
        if (!sSelf.wlDelegate) {
            sSelf.wlDelegate = self.cyl_tabBarController;
        }

        [sSelf.wlDelegate tabBar:sSelf didSelectItemAt:sSelf.selectedIndex];
    };
    tabBarItem.viewTouchUpInside = viewTouchUpInside;
    if (index == self.defaultSelectedIndex) {
         viewTouchUpInside(tabBarItem);
    }
    
    [self.tabBarItems addObject:tabBarItem];
    if (self.plusSuperView) {
        [self insertSubview:tabBarItem belowSubview:self.plusSuperView];
    } else {
        [self addSubview:tabBarItem];
    }
    
    return tabBarItem;
}

#pragma mark - 自定义贴吧的点击响应

- (void)stopAnimationOfAllLottieView {
#if __has_include(<Lottie/Lottie.h>)
    if ([self isKindOfClass:[CYLFlatDesignTabBar class]]) {
        CYLFlatDesignTabBar *flatDesignTabBar = (CYLFlatDesignTabBar *)self;
        [flatDesignTabBar.tabBarItems enumerateObjectsUsingBlock:^(UIControl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj cyl_stopAnimationOfLottieView];
        }];
        
    }
#endif
    
    
#if __has_include(<Lottie/Lottie-Swift.h>)
    if ([self isKindOfClass:[CYLFlatDesignTabBar class]]) {
        CYLFlatDesignTabBar *flatDesignTabBar = (CYLFlatDesignTabBar *)self;
        [flatDesignTabBar.tabBarItems enumerateObjectsUsingBlock:^(UIControl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj cyl_stopAnimationOfLottieView];
        }];
        
    }
#endif

}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    if (_selectedIndex == selectedIndex && (self.defaultSelectedIndex != selectedIndex)) { return; }
    
    [self closePlus:YES];
    if (self.tabBarItems && self.tabBarItems.count > _selectedIndex) {
        CYLFlatDesignTabBarItem *currTabBarItem = self.tabBarItems[_selectedIndex];
        [currTabBarItem setIsSelected:NO animated:YES];
        
        CYLFlatDesignTabBarItem *tabBarItem = self.tabBarItems[selectedIndex];
        [tabBarItem setIsSelected:YES animated:YES];
    }
    _selectedIndex = selectedIndex;
}

#pragma mark - 手势回调

- (void)longPressAction:(UILongPressGestureRecognizer *)lrGR {
    if (self.plusing) { return; }
    if (lrGR.state == UIGestureRecognizerStateBegan) {
        //TODO: plus button vs touch event?
        // self.plusView.isCanTouchesBegan = NO;
        [self didClickPlus];
        //TODO: delegate
    }
}

- (void)didClickPlus {
    if (self.plusing) {
        [self closePlus:YES];
    } else {
        [self showPlus:YES];
    }
}

#pragma mark - plus动画

- (void)setIsAnimating:(BOOL)isAnimating {
    _isAnimating = isAnimating;
    //    if (!isAnimating) { self.plusView.isCanTouchesBegan = YES; }
}

- (void)setPlusing:(BOOL)plusing {
    _plusing = plusing;
    self.backgroundView.userInteractionEnabled = plusing;
    
    self.lpGR.enabled = !plusing;
}

- (void)showPlus:(BOOL)animated {
    if (self.plusing) { return; }
    [self plusAction:animated];
}

- (void)closePlus {
    [self closePlus:YES];
}

- (void)closePlus:(BOOL)animated {
    if (!self.plusing) { return; }
    [self plusAction:animated];
}

- (void)plusAction:(BOOL)animated {
    self.isAnimating = YES;
    self.plusing = !self.plusing;
    
    [self preparePlusSubviews];
    
    UIColor *backgroundColor = self.plusing ? CYLRGBAColor(0, 0, 0, 0.2) : CYLRGBAColor(0, 0, 0, 0);
    
    CGRect blurFrame = self.blurView.frame;
    blurFrame.origin.y = self.plusing ? _blurPlusY : 0;
    
    CGFloat blurRadius = self.plusing ? CYLScaleValue(22) : CYLScaleValue(16);
    CGFloat tabBarItemScaleXY = self.plusing ? 0.5 : 1;
    CGFloat tabBarItemAlpha = self.plusing ? 0 : 1;
    
    if (!animated) {
        self.backgroundView.backgroundColor = backgroundColor;
        
        self.blurView.frame = blurFrame;
        self.blurView.layer.cornerRadius = blurRadius;
        for (CYLFlatDesignTabBarItem *tabBarItem in self.tabBarItems) {
            tabBarItem.layer.transform = CATransform3DMakeScale(tabBarItemScaleXY, tabBarItemScaleXY, 1);
            tabBarItem.layer.opacity = tabBarItemAlpha;
        }
        
        self.isAnimating = NO;
        return;
    }
    
    NSTimeInterval beginTime = 0;
    CGFloat springSpeed = self.plusing ? 10 : 17;
    CGFloat springBounciness = self.plusing ? 7 : 4;
    
    beginTime = self.plusing ? 0 : 0.15;
    springSpeed = 20;
    springBounciness = self.plusing ? 7 : 5;
    
}

#pragma mark 创建plus的子视图
- (void)preparePlusSubviews {
    if (self.backgroundView) {
        return;
    }
    
    CGFloat w = CYLScreenWidth();
    CGFloat h = CYLScreenHeight();
    CGFloat x = 0;
    CGFloat y = CYLScreenHeight() - h;
    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(x, y, w, h)];
    backgroundView.backgroundColor = CYLRGBAColor(0, 0, 0, 0);
//    [backgroundView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closePlus)]];
    [self insertSubview:backgroundView belowSubview:self.blurView];
    self.backgroundView = backgroundView;
    
    w = h = CYLScaleValue(60);
    x = CYLScaleValue(43);
    y = _blurPlusY + CYLScaleValue(48);
}

- (CYLBaseView *)createTypeViewWithFrame:(CGRect)frame
                                   image:(UIImage *)image
                         backgroundColor:(UIColor *)backgroundColor
                                pushType:(NSInteger)pushType {
    CYLBaseView *typeView = [[CYLBaseView alloc] initWithFrame:frame];
    typeView.image = image;
    typeView.scale = 0.88;
    typeView.scaleDuration = 0.3;
    
    typeView.layer.cornerRadius = frame.size.height * 0.5;
    typeView.layer.masksToBounds = YES;
    typeView.backgroundColor = backgroundColor;
    typeView.tag = pushType;
    
    __weak typeof(self) wSelf = self;
    typeView.viewTouchUpInside = ^(CYLBaseView *bounceView) {
        __strong typeof(wSelf) sSelf = wSelf;
        if (!sSelf || sSelf.isAnimating) { return; }
        [sSelf choose:bounceView.tag];
    };
    
    [self insertSubview:typeView belowSubview:self.plusSuperView];
    return typeView;
}

- (UILabel *)createTypeLabelWithTitle:(NSString *)title textColor:(UIColor *)textColor typeView:(UIView *)typeView {
    UILabel *typeLabel = ({
        UILabel *aLabel = [[UILabel alloc] init];
        aLabel.font = CYLScaleFont(15);
        aLabel.textColor = textColor;
        aLabel.text = title;
        [aLabel sizeToFit];
        aLabel.center = CGPointMake(CGRectGetMidX(typeView.frame), CGRectGetMaxY(typeView.frame) + CYLScaleValue(8) + aLabel.frame.size.height * 0.5);
        aLabel;
    });
    [self insertSubview:typeLabel belowSubview:self.plusSuperView];
    return typeLabel;
}

#pragma mark -

- (void)choose:(NSInteger)pushType {
    
}

@end


@interface CYLFlatDesignTabBarItem ()
@end

@implementation CYLFlatDesignTabBarItem


- (instancetype)initWithFrame:(CGRect)frame
                        title:(NSString *)title
              tabBarItemImage:(id)tabBarItemImage
      tabBarItemSelectedImage:(id)tabBarItemSelectedImage
                        index:(NSInteger)index
      titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                  imageInsets:(UIEdgeInsets)imageInsets
               lottieFilePath:(NSString *)lottieFilePath
              lottieSizeValue:(NSValue *)lottieSizeValue {
    if (self = [super initWithFrame:frame]) {
        
        self.scale = 1.17;
        self.scaleDuration = 0.2;
        self.recoverBounciness = 15;
        
        self.titlePositionAdjustment = titlePositionAdjustment;
        self.imageInsets = imageInsets;
        self.lottieFilePath = lottieFilePath;
        
        NSValue *tureLottieSizeValue = [CYLConstants cyl_getTureLottieSizeValue:lottieSizeValue fromNormalImage:self.tabBarItemImage];
        self.lottieSizeValue = tureLottieSizeValue;
        
        // =========================
        // 1️⃣ ImageView
        // =========================
        
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        self.tabBarItemImage =  [UIImage cyl_imageNamed:tabBarItemImage];
        self.tabBarItemSelectedImage = [UIImage cyl_imageNamed:tabBarItemSelectedImage];;
        
        imageView.image = self.tabBarItemImage;
        imageView.highlightedImage = self.tabBarItemSelectedImage;
        imageView.highlighted = (index == 0);
        imageView.clipsToBounds = NO;

        self.imageView = imageView;
        
        [NSLayoutConstraint activateConstraints:@[
            [imageView.widthAnchor constraintEqualToConstant:20],
            [imageView.heightAnchor constraintEqualToConstant:20]
        ]];
        
        
        // =========================
        // 2️⃣ Title Label
        // =========================
        
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont systemFontOfSize:10];
        titleLabel.text = title;
        
        self.titleLabel = titleLabel;
        
        
        // =========================
        // 3️⃣ StackView
        // =========================
        
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[
            self.imageView,
            self.titleLabel
        ]];
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.alignment = UIStackViewAlignmentCenter;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.spacing = 4; // image 与 label 间距
        stackView.clipsToBounds = NO;
        self.stackView = stackView;
        
        [self addSubview:self.stackView];
        
        [NSLayoutConstraint activateConstraints:@[
            
            // 居中
            [stackView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [stackView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            
            // 宽度铺满（保证 label 居中）
            [stackView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.leadingAnchor],
            [stackView.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor],
        ]];
        
        
        // =========================
        // 4️⃣ AnchorPoint 调整
        // =========================
        
        // 强制 layout 一次，拿到真实 frame
        [self layoutIfNeeded];
        
        CGFloat iconMidY = CGRectGetMidY(imageView.frame);
        CGFloat diffY = self.bounds.size.height * 0.5 - iconMidY;
        
        self.layer.anchorPoint = CGPointMake(0.5, iconMidY / self.bounds.size.height);
        self.layer.position = CGPointMake(self.layer.position.x,
                                          self.layer.position.y - diffY);
        
        
        // =========================
        // 5️⃣ tag 逻辑
        // =========================
        
        NSInteger tag = index;
        if (index == 0) {
            tag = -1;
        }
        self.tag = tag;
        
        NSURL *lottieURL;
        
        if (lottieFilePath) {
            lottieURL = [NSURL fileURLWithPath:lottieFilePath];
        }

        if (lottieURL) {
#if __has_include(<Lottie/Lottie.h>)
            CGSize lottieSize = [lottieSizeValue CGSizeValue];
            [self cyl_addLottieImageWithLottieURL:lottieURL size:lottieSize contentMode:self.cyl_tabBarController.lottieAnimationViewContentMode];
#endif
         
    
#if __has_include(<Lottie/Lottie-Swift.h>)
            CGSize lottieSize = [lottieSizeValue CGSizeValue];
            [self cyl_addLottieImageWithLottieURL:lottieURL size:lottieSize contentMode:self.cyl_tabBarController.lottieAnimationViewContentMode];
#endif

        }
    }
    
    return self;
}


- (void)setIsSelected:(BOOL)isSelected {
    [self setIsSelected:isSelected animated:NO];
}

- (void)setIsSelected:(BOOL)isSelected animated:(BOOL)animated {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageView.highlighted = isSelected;
        self.titleLabel.textColor = isSelected ? CYLRGBColor(29, 121, 255) : CYLRGBColor(115, 122, 135);
        // self.imgTabIcon.image = self.currentTab?.tabBarItem?.image
        if (isSelected) {
            CGSize lottieSize = [self.lottieSizeValue CGSizeValue];
            NSURL *url;
            if (self.lottieFilePath) {
                url = [NSURL fileURLWithPath:self.lottieFilePath];
            }
            [self cyl_animationLottieImageWithLottieURL:url size:lottieSize defaultSelected:NO contentMode:self.cyl_tabBarController.lottieAnimationViewContentMode];
        } else {
            [self cyl_stopAnimationOfLottieView];
        }
    });
}

- (void)setIsHasBadge:(BOOL)isHasBadge {
    [self setIsHasBadge:isHasBadge animated:NO];
}

- (void)setIsHasBadge:(BOOL)isHasBadge animated:(BOOL)animated {
    _isHasBadge = isHasBadge;
}

- (UIView *)actualBadgeSuperView {
    // badge label will be added onto imageView
    UIControl *tabButton = self;
    UIImageView *tabImageView = [self imageView];
    UIView *lottieAnimationView = (UIView *)tabButton.cyl_lottieAnimationView;
    
    UIView *actualBadgeSuperView = nil;
    
    do {
        if (lottieAnimationView && !lottieAnimationView.cyl_isInvisiable) {
            actualBadgeSuperView = lottieAnimationView;
            break;
        }
        if (tabImageView && !tabImageView.cyl_isInvisiable) {
            actualBadgeSuperView = tabImageView;
            break;
        }
    } while (NO);
    return actualBadgeSuperView;
}

@end




