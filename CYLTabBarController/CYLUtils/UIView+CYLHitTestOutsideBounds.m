//
//  UIView+CYLHitTestOutsideBounds.m
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UIView+CYLHitTestOutsideBounds.h"
#import <objc/runtime.h>

/// [EN] YES once a view has used the property: until then the swizzled hit test costs nothing.
/// [CN] 有视图使用过该属性后为 YES：在此之前交换后的 hitTest 没有额外开销。
static BOOL CYLHitTestOutsideBoundsInUse = NO;

@implementation UIView (CYLHitTestOutsideBounds)

+ (void)cyl_installHitTestOutsideBoundsIfNeeded {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class viewClass = [UIView class];
        Method originalMethod = class_getInstanceMethod(viewClass, @selector(hitTest:withEvent:));
        Method swizzledMethod = class_getInstanceMethod(viewClass, @selector(cyl_outsideBoundsHitTest:withEvent:));
        if (!originalMethod || !swizzledMethod) {
            return;
        }
        method_exchangeImplementations(originalMethod, swizzledMethod);
        CYLHitTestOutsideBoundsInUse = YES;
    });
}

- (BOOL)cyl_respondsOutsideSuperviewBounds {
    return [objc_getAssociatedObject(self, @selector(cyl_respondsOutsideSuperviewBounds)) boolValue];
}

- (void)cyl_setRespondsOutsideSuperviewBounds:(BOOL)respondsOutsideSuperviewBounds {
    objc_setAssociatedObject(self, @selector(cyl_respondsOutsideSuperviewBounds), @(respondsOutsideSuperviewBounds), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (respondsOutsideSuperviewBounds) {
        [UIView cyl_installHitTestOutsideBoundsIfNeeded];
    }
}

/// [EN] After the exchange this runs as `-hitTest:withEvent:`, and this selector calls the original.
/// [CN] 交换后它作为 `-hitTest:withEvent:` 执行，调用本选择子即调用原实现。
- (UIView *)cyl_outsideBoundsHitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [self cyl_outsideBoundsHitTest:point withEvent:event];
    if (view || !CYLHitTestOutsideBoundsInUse) {
        return view;
    }
    if (self.hidden || self.alpha < 0.01 || !self.userInteractionEnabled) {
        return nil;
    }
    for (UIView *subview in self.subviews.reverseObjectEnumerator) {
        if (!subview.cyl_respondsOutsideSuperviewBounds) {
            continue;
        }
        UIView *hitView = [subview hitTest:[subview convertPoint:point fromView:self] withEvent:event];
        if (hitView) {
            return hitView;
        }
    }
    return nil;
}

@end
