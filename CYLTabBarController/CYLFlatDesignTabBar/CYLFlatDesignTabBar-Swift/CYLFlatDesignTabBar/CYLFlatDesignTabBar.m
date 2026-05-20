//
//  CYLFlatDesignTabBar.m
//  CYLFlatDesignTabBarController
//
//  Created by apple on 2026/2/6.
//

#import "CYLFlatDesignTabBar.h"
#import "CYLFlatDesignTabBarItem.h"
#import "CYLFlatDesignTabBarController.h"
#import "CYLFlatDesignTabViewController.h"

@interface CYLFlatDesignTabBar ()

// _UIBackground
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIVisualEffectView *backgroundEffectView;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *shadowImageView;

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, weak, readonly, nullable) UITabBarController *tabBarController;
@property (nonatomic, weak, readonly, nullable) CYLFlatDesignTabViewController *customTabBarController;

@end

@implementation CYLFlatDesignTabBar {
    NSInteger _selectedItemIndex;
    NSMutableArray *_buttons;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_tabBarItemDidChange:) name:CYLFlatDesignTabBarItemDidChange object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_tabBarItemDidChange:(NSNotification *)note {
    if (_items == nil || _items.count == 0) return;
    CYLFlatDesignTabBarItem *changedItem = [note object];
    NSInteger itemIndex = [_items indexOfObject:changedItem];
    if (itemIndex != NSNotFound) {
        CYLFlatDesignTabBarButton *tabBarButton = _buttons[itemIndex];
        tabBarButton.tabBarItem = changedItem;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self _updateLayout];
}

- (void)commonInit {
    _selectedItemIndex = -1;
    _buttons = [NSMutableArray array];
    
    _backgroundView = [[UIView alloc] init];
    [self addSubview:_backgroundView];
    
    _backgroundImageView = [[UIImageView alloc] init];
    [_backgroundView addSubview:_backgroundImageView];
    
    _contentView = [[UIView alloc] init];
    [self addSubview:_contentView];
    
    self.barTintColor = [UIColor clearColor];
    self.tintColor = [UIColor systemBlueColor];
    _useLayoutSafeAreaInsets = YES;
}

#pragma mark - Setter & Getter
- (CYLFlatDesignTabBarItem *)addItemWithTitle:(NSString *)title
                              tabBarItemImage:(id)tabBarItemImage
                      tabBarItemSelectedImage:(id)tabBarItemSelectedImage
                                        index:(NSInteger)index
                      titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                                  imageInsets:(UIEdgeInsets)imageInsets
                               lottieFilePath:(NSString *)lottieFilePath
                              lottieSizeValue:(NSValue *)lottieSizeValue;
{
    return [CYLFlatDesignTabBarItem new];
}
- (NSArray<CYLFlatDesignTabBarButton *> *)tabBarButtons {
    return [_buttons copy];
}

- (void)setDelegate:(id<CYLFlatDesignTabBarDelegate>)delegate {
    if (_delegate != delegate) {
        if (_delegate) {
            // 系统 UITabBarController 也是不允许修改的
            if (self.tabBarController || self.customTabBarController) {
                NSAssert(NO, @"不允许更改由 tabBarController 管理的 tabBar 的代理");
                return;
            }
        }
        _delegate = delegate;
    }
}

- (void)setItems:(NSArray<CYLFlatDesignTabBarItem *> *)items {
    if (![_items isEqualToArray:items]) {
        if (self.selectedItem && ![items containsObject:self.selectedItem]) {
            _selectedItemIndex = -1;
        }
        _items = [items copy];
        [self _reloadItems];
    }
}

- (NSArray<CYLFlatDesignTabBarButton *> *)tabBarItems {
    return self.tabBarButtons;
}

- (void)setTabBarItems:(NSArray<CYLFlatDesignTabBarItem *> *)tabBarItems {
    [self setItems:tabBarItems];
}

- (void)setSelectedItem:(CYLFlatDesignTabBarItem *)selectedItem {
    if (selectedItem) {
        NSInteger index = [self.items indexOfObject:selectedItem];
        if (index != NSNotFound && _selectedItemIndex != index) {
            [self _setSelectedIndex:index];
        }
    } else {
        if (self.selectedItem) {
            CYLFlatDesignTabBarButton *selectedButton = _buttons[_selectedItemIndex];
            selectedButton.selected = NO;
            _selectedItemIndex = -1;
        }
    }
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    [self _setSelectedIndex:selectedIndex];
}

