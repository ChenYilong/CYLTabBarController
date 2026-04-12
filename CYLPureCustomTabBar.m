//
//  CYLTabBar.h
//  CYLTabBarController
//
//  v1.21.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2018 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLPureCustomTabBar.h"
//#import "UIView+CYLPOP.h"

#import "CYLTabBar.h"
#import "CYLPlusButton.h"
#import "CYLTabBarController.h"
#import "CYLConstants.h"
#import "UIControl+CYLTabBarControllerExtention.h"
#import "CYLTabBar+CYLTabBarControllerExtention.h"

@interface CYLPureCustomTabBar ()
@property (nonatomic, weak) UIVisualEffectView *blurView;
@property (nonatomic, weak) UIView *bgView;
@property (nonatomic, weak) UILabel *mobileLabel;
@property (nonatomic, weak) UILabel *equipmentLabel;
@property (nonatomic, weak) UILabel *vrEquipmentLabel;

@property (nonatomic, weak) UILongPressGestureRecognizer *lpGR;
@property (nonatomic, strong) UIColor *lightBlackWhiteColor;
@end

@implementation CYLPureCustomTabBar
{
    CGSize _tabBarItemSize;
    CGSize _popBtnSize;
    
    CGFloat _blurPlusY;
    CGPoint _mobileIconCenter;
    CGPoint _equipmentIconCenter;
    CGPoint _vrEquipmentIconCenter;
    CGPoint _mobileTitleCenter;
    CGPoint _equipmentTitleCenter;
    CGPoint _vrEquipmentTitleCenter;
}

- (NSMutableArray<CYLPureCustomTabBarItem *> *)tabBarItems {
    if (!_tabBarItems) _tabBarItems = [NSMutableArray array];
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

- (instancetype)init {
    if (self = [super initWithFrame:CGRectMake(0, 0, self.cyl_tabBarController.visiableTabBarSize.width, self.cyl_tabBarController.visiableTabBarSize.height)]) {
        self.backgroundColor = UIColor.clearColor;
        
        UIGlassEffect *effect = [UIGlassEffect effectWithStyle:UIGlassEffectStyleRegular];
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:effect];
        blurView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.width);
        blurView.layer.cornerRadius = CYLScaleValue(16);
        blurView.layer.masksToBounds = YES;
        [self addSubview:blurView];
        self.blurView = blurView;
        
        _tabBarItemSize = CGSizeMake(CYLScaleValue(70),  self.cyl_tabBarController.visiableTabBarSize.height);
        _popBtnSize = CGSizeMake(CYLScaleValue(80),  self.cyl_tabBarController.visiableTabBarSize.height);
        
        UIView *plusSuperView = [[UIView alloc] initWithFrame:CGRectMake(CYLHalfOfDiff(self.bounds.size.width, _popBtnSize.width), 0, _popBtnSize.width, _popBtnSize.height)];
        [self addSubview:plusSuperView];
        self.plusSuperView = plusSuperView;
        
        CYLBaseView *plusView = [[CYLBaseView alloc] initWithFrame:plusSuperView.bounds];
        plusView.layer.contentsGravity = kCAGravityCenter;
        
        if (CYL_IS_IOS_13) {
            plusView.layer.contentsScale = self.cyl_tabBarController.rootWindow.windowScene.screen.scale;
        }
        plusView.image = [UIImage imageNamed:@"com_home_live_icon"];
        plusView.scale = 1.15;
        plusView.scaleDuration = 0.2;
        plusView.isJudgeBegin = YES;
        [plusSuperView addSubview:plusView];
        self.plusView = plusView;
        
        __weak typeof(self) wSelf = self;
        plusView.viewTouchUpInside = ^(CYLBaseView *bounceView) {
            __strong typeof(wSelf) sSelf = wSelf;
            if (!sSelf) return;
            [sSelf didClickPlus];
        };
        
        UILongPressGestureRecognizer *lpGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        lpGR.minimumPressDuration = 0.4;
        [plusView addGestureRecognizer:lpGR];
        self.lpGR = lpGR;
        
        _blurPlusY = -(CYLScaleValue(212) + self.cyl_tabBarController.rootWindow.safeAreaInsets.bottom);
    }
    return self;
}

