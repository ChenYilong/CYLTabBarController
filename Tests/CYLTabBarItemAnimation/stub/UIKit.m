#import <UIKit/UIKit.h>

@implementation UITraitCollection
@end

@implementation UIColor
- (UIColor *)resolvedColorWithTraitCollection:(UITraitCollection *)traitCollection {
    (void)traitCollection;
    return self;
}
@end

@interface UIView ()
@property (nonatomic, weak, readwrite) UIView *superview;
@end

@implementation UIView {
    NSMutableArray<UIView *> *_subviewList;
}
- (CGRect)bounds {
    return CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
}
- (NSArray<UIView *> *)subviews {
    return _subviewList ? [_subviewList copy] : @[];
}
- (void)insertSubview:(UIView *)view atIndex:(NSUInteger)index {
    [view removeFromSuperview];
    if (!_subviewList) {
        _subviewList = [NSMutableArray array];
    }
    [_subviewList insertObject:view atIndex:MIN(index, _subviewList.count)];
    view.superview = self;
}
- (void)addSubview:(UIView *)view {
    [self insertSubview:view atIndex:NSUIntegerMax];
}
- (void)insertSubview:(UIView *)view aboveSubview:(UIView *)siblingSubview {
    NSUInteger index = [_subviewList indexOfObject:siblingSubview];
    [self insertSubview:view atIndex:(index == NSNotFound ? NSUIntegerMax : index + 1)];
}
- (void)removeFromSuperview {
    UIView *superview = self.superview;
    if (superview) {
        [superview->_subviewList removeObject:self];
    }
    self.superview = nil;
}
@end

@implementation UIControl
@end