- (CYLFlatDesignTabBarItem *)selectedItem {
    if (_selectedItemIndex >= 0 && _selectedItemIndex < _items.count) {
        return [_items objectAtIndex:_selectedItemIndex];
    }
    return nil;
}

- (void)setTintColor:(UIColor *)tintColor {
    if (_tintColor != tintColor) {
        _tintColor = tintColor;
        for (CYLFlatDesignTabBarButton *button in _buttons) {
            button.tintColor = tintColor;
        }
    }
}

- (void)setBarTintColor:(UIColor *)barTintColor {
    if (_barTintColor != barTintColor) {
        _barTintColor = barTintColor;
        _backgroundImageView.image = _backgroundImage;
        if (_backgroundImage) {
            if (_backgroundEffectView) {
                [_backgroundEffectView removeFromSuperview];
                _backgroundEffectView = nil;
            }
            _backgroundImageView.backgroundColor = [UIColor clearColor];
        } else {
            _backgroundImageView.backgroundColor = self.barTintColor;
            if (!_backgroundEffectView) {
                UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent];
                _backgroundEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            }
            [_backgroundView insertSubview:_backgroundEffectView atIndex:0];
        }
        [self setNeedsLayout];
    }
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    if (_backgroundImage != backgroundImage) {
        _backgroundImage = backgroundImage;
        _backgroundImageView.image = backgroundImage;
        if (backgroundImage) {
            if (_backgroundEffectView) {
                [_backgroundEffectView removeFromSuperview];
                _backgroundEffectView = nil;
            }
            _backgroundImageView.backgroundColor = [UIColor clearColor];
        } else {
            _backgroundImageView.backgroundColor = self.barTintColor;
            if (!_backgroundEffectView) {
                UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent];
                _backgroundEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            }
            [_backgroundView insertSubview:_backgroundEffectView atIndex:0];
        }
        [self setNeedsLayout];
    }
}

- (void)setShadowImage:(UIImage *)shadowImage {
    if (_shadowImage != shadowImage) {
        _shadowImage = shadowImage;
        if (shadowImage) {
            if (!_shadowImageView) {
                _shadowImageView = [[UIImageView alloc] init];
            }
            _shadowImageView.image = shadowImage;
            [_backgroundView addSubview:_shadowImageView];
        } else {
            if (_shadowImageView) {
                [_shadowImageView removeFromSuperview];
                _shadowImageView = nil;
            }
        }
        [self setNeedsLayout];
    }
}

- (void)setUseLayoutSafeAreaInsets:(BOOL)useLayoutSafeAreaInsets {
    if (_useLayoutSafeAreaInsets != useLayoutSafeAreaInsets) {
        _useLayoutSafeAreaInsets = useLayoutSafeAreaInsets;
        [self setNeedsLayout];
    }
}

#pragma mark - Private

