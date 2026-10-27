//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "_CYLFlatDesignTabBarParallaxOverlayView.h"
#import "CYLTabBarController.h"
#import "UIViewController+CYLTabBarControllerExtention.h"
//#import "CYLFlatDesignUIViewController.h"
#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/CYLTabBarController.h>
#else
#import "CYLTabBarController.h"
#endif

static void *const CYLParallaxOverlayScrollViewContext = (void *)&CYLParallaxOverlayScrollViewContext;

@interface _CYLFlatDesignTabBarParallaxOverlayView ()
/// The scroll view this overlay is currently observing (see -didMoveToSuperview).
@property (nonatomic, weak) UIScrollView *cyl_observedScrollView;
@end

@implementation _CYLFlatDesignTabBarParallaxOverlayView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (void)dealloc {
    [self cyl_stopObservingScrollView];
}

#pragma mark - Pin to the visible area of a scrolling page (#662)

// FIX: issue #662
// The overlay is added to the page's view during push/pop. When that page is a
// UITableViewController / UICollectionViewController, its view is a UIScrollView, and
// subviews of a scroll view move with its content. The overlay's frame was set once to
// the scroll view's bounds, but the page can still settle its adjustedContentInset (and so
// its contentOffset) after that, e.g. on iPhone Duo built with the iOS 27.1 SDK, where the
// top inset changes from 24 to 82 as the navigation bar moves into the trailing status
// column. The overlay then slid down with the content by the difference (58 pt) and carried
// the tab bar off the bottom edge: the bar looked shorter until the transition ended.
// Keep the overlay's frame equal to the scroll view's visible bounds while it is attached.

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    [self cyl_stopObservingScrollView];
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    if (![self.superview isKindOfClass:[UIScrollView class]]) {
        return;
    }
    UIScrollView *scrollView = (UIScrollView *)self.superview;
    self.cyl_observedScrollView = scrollView;
    [scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:CYLParallaxOverlayScrollViewContext];
    [scrollView addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:CYLParallaxOverlayScrollViewContext];
    [self cyl_pinToScrollViewBounds];
}

- (void)cyl_stopObservingScrollView {
    UIScrollView *scrollView = self.cyl_observedScrollView;
    if (!scrollView) {
        return;
    }
    [scrollView removeObserver:self forKeyPath:@"contentOffset" context:CYLParallaxOverlayScrollViewContext];
    [scrollView removeObserver:self forKeyPath:@"bounds" context:CYLParallaxOverlayScrollViewContext];
    self.cyl_observedScrollView = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context != CYLParallaxOverlayScrollViewContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    [self cyl_pinToScrollViewBounds];
}

- (void)cyl_pinToScrollViewBounds {
    UIScrollView *scrollView = self.cyl_observedScrollView;
    if (!scrollView || CGRectEqualToRect(self.frame, scrollView.bounds)) {
        return;
    }
    [UIView performWithoutAnimation:^{
        self.frame = scrollView.bounds;
    }];
}

- (UIEdgeInsets)safeAreaInsets {
    UIViewController *currentViewController = [self cyl_parallaxCurrentViewController];
    /*!
     *
        CYLFlatDesignUIViewController *customTabBarController = currentViewController.cylflatdesign_tabBarController;
        if (customTabBarController) {
            return customTabBarController.view.safeAreaInsets;
        }

     */
    UITabBarController *tabBarController = currentViewController.cylflatdesign_tabBarController;
    if (tabBarController) {
        return tabBarController.view.safeAreaInsets;
    }
    return [super safeAreaInsets];
}

- (UIViewController *)cyl_parallaxCurrentViewController {
    UIResponder *next = self.nextResponder;
    do {
        if ([next isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)next;
        }
        next = next.nextResponder;
    } while (next != nil);
    return nil;
}

@end
