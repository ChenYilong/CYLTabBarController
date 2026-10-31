//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarBadgeView.h"

/// Implemented in UIView+CYLBadgeExtention.m: tells the badge's host about a window or trait change.
@interface UIView (CYLBadgeEnvironmentNotifying)
- (void)cyl_notifyBadgeHostOfEnvironmentChange;
@end

@interface CYLTabBarBadgeView ()

@property (nonatomic, strong) UILabel *badgeLabel;

@end

@implementation CYLTabBarBadgeView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.layer.masksToBounds = YES;
        [self badgeLabel];
    }
    return self;
}

- (UILabel *)badgeLabel {
    if (!_badgeLabel) {
        _badgeLabel = [[UILabel alloc] initWithFrame:self.frame];
        _badgeLabel.textAlignment = NSTextAlignmentCenter;
        _badgeLabel.backgroundColor = [UIColor clearColor];
        _badgeLabel.text = @"test";
        // FIX: issue #653 — the label is laid out by frame in -layoutSubviews; keep it out of Auto Layout
        // (Auto Layout inside a tab button breaks the iOS 27.1 vertical bar).
        _badgeLabel.translatesAutoresizingMaskIntoConstraints = YES;

//        _badgeLabel.font = kCYLBadgeDefaultFont;//[UIFont systemFontOfSize:11];
        _badgeLabel.textColor = [UIColor whiteColor];
        
        [self addSubview:_badgeLabel];
        [self bringSubviewToFront:_badgeLabel];
        _badgeLabel.layer.zPosition = MAXFLOAT;
    }
    return _badgeLabel;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (CGRectEqualToRect(CGRectZero, self.bounds)) {
        return;
    }
    if (CGRectEqualToRect(self.badgeLabel.frame, self.bounds)) {
        return;
    }
     
//    self.frame = self.bounds;
//    [self setNeedsDisplay];

    self.badgeLabel.frame = self.bounds;

//    self.badgeLabel.center = self.center;

}

/*!
 * Why `-setFrame:` does not hand its `frame` argument to the label, and uses `self.bounds` instead
 * 为什么 `-setFrame:` 不把传入的 `frame` 直接交给 Label，而是使用 `self.bounds`
 *
 * [EN] Two views, two coordinate spaces.
 *      - `frame` (the argument) is this badge's rectangle in its SUPERVIEW's coordinates ("where the badge is
 *        on the tab button").
 *      - `badgeLabel` is a subview of this badge, so its own `frame` is in the BADGE's coordinates ("where the
 *        text is inside the badge"). The text should fill the badge, so that is `bounds`: origin (0, 0), the badge's size.
 *
 *      Example: the tab button places the badge at `{x: 50, y: -4, w: 20, h: 16}`.
 *        - Wrong, the old code (`label.frame = frame`): the label gets `{50, -4, 20, 16}` inside a 20 x 16 badge,
 *          so the text sits 50 points to the right and 4 above, outside the badge, until the next layout pass.
 *        - Right (`label.frame = self.bounds`): the label gets `{0, 0, 20, 16}`, which covers the badge exactly.
 *      Copying the origin is always wrong; copying only the size (`frame.size`) would work only while the view has
 *      no transform (with a scale or rotation, `frame.size` is the size of the transformed bounding box, `bounds.size`
 *      is the real size).
 *
 *      The argument is not ignored: `[super setFrame:frame]` applies it first, and `bounds` is read afterwards,
 *      so it is the size UIKit actually ended up with (UIKit and Auto Layout may adjust or override what is asked for).
 *
 *      `-setBounds:` changes the size as well, so it is synced the same way. `-layoutSubviews` does the same, which is
 *      the fallback; the overrides only make the label correct immediately, before the next layout pass.
 *
 *      There is no `-setCenter:` override on purpose. `center` is also in the superview's coordinates, and moving the
 *      badge changes neither `bounds` nor where the label sits inside it. The old override copied the center to the
 *      label, which only moved the text out of the badge.
 * [CN] 两个视图，两个坐标系。
 *      - 参数 `frame` 是本角标在 **父视图** 坐标系中的矩形（"角标在 Tab 按钮上的位置"）。
 *      - `badgeLabel` 是本角标的子视图，它自己的 `frame` 在 **角标自身** 坐标系中（"文字在角标内的位置"）。
 *        文字应该铺满角标，所以应该是 `bounds`：原点 (0, 0)，尺寸等于角标尺寸。
 *
 *      例：Tab 按钮把角标放在 `{x: 50, y: -4, w: 20, h: 16}`。
 *        - 错误（旧代码 `label.frame = frame`）：Label 在 20 x 16 的角标里得到 `{50, -4, 20, 16}`，
 *          文字向右偏 50 点、向上偏 4 点，跑到角标外面，直到下一次布局。
 *        - 正确（`label.frame = self.bounds`）：Label 得到 `{0, 0, 20, 16}`，刚好盖住角标。
 *      原点永远不能复制；只复制尺寸（`frame.size`）仅在视图没有 transform 时才对（有缩放或旋转时，
 *      `frame.size` 是变换后外接矩形的大小，`bounds.size` 才是真实大小）。
 *
 *      参数并没有被忽略：先由 `[super setFrame:frame]` 应用它，然后才读取 `bounds`，
 *      所以得到的是 UIKit 最终采用的尺寸（UIKit 和自动布局可能调整或覆盖所请求的值）。
 *
 *      `-setBounds:` 同样改变尺寸，所以用同样的方式同步。`-layoutSubviews` 也做同样的事，作为兜底；
 *      这里的重写只是让 Label 在下一次布局之前就立即正确。
 *
 *      有意不重写 `-setCenter:`。`center` 同样是父视图坐标系中的值，移动角标既不改变 `bounds`，
 *      也不改变 Label 在角标内的位置。旧的重写把 center 赋给 Label，只会让文字移出角标。
 */