#pragma mark - 重写父类方法

- (void)addSubview:(UIView *)view {
    if ([self isKindOfClass:[UITabBar class]]) {
        if ([view isKindOfClass:NSClassFromString(@"UIKit._UITabBarPlatterView")]) {
            view.hidden = YES;
        }
    }
    [super addSubview:view];
}

- (void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if ([self isKindOfClass:[UITabBar class]]) {
        if ([gestureRecognizer isKindOfClass:NSClassFromString(@"_UIContinuousSelectionGestureRecognizer")]) {
            gestureRecognizer.enabled = NO;
        }
    }
    [super addGestureRecognizer:gestureRecognizer];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.plusing) {
        return YES;
    }
    BOOL inside = [super pointInside:point withEvent:event];
    if (inside) {
        if (CGRectContainsPoint(self.plusSuperView.frame, point)) {
            self.plusView.isTouching = YES;
            return inside;
        }
        for (CYLPureCustomTabBarItem *item in self.tabBarItems) {
            if (CGRectContainsPoint(item.frame, point)) {
                item.isTouching = YES;
                return inside;
            }
        }
    }
    return inside;
}

#pragma mark - 添加贴吧

- (void)addItemWithTitle:(NSString *)title
              normalIcon:(NSString *)normalIcon
              selectIcon:(NSString *)selectIcon
                   index:(NSInteger)index {
    CGFloat w = _tabBarItemSize.width;
    CGFloat h = _tabBarItemSize.height;
    CGFloat x = 0;
    if (index > 1) {
        x = self.cyl_tabBarController.visiableTabBarSize.width - w - (3 - index) * (w + CYLScaleValue(2));
    } else {
        x = index * (w + CYLScaleValue(2));
    }
    CGFloat y = 0;
    CYLPureCustomTabBarItem *tabBarItem = [[CYLPureCustomTabBarItem alloc] initWithFrame:CGRectMake(x, y, w, h) title:title index:index normalIcon:normalIcon selectIcon:selectIcon];
    tabBarItem.tag = index;
    tabBarItem.isSelected = index == 0;
    __weak typeof(self) wSelf = self;
    tabBarItem.viewTouchUpInside = ^(CYLBaseView *bounceView) {
        __strong typeof(wSelf) sSelf = wSelf;
        if (!sSelf || sSelf.selectedIndex == bounceView.tag) return;
        sSelf.selectedIndex = bounceView.tag;
        [sSelf.wlDelegate tabBar:sSelf didSelectItemAt:sSelf.selectedIndex];
    };
    [self.tabBarItems addObject:tabBarItem];
    [self insertSubview:tabBarItem belowSubview:self.plusSuperView];
}

#pragma mark - 自定义贴吧的点击响应

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    if (_selectedIndex == selectedIndex) return;
    
    [self closePlus:YES];
    
    CYLPureCustomTabBarItem *currTabBarItem = self.tabBarItems[_selectedIndex];
    [currTabBarItem setIsSelected:NO animated:YES];
    
    CYLPureCustomTabBarItem *tabBarItem = self.tabBarItems[selectedIndex];
    [tabBarItem setIsSelected:YES animated:YES];
    
    _selectedIndex = selectedIndex;
}

#pragma mark - 手势回调