- (void)_tabBarDidSelectButton:(CYLFlatDesignTabBarButton *)tabBarButton {
    NSInteger selectedIndex = [_buttons indexOfObject:tabBarButton];
    CYLFlatDesignTabBarItem *item = self.items[selectedIndex];
    if (!item.isEnabled) return;
    
    if ([self.delegate respondsToSelector:@selector(tabBar:didSelectItem:)]) {
        [self.delegate tabBar:self didSelectItem:item];
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"


    if (self.tabBarController) {
        // 系统私有方法 _tabBarItemClicked:
        SEL sel = NSSelectorFromString(@"_tabBarItemClicked:");
        if ([self.tabBarController respondsToSelector:sel]) {
            UITabBarItem *systemItem = self.tabBarController.tabBar.items[selectedIndex];
            [self.tabBarController performSelector:sel withObject:systemItem];
        } else {
            // 万一某个版本系统私有方法 _tabBarItemClicked: 改了，做一个容错处理
            SEL customSEL = NSSelectorFromString(@"_qqtabBarItemClicked:");
            if ([self.tabBarController respondsToSelector:customSEL]) {
                [self.tabBarController performSelector:customSEL withObject:item];
            } else {
                [self _setSelectedIndex:selectedIndex];
            }
        }
    } else if (self.customTabBarController) {
        SEL sel = NSSelectorFromString(@"_tabBarItemClicked:");
        if ([self.customTabBarController respondsToSelector:sel]) {
            [self.customTabBarController performSelector:sel withObject:item afterDelay:0];
        } else {
            [self _setSelectedIndex:selectedIndex];
        }
    } else {
        [self _setSelectedIndex:selectedIndex];
    }
#pragma clang diagnostic pop
}

- (UITabBarController *)tabBarController {
    if ([self.delegate isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBarController = (UITabBarController *)self.delegate;
        return tabBarController;
    }
    return nil;
}

- (CYLFlatDesignTabViewController *)customTabBarController {
    if ([self.delegate isKindOfClass:[CYLFlatDesignTabViewController class]]) {
       return (CYLFlatDesignTabViewController *)self.delegate;
   }
   return nil;
}

- (void)_reloadItems {
    // remove old
    for (CYLFlatDesignTabBarButton *button in _buttons) {
        [button removeFromSuperview];
    }
    [_buttons removeAllObjects];
    
    // add tabBarButton
    for (NSInteger index = 0; index < self.items.count; index++) {
        CYLFlatDesignTabBarItem *item = self.items[index];
        CYLFlatDesignTabBarButton *button = [[CYLFlatDesignTabBarButton alloc] initWithTabBarItem:item];
        button.tintColor = self.tintColor;
        button.selected = (item == self.selectedItem);
        [button addTarget:self action:@selector(_tabBarDidSelectButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView insertSubview:button atIndex:0];
        [_buttons addObject:button];
    }
    
    [self setNeedsLayout];
}

- (void)_setSelectedIndex:(NSInteger)selectedIndex {
    if (_selectedItemIndex != selectedIndex) {
        _selectedItemIndex = selectedIndex;
        for (NSInteger i = 0; i < _buttons.count; i++) {
            CYLFlatDesignTabBarButton *button = _buttons[i];
            button.selected = (i == selectedIndex);
        }
    }
}

- (void)_updateLayout {
    if (CGRectIsEmpty(self.bounds)) {
        return;
    }
    
    // background
    _backgroundView.frame = self.bounds;
    
    _backgroundImageView.frame = _backgroundView.bounds;
    if (_backgroundEffectView) {
        _backgroundEffectView.frame = _backgroundView.bounds;
    }
    
    if (_shadowImageView) {
        CGFloat shadowImageHeight = 1.0 / UIScreen.mainScreen.scale;
        _shadowImageView.frame = CGRectMake(0, -shadowImageHeight, CGRectGetWidth(_backgroundView.frame), shadowImageHeight);
    }
    
    // 放在UITabBarController里
    CGFloat contentHeight = CGRectGetHeight(self.bounds) - self.safeAreaInsets.bottom;
    self.contentView.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), contentHeight);
    
    NSInteger itemCount = self.items.count;
    if (itemCount == 0) return;
    if (_buttons.count != itemCount) return;

    CGFloat contentWidth = CGRectGetWidth(self.contentView.frame);
    if (self.useLayoutSafeAreaInsets) {
        contentWidth -= (self.safeAreaInsets.left + self.safeAreaInsets.right);
    }
    
//    系统间距
//    CGFloat margin = 2.0;
//    CGFloat buttonSpace = 4.0;
//    CGFloat buttonY = 1.0;
    
    CGFloat margin = 0.0;
    CGFloat buttonSpace = 0.0;
    CGFloat buttonY = 0.0;
    CGFloat buttonWidth = 0;
    if (itemCount == 1) {
        buttonWidth = contentWidth - margin * 2;
    } else {
        buttonWidth = (contentWidth - margin * 2 - (itemCount - 1) * buttonSpace) / itemCount;
    }
    CGFloat buttonHeight = CGRectGetHeight(self.contentView.frame) - buttonY;

    for (NSInteger i = 0; i < self.items.count; i++) {
        CYLFlatDesignTabBarButton *button = _buttons[i];
        CGFloat buttonX = margin + i * (buttonWidth + buttonSpace);
        if (self.useLayoutSafeAreaInsets) {
            buttonX += self.safeAreaInsets.left;
        }
        button.frame = CGRectMake(buttonX, buttonY, buttonWidth, buttonHeight);
    }
}

@end
