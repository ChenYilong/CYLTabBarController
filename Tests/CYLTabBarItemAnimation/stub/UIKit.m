#import <UIKit/UIKit.h>

@implementation UITraitCollection
@end

@implementation UIColor
- (UIColor *)resolvedColorWithTraitCollection:(UITraitCollection *)traitCollection {
    (void)traitCollection;
    return self;
}
@end

@implementation UIView
@end