- (void)longPressAction:(UILongPressGestureRecognizer *)lrGR {
    if (self.plusing) return;
    if (lrGR.state == UIGestureRecognizerStateBegan) {
        self.plusView.isCanTouchesBegan = NO;
        [self didClickPlus];
        //TODO:   delegate
//        AudioServicesPlaySystemSound(1519);
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
    if (!isAnimating) self.plusView.isCanTouchesBegan = YES;
}

- (void)setPlusing:(BOOL)plusing {
    _plusing = plusing;
    self.bgView.userInteractionEnabled = plusing;
    self.mobileView.userInteractionEnabled = plusing;
    self.equipmentView.userInteractionEnabled = plusing;
    self.vrEquipmentView.userInteractionEnabled = plusing;
    self.lpGR.enabled = !plusing;
}

- (void)showPlus:(BOOL)animated {
    if (self.plusing) return;
    [self plusAction:animated];
}

- (void)closePlus {
    [self closePlus:YES];
}

- (void)closePlus:(BOOL)animated {
    if (!self.plusing) return;
    [self plusAction:animated];
}

- (void)plusAction:(BOOL)animated {
    self.isAnimating = YES;
    self.plusing = !self.plusing;
    
    [self preparePlusSubviews];
    
    UIColor *bgColor = self.plusing ? CYLRGBAColor(0, 0, 0, 0.2) : CYLRGBAColor(0, 0, 0, 0);
    
    CGRect blurFrame = self.blurView.frame;
    blurFrame.origin.y = self.plusing ? _blurPlusY : 0;
    
    CGFloat blurRadius = self.plusing ? CYLScaleValue(22) : CYLScaleValue(16);
    
    CGFloat iconAlpha = self.plusing ? 1 : 0;
    CGFloat iconScale = self.plusing ? 1 : (self.plusSuperView.frame.size.width / self.mobileView.frame.size.width);
    
    CGPoint mobileTitleCenter = self.plusSuperView.center;
    CGPoint equipmentTitleCenter = mobileTitleCenter;
    CGPoint vrEquipmentTitleCenter = mobileTitleCenter;
    
    CGPoint mobileIconCenter = mobileTitleCenter;
    CGPoint equipmentIconCenter = mobileTitleCenter;
    CGPoint vrEquipmentIconCenter = mobileTitleCenter;
    
    if (self.plusing) {
        mobileTitleCenter = _mobileTitleCenter;
        equipmentTitleCenter = _equipmentTitleCenter;
        vrEquipmentTitleCenter = _vrEquipmentTitleCenter;
        
        mobileIconCenter = _mobileIconCenter;
        equipmentIconCenter = _equipmentIconCenter;
        vrEquipmentIconCenter = _vrEquipmentIconCenter;
    }
    
    UIImage *plusImage = self.plusing ? [UIImage imageNamed:@"live_shut_crude_black_icon"] : [UIImage imageNamed:@"com_home_live_icon"];
    
    CGFloat tabBarItemScaleXY = self.plusing ? 0.5 : 1;
    CGFloat tabBarItemAlpha = self.plusing ? 0 : 1;
    
    if (!animated) {
        self.bgView.backgroundColor = bgColor;
        
        self.blurView.frame = blurFrame;
        self.blurView.layer.cornerRadius = blurRadius;
        
        self.mobileLabel.alpha = iconAlpha;
        self.mobileLabel.center = mobileTitleCenter;
        
        self.equipmentLabel.alpha = iconAlpha;
        self.equipmentLabel.center = equipmentTitleCenter;
        
        self.vrEquipmentLabel.alpha = iconAlpha;
        self.vrEquipmentLabel.center = vrEquipmentTitleCenter;
        
        self.mobileView.transform = CGAffineTransformMakeScale(iconScale, iconScale);
        self.mobileView.center = mobileIconCenter;
        self.mobileView.alpha = iconAlpha;
        
        self.equipmentView.transform = CGAffineTransformMakeScale(iconScale, iconScale);
        self.equipmentView.center = equipmentIconCenter;
        self.equipmentView.alpha = iconAlpha;
        
        self.vrEquipmentView.transform = CGAffineTransformMakeScale(iconScale, iconScale);
        self.vrEquipmentView.center = vrEquipmentIconCenter;
        self.vrEquipmentView.alpha = iconAlpha;
        
        self.plusView.image = plusImage;
        
        for (CYLPureCustomTabBarItem *tabBarItem in self.tabBarItems) {
            tabBarItem.layer.transform = CATransform3DMakeScale(tabBarItemScaleXY, tabBarItemScaleXY, 1);
            tabBarItem.layer.opacity = tabBarItemAlpha;
        }
        
        self.isAnimating = NO;
        return;
    }
    
    NSTimeInterval beginTime = 0;
    
    // ------------------ 背景 ------------------
//    [self.bgView jp_addPOPBasicAnimationWithPropertyNamed:kPOPViewBackgroundColor toValue:bgColor duration:0.3 beginTime:beginTime completionBlock:nil];
    
    CGFloat springSpeed = self.plusing ? 10 : 17;
    CGFloat springBounciness = self.plusing ? 7 : 4;
//    [self.blurView jp_addPOPSpringAnimationWithPropertyNamed:kPOPViewFrame toValue:@(blurFrame) springSpeed:springSpeed springBounciness:springBounciness beginTime:beginTime completionBlock:nil];
//    [self.blurView.layer jp_addPOPBasicAnimationWithPropertyNamed:kPOPLayerCornerRadius toValue:@(blurRadius) duration:0.3 beginTime:beginTime completionBlock:nil];
    // -----------------------------------------
    
    
    // ------------------ 标签 ------------------
//    NSTimeInterval duration = self.plusing ? 0.3 : 0.15;
//    [self.mobileLabel jp_addPOPBasicAnimationWithPropertyNamed:kPOPViewAlpha toValue:@(iconAlpha) duration:duration beginTime:beginTime completionBlock:nil];
//    [self.mobileLabel jp_addPOPSpringAnimationWithPropertyNamed:kPOPViewCenter toValue:@(mobileTitleCenter) springSpeed:10 springBounciness:7 beginTime:beginTime completionBlock:nil];
//    
//    [self.equipmentLabel jp_addPOPBasicAnimationWithPropertyNamed:kPOPViewAlpha toValue:@(iconAlpha) duration:duration beginTime:beginTime completionBlock:nil];
//    [self.equipmentLabel jp_addPOPSpringAnimationWithPropertyNamed:kPOPViewCenter toValue:@(equipmentTitleCenter) springSpeed:10 springBounciness:7 beginTime:beginTime completionBlock:nil];
//    
//    [self.vrEquipmentLabel jp_addPOPBasicAnimationWithPropertyNamed:kPOPViewAlpha toValue:@(iconAlpha) duration:duration beginTime:beginTime completionBlock:nil];
//    [self.vrEquipmentLabel jp_addPOPSpringAnimationWithPropertyNamed:kPOPViewCenter toValue:@(vrEquipmentTitleCenter) springSpeed:10 springBounciness:7 beginTime:beginTime completionBlock:nil];
    // -----------------------------------------
    
    
    // ------------------ 图标 ------------------
    CGPoint iconScaleXY = CGPointMake(iconScale, iconScale);
    
//    [self.mobileView jp_addPOPSpringAnimationWithPropertyNamed:kPOPViewScaleXY toValue:@(iconScaleXY) springSpeed:10 springBounciness:7 beginTime:beginTime completionBlock:nil];
//    [self.mobileView jp_addPOPSpringAnimationWithPropertyNamed:kPOPViewCenter toValue:@(mobileIconCenter) springSpeed:10 springBounciness:7 beginTime:beginTime completionBlock:nil];
//    [self.mobileView jp_addPOPSpringAnimationWithPropertyNamed:kPOPViewAlpha toValue:@(iconAlpha) springSpeed:10 springBounciness:7 beginTime:beginTime completionBlock:nil];
//
//    [self.equipmentView jp_addPOPSpringAnimationWithPropertyNamed:kPOPViewScaleXY toValue:@(iconScaleXY) springSpeed:10 springBounciness:7 beginTime:beginTime completionBlock:nil];
//    [self.equipmentView jp_addPOPSpringAnimationWithPropertyNamed:kPOPViewCenter toValue:@(equipmentIconCenter) springSpeed:10 springBounciness:7 beginTime:beginTime completionBlock:nil];
//    [self.equipmentView jp_addPOPSpringAnimationWithPropertyNamed:kPOPViewAlpha toValue:@(iconAlpha) springSpeed:10 springBounciness:7 beginTime:beginTime completionBlock:nil];
//
//    [self.vrEquipmentView jp_addPOPSpringAnimationWithPropertyNamed:kPOPViewScaleXY toValue:@(iconScaleXY) springSpeed:10 springBounciness:7 beginTime:beginTime completionBlock:nil];
//    [self.vrEquipmentView jp_addPOPSpringAnimationWithPropertyNamed:kPOPViewCenter toValue:@(vrEquipmentIconCenter) springSpeed:10 springBounciness:7 beginTime:beginTime completionBlock:nil];
//    [self.vrEquipmentView jp_addPOPSpringAnimationWithPropertyNamed:kPOPViewAlpha toValue:@(iconAlpha) springSpeed:10 springBounciness:7 beginTime:beginTime completionBlock:nil];
    // -----------------------------------------
    
    
    // ------------------ 按钮 ------------------
//    [self.plusSuperView.layer jp_addPOPBasicAnimationWithPropertyNamed:kPOPLayerScaleXY toValue:@(CGPointMake(0.1, 0.1)) duration:0.13 beginTime:beginTime completionBlock:^(POPAnimation *anim, BOOL finished) {
//        self.plusView.image = plusImage;
//        [self.plusSuperView.layer jp_addPOPSpringAnimationWithPropertyNamed:kPOPLayerScaleXY toValue:@(CGPointMake(1, 1)) springSpeed:20 springBounciness:8 completionBlock:^(POPAnimation *anim, BOOL finished) {
//            // 不知道被什么覆盖了点不了，重新按上去
//            [self addSubview:self.plusSuperView];
//            self.isAnimating = NO;
//        }];
//    }];
    // -----------------------------------------
    
    
    // ------------------ 贴吧 ------------------
    beginTime = self.plusing ? 0 : 0.15;
    springSpeed = 20;
    springBounciness = self.plusing ? 7 : 5;
    for (CYLPureCustomTabBarItem *tabBarItem in self.tabBarItems) {
//        [tabBarItem.layer jp_addPOPSpringAnimationWithPropertyNamed:kPOPLayerScaleXY toValue:@(CGPointMake(tabBarItemScaleXY, tabBarItemScaleXY)) springSpeed:springSpeed springBounciness:springBounciness beginTime:beginTime completionBlock:nil];
//        [tabBarItem.layer jp_addPOPSpringAnimationWithPropertyNamed:kPOPLayerOpacity toValue:@(tabBarItemAlpha) springSpeed:springSpeed springBounciness:springBounciness beginTime:beginTime completionBlock:nil];
    }
    // -----------------------------------------
    
//    AudioServicesPlaySystemSound((self.plusing ? 1397 : 1396));
}

#pragma mark 创建plus的子视图
- (void)preparePlusSubviews {
    if (self.bgView) {
        self.mobileView.hidden = NO;
        self.equipmentView.hidden = NO;
        self.vrEquipmentView.hidden = NO;
        return;
    }
    
    CGFloat w = self.cyl_tabBarController.visiableTabBarSize.width;
    CGFloat h = self.cyl_tabBarController.visiableTabBarSize.height;
    CGFloat x = 0;
    CGFloat y = self.bounds.size.height - h;
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(x, y, w, h)];
    bgView.backgroundColor = CYLRGBAColor(0, 0, 0, 0);
    [bgView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closePlus)]];
    [self insertSubview:bgView belowSubview:self.blurView];
    self.bgView = bgView;
    
    w = h = CYLScaleValue(60);
    x = CYLScaleValue(43);
    y = _blurPlusY + CYLScaleValue(48);
    CGFloat space = (self.cyl_tabBarController.visiableTabBarSize.width - 2 * x - 3 * w) / 2.0;
    
    self.mobileView = [self createTypeViewWithFrame:CGRectMake(x, y, w, h) image:[UIImage imageNamed:@"live_phone_icon"] bgColor:CYLRGBColor(230, 55, 81) pushType:0];
    
    x = x + w + space;
    self.equipmentView = [self createTypeViewWithFrame:CGRectMake(x, y, w, h) image:[UIImage imageNamed:@"live_equipment_icon"] bgColor:CYLRGBColor(56, 121, 242) pushType:1];
    
    x = x + w + space;
    self.vrEquipmentView = [self createTypeViewWithFrame:CGRectMake(x, y, w, h) image:[UIImage imageNamed:@"live_vr_icon"] bgColor:CYLRGBColor(53, 188, 156) pushType:2];
    
    _mobileIconCenter = self.mobileView.center;
    _equipmentIconCenter = self.equipmentView.center;
    _vrEquipmentIconCenter = self.vrEquipmentView.center;
    
    UIColor *textColor = self.lightBlackWhiteColor;
    self.mobileLabel = [self createTypeLabelWithTitle:@"手机直播" textColor:textColor typeView:self.mobileView];
    self.equipmentLabel = [self createTypeLabelWithTitle:@"专业设备直播" textColor:textColor typeView:self.equipmentView];
    self.vrEquipmentLabel = [self createTypeLabelWithTitle:@"VR直播" textColor:textColor typeView:self.vrEquipmentView];
    
    _mobileTitleCenter = self.mobileLabel.center;
    _equipmentTitleCenter = self.equipmentLabel.center;
    _vrEquipmentTitleCenter = self.vrEquipmentLabel.center;

    CGFloat iconScale = self.plusSuperView.frame.size.width / self.mobileView.frame.size.width;
    CGPoint center = self.plusSuperView.center;
    
    self.mobileView.transform = CGAffineTransformMakeScale(iconScale, iconScale);
    self.mobileView.center = center;
    self.mobileView.alpha = 0;
    
    self.equipmentView.transform = CGAffineTransformMakeScale(iconScale, iconScale);
    self.equipmentView.center = center;
    self.equipmentView.alpha = 0;
    
    self.vrEquipmentView.transform = CGAffineTransformMakeScale(iconScale, iconScale);
    self.vrEquipmentView.center = center;
    self.vrEquipmentView.alpha = 0;

    self.mobileLabel.center = center;
    self.mobileLabel.alpha = 0;
    
    self.equipmentLabel.center = center;
    self.equipmentLabel.alpha = 0;
    
    self.vrEquipmentLabel.center = center;
    self.vrEquipmentLabel.alpha = 0;
}