- (void)cyl_syncBadgeLabelWithBounds {
    if (CGRectIsEmpty(self.bounds)) {
        return;
    }
    self.badgeLabel.frame = self.bounds;
}

- (void)setFrame:(CGRect)frame {
    // `frame` is applied here, by super. The label then follows this view's `bounds`, not `frame` (superview-space
    // origin, see the long comment on -cyl_syncBadgeLabelWithBounds).
    // 这里由 super 应用 `frame`；Label 随后跟随本视图的 `bounds` 而不是 `frame`（父视图坐标系的原点，详见 -cyl_syncBadgeLabelWithBounds 上的说明）。
    [super setFrame:frame];
    [self cyl_syncBadgeLabelWithBounds];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self cyl_syncBadgeLabelWithBounds];
}

/*!
 * There is intentionally NO `-setCenter:` override here, which is why this class does not treat `center` like `frame`
 * 这里有意没有重写 `-setCenter:`，所以本类对 `center` 的处理与 `frame` 不一致
 *
 * [EN] Not an omission: the override that used to be here was removed because it was wrong, and nothing needs its job.
 *      - `-setFrame:` and `-setBounds:` can change the badge's SIZE. The label fills the badge, so it must be resized to
 *        match: they call `-cyl_syncBadgeLabelWithBounds`.
 *      - `-setCenter:` changes only WHERE the badge is in its superview. The size, and so `bounds`, stay the same, and
 *        the label, which fills `bounds`, is still correct. There is nothing to sync.
 *      The removed override did `badgeLabel.center = center`. `center` is in the superview's coordinates and
 *      `badgeLabel.center` in the badge's own, so for a badge at `center = (60, 4)` and size 20 x 16 it put the label's
 *      center at (60, 4), outside a badge whose bounds are {0, 0, 20, 16}. Because a move does not trigger
 *      `-layoutSubviews`, the offset stayed until the next resize. (`-layoutSubviews` only repaired it when the size changed.)
 *      `CYLBadgeLabel` and `UILabel` do not mirror a position either: only the host positions the badge, with
 *      `-cyl_layoutBadgeAtTopRightCorner` in UIView+CYLBadgeExtention.m.
 *      If a future change makes the label something other than "fills bounds", sync it from `-layoutSubviews`, not here.
 * [CN] 不是遗漏：这里原有的重写因为本身是错的而被删除，并且没有任何需要它来完成的工作。
 *      - `-setFrame:` 和 `-setBounds:` 可能改变角标的 **尺寸**。Label 铺满角标，所以必须随之调整大小：它们调用 `-cyl_syncBadgeLabelWithBounds`。
 *      - `-setCenter:` 只改变角标在父视图中的 **位置**。尺寸即 `bounds` 不变，铺满 `bounds` 的 Label 依然正确，没有需要同步的内容。
 *      被删除的重写执行 `badgeLabel.center = center`。`center` 在父视图坐标系中，而 `badgeLabel.center` 在角标自身坐标系中：
 *      角标 `center = (60, 4)`、尺寸 20 x 16 时，它会把 Label 的中心放到 (60, 4)，在 `bounds` 为 {0, 0, 20, 16} 的角标之外。
 *      由于移动不会触发 `-layoutSubviews`，这个偏移会一直保留到下一次尺寸变化。（`-layoutSubviews` 只在尺寸改变时才能修复。）
 *      `CYLBadgeLabel` 和 `UILabel` 也不会镜像位置：只有宿主负责放置角标，使用 UIView+CYLBadgeExtention.m 中的 `-cyl_layoutBadgeAtTopRightCorner`。
 *      如果以后 Label 不再"铺满 bounds"，应在 `-layoutSubviews` 中同步，而不是在这里。
 */

- (void)didMoveToWindow {
    [super didMoveToWindow];
    [self cyl_notifyBadgeHostOfEnvironmentChange];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self cyl_notifyBadgeHostOfEnvironmentChange];
}
#pragma clang diagnostic pop

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    _textAlignment = textAlignment;
    if (textAlignment) {
        [self.badgeLabel setTextAlignment:textAlignment];
    }
}

- (void)setTextColor:(UIColor *)badgeTextColor {
    _textColor = badgeTextColor;
    if (badgeTextColor) {
        self.badgeLabel.textColor = badgeTextColor;
    }
}

- (void)setFont:(UIFont *)badgeTextFont {
    _font = badgeTextFont;
    if (badgeTextFont) {
        self.badgeLabel.font = badgeTextFont;
    }
}

- (void)setText:(NSString *)badgeValue {
    if (![_text isEqualToString:badgeValue]) {
        _text = [badgeValue copy];
        self.badgeLabel.text = [badgeValue copy];
    }
}

- (void)setBadgeContentInset:(UIEdgeInsets)badgeContentInset {
    if (!UIEdgeInsetsEqualToEdgeInsets(_badgeContentInset, badgeContentInset)) {
        _badgeContentInset = badgeContentInset;
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    if (_text.length == 0) {
        return CGSizeZero;
    }
    CGSize badgeSize = [_text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:0 attributes:@{NSFontAttributeName:self.badgeLabel.font} context:nil].size;
    CGFloat width = badgeSize.width + _badgeContentInset.left + _badgeContentInset.right;
    CGFloat height = badgeSize.height + _badgeContentInset.top + _badgeContentInset.bottom;
    height = MAX(height, 18.0);
    width = MAX(width, height);
    return CGSizeMake(width, height);
}

@end