- (CYLBaseView *)createTypeViewWithFrame:(CGRect)frame
                                    image:(UIImage *)image
                                  bgColor:(UIColor *)bgColor
                                 pushType:(NSInteger)pushType {
    CYLBaseView *typeView = [[CYLBaseView alloc] initWithFrame:frame];
    typeView.image = image;
    typeView.scale = 0.88;
    typeView.scaleDuration = 0.3;
    
    typeView.layer.cornerRadius = frame.size.height * 0.5;
    typeView.layer.masksToBounds = YES;
    typeView.backgroundColor = bgColor;
    typeView.tag = pushType;
    
    __weak typeof(self) wSelf = self;
    typeView.viewTouchUpInside = ^(CYLBaseView *bounceView) {
        __strong typeof(wSelf) sSelf = wSelf;
        if (!sSelf || sSelf.isAnimating) return;
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

#pragma mark - 前往直播

- (void)choose:(NSInteger)pushType {
    NSLog(@"前往直播 --- %zd", pushType);
}

@end


@interface CYLPureCustomTabBarItem ()
@property (nonatomic, weak) UIImageView *normalIconView;
@property (nonatomic, weak) UIImageView *selectIconView;
@property (nonatomic, weak) UILabel *titleLabel;
@end

@implementation CYLPureCustomTabBarItem

- (instancetype)initWithFrame:(CGRect)frame
                        title:(NSString *)title
                        index:(NSInteger)index
                   normalIcon:(NSString *)normalIcon
                   selectIcon:(NSString *)selectIcon {
    if (self = [super initWithFrame:frame]) {
        self.scale = 1.17;
        self.scaleDuration = 0.2;
        self.recoverBounciness = 15;
        
        CGRect iconFrame = CGRectMake(CYLScaleValue(25), 8, 20, 20);
        
        UIImageView *normalIconView = [[UIImageView alloc] initWithFrame:iconFrame];
        normalIconView.image = [UIImage imageNamed:normalIcon];
        [self addSubview:normalIconView];
        self.normalIconView = normalIconView;
        
        UIImageView *selectIconView = [[UIImageView alloc] initWithFrame:iconFrame];
        selectIconView.image = [UIImage imageNamed:selectIcon];
        [self addSubview:selectIconView];
        self.selectIconView = selectIconView;
        
        UILabel *titleLabel = ({
            UILabel *aLabel = [[UILabel alloc] init];
            aLabel.textAlignment = NSTextAlignmentCenter;
            aLabel.font = [UIFont systemFontOfSize:10];
            aLabel.text = title;
            aLabel.frame = CGRectMake(0, 8 + 20 + 4, self.bounds.size.width, 14);
            aLabel;
        });
        [self addSubview:titleLabel];
        self.titleLabel = titleLabel;
        
        CGFloat iconMidY = CGRectGetMidY(iconFrame);
        CGFloat diffY = self.bounds.size.height * 0.5 - iconMidY;
        self.layer.anchorPoint = CGPointMake(0.5, (iconMidY / self.bounds.size.height));
        self.layer.position = CGPointMake(self.layer.position.x, self.layer.position.y - diffY);
    }
    return self;
}

- (void)setIsSelected:(BOOL)isSelected {
    [self setIsSelected:isSelected animated:NO];
}

- (void)setIsSelected:(BOOL)isSelected animated:(BOOL)animated {
    _isSelected = isSelected;
    CGFloat normalIconViewAlpha = isSelected ? 0.0 : 1.0;
    CGFloat selectIconViewAlpha = isSelected ? 1.0 : 0.0;
    UIColor *titleLabelColor = isSelected ? CYLRGBColor(29, 121, 255) : CYLRGBColor(115, 122, 135);
    if (animated) {
        NSTimeInterval duration = isSelected ? 0.2 : 0.1;
//        [self.normalIconView jp_addPOPBasicAnimationWithPropertyNamed:kPOPViewAlpha toValue:@(normalIconViewAlpha) duration:duration];
//        [self.selectIconView jp_addPOPBasicAnimationWithPropertyNamed:kPOPViewAlpha toValue:@(selectIconViewAlpha) duration:duration];
//        [self.titleLabel jp_addPOPBasicAnimationWithPropertyNamed:kPOPLabelTextColor toValue:titleLabelColor duration:duration];
    } else {
        self.normalIconView.alpha = normalIconViewAlpha;
        self.selectIconView.alpha = selectIconViewAlpha;
        self.titleLabel.textColor = titleLabelColor;
    }
}

- (void)setIsHasBadge:(BOOL)isHasBadge {
    [self setIsHasBadge:isHasBadge animated:NO];
}

- (void)setIsHasBadge:(BOOL)isHasBadge animated:(BOOL)animated {
    _isHasBadge = isHasBadge;
}

@end
