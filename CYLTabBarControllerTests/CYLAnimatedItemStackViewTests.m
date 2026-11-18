//
//  CYLAnimatedItemStackViewTests.m
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CYLTabBarController/CYLTabBarController.h>
@import CYLAnimatedItem;
#import "CYLTabBarControllerTests-Swift.h"

/*
 * [EN] CYLAnimatedItemStackView (Swift): every element is a CYLAnimatedItemView; actions, background action, accessibility
 *      and wrapping, the work CYLTableViewPlaceHolder's CYLPlaceholderStackView did. Written in Objective-C on purpose:
 *      it checks the Objective-C API that CYLTableViewPlaceHolder (an Objective-C library) calls.
 * [CN] CYLAnimatedItemStackView：每个元素都是 CYLAnimatedItemView；动作、背景动作、无障碍与换行，即 CYLTableViewPlaceHolder 的
 *      CYLPlaceholderStackView 所做的工作。有意用 Objective-C 编写：检查 CYLTableViewPlaceHolder（Objective-C 库）调用的 Objective-C API。
 */
@interface CYLAnimatedItemStackViewTests : XCTestCase
@end

@implementation CYLAnimatedItemStackViewTests

/*
 * [EN] Runs the touch-up-inside actions of `control`: logic tests have no UIApplication, so
 *      -sendActionsForControlEvents: delivers nothing (as in CYLAnimatedItemViewTests).
 * [CN] 执行 `control` 的 touch-up-inside 事件：逻辑测试没有 UIApplication，-sendActionsForControlEvents: 不会派发事件（同 CYLAnimatedItemViewTests）。
 */
- (void)sendTouchUpInsideTo:(UIControl *)control {
    for (id target in control.allTargets) {
        for (NSString *name in [control actionsForTarget:target forControlEvent:UIControlEventTouchUpInside]) {
            SEL action = NSSelectorFromString(name);
            IMP imp = [target methodForSelector:action];
            ((void (*)(id, SEL, id))imp)(target, action, control);
        }
    }
}

- (CYLAnimatedItemView *)itemWithTitle:(NSString *)title {
    CYLAnimatedItemView *item = [[CYLAnimatedItemView alloc] initWithFrame:CGRectZero];
    item.axis = CYLAnimatedItemAxisVertical;
    item.title = title;
    return item;
}

- (void)testItemsAreArrangedInOrderAndFirstIsReserved {
    CYLAnimatedItemView *first = [self itemWithTitle:@"No messages"];
    CYLAnimatedItemView *second = [self itemWithTitle:@"Pull to refresh"];
    CYLAnimatedItemStackView *stack = [[CYLAnimatedItemStackView alloc] initWithItemViews:@[first, second] actions:nil];
    XCTAssertEqualObjects(stack.itemViews, (@[first, second]));
    XCTAssertEqual(stack.firstItemView, first);
    XCTAssertEqualObjects(stack.stackView.arrangedSubviews, (@[first, second]));
    XCTAssertEqual(stack.stackView.axis, UILayoutConstraintAxisVertical);
    XCTAssertEqual(stack.stackView.alignment, UIStackViewAlignmentCenter);
    for (UIView *view in stack.stackView.arrangedSubviews) {
        XCTAssertTrue([view isKindOfClass:CYLAnimatedItemView.class]);
    }
}

- (void)testEmptyStackHasNoFirstItem {
    CYLAnimatedItemStackView *stack = [[CYLAnimatedItemStackView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    XCTAssertNil(stack.firstItemView);
    XCTAssertEqual(stack.itemViews.count, 0u);
}

- (void)testAppendIgnoresDuplicatesAndSetsSpacing {
    CYLAnimatedItemStackView *stack = [[CYLAnimatedItemStackView alloc] initWithItemViews:@[] actions:nil];
    CYLAnimatedItemView *first = [stack appendItemWithTitle:@"Empty" image:nil animationURL:nil action:nil spacingBefore:0];
    CYLAnimatedItemView *second = [stack appendItemWithTitle:@"Retry" image:nil animationURL:nil action:@"retry" spacingBefore:24];
    [stack appendItemView:first action:nil spacingBefore:8];
    XCTAssertEqual(stack.itemViews.count, 2u);
    XCTAssertEqual([stack.stackView customSpacingAfterView:first], 24);
    XCTAssertEqual(second.axis, CYLAnimatedItemAxisVertical);
    XCTAssertEqual(second.titleLabel.numberOfLines, 0);
}

- (void)testItemTapPerformsItsAction {
    __block NSString *performed = nil;
    CYLAnimatedItemStackView *stack = [[CYLAnimatedItemStackView alloc] initWithItemViews:@[] actions:@{
        @"retry": ^(CYLAnimatedItemStackView *view, NSString *action) { performed = action; },
    }];
    [stack appendItemWithTitle:@"Empty" image:nil animationURL:nil action:nil spacingBefore:0];
    CYLAnimatedItemView *retry = [stack appendItemWithTitle:@"Retry" image:nil animationURL:nil action:@"retry" spacingBefore:16];
    [self sendTouchUpInsideTo:retry];
    XCTAssertEqualObjects(performed, @"retry");
    XCTAssertEqual([stack itemViewForAction:@"retry"], retry);
    XCTAssertEqualObjects([stack actionForItemView:retry], @"retry");
    XCTAssertNil([stack itemViewForAction:@"missing"]);
}

- (void)testItemWithoutActionTakesNoTouches {
    CYLAnimatedItemStackView *stack = [[CYLAnimatedItemStackView alloc] initWithItemViews:@[] actions:nil];
    CYLAnimatedItemView *hint = [stack appendItemWithTitle:@"Hint" image:nil animationURL:nil action:nil spacingBefore:0];
    XCTAssertFalse(hint.userInteractionEnabled);
    [stack setAction:@"open" forItemView:hint];
    XCTAssertTrue(hint.userInteractionEnabled);
    [stack setAction:nil forItemView:hint];
    XCTAssertFalse(hint.userInteractionEnabled);
    XCTAssertNil([stack actionForItemView:hint]);
}

- (void)testHandlersCanBeSetAndRemoved {
    __block NSInteger count = 0;
    CYLAnimatedItemStackView *stack = [[CYLAnimatedItemStackView alloc] initWithItemViews:@[] actions:nil];
    XCTAssertFalse([stack performAction:@"retry"]);
    [stack setHandler:^(CYLAnimatedItemStackView *view, NSString *action) { count++; } forAction:@"retry"];
    XCTAssertTrue([stack performAction:@"retry"]);
    [stack setHandler:nil forAction:@"retry"];
    XCTAssertFalse([stack performAction:@"retry"]);
    XCTAssertEqual(count, 1);
}

- (void)testBackgroundActionAndVoiceOver {
    __block NSInteger count = 0;
    CYLAnimatedItemStackView *stack = [[CYLAnimatedItemStackView alloc] initWithItemViews:@[] actions:@{
        @"reload": ^(CYLAnimatedItemStackView *view, NSString *action) { count++; },
    }];
    CYLAnimatedItemView *first = [stack appendItemWithTitle:@"No connection" image:nil animationURL:nil action:nil spacingBefore:0];
    XCTAssertFalse(first.accessibilityTraits & UIAccessibilityTraitButton, @"text without an action is not a button");
    XCTAssertTrue(first.accessibilityTraits & UIAccessibilityTraitStaticText);
    stack.backgroundAction = @"reload";
    XCTAssertTrue(first.accessibilityTraits & UIAccessibilityTraitButton, @"VoiceOver reaches the background action");
    XCTAssertTrue([stack accessibilityActivate]);
    XCTAssertEqual(count, 1);
    stack.backgroundAction = nil;
    XCTAssertFalse(first.accessibilityTraits & UIAccessibilityTraitButton);
    XCTAssertFalse([stack accessibilityActivate]);
    XCTAssertTrue(stack.shouldGroupAccessibilityChildren);
}

- (void)testTraitsSurviveTitleChange {
    CYLAnimatedItemStackView *stack = [[CYLAnimatedItemStackView alloc] initWithItemViews:@[] actions:nil];
    CYLAnimatedItemView *hint = [stack appendItemWithTitle:@"Hint" image:nil animationURL:nil action:nil spacingBefore:0];
    hint.title = @"Another hint";
    XCTAssertFalse(hint.accessibilityTraits & UIAccessibilityTraitButton);
    XCTAssertTrue(hint.isAccessibilityElement);
}

- (void)testDecorativeItemIsHiddenFromVoiceOver {
    CYLAnimatedItemStackView *stack = [[CYLAnimatedItemStackView alloc] initWithItemViews:@[] actions:nil];
    [stack appendItemWithTitle:@"Empty" image:nil animationURL:nil action:nil spacingBefore:0];
    CYLAnimatedItemView *separator = [stack appendItemWithTitle:nil image:[UIImage new] animationURL:nil action:nil spacingBefore:8];
    XCTAssertFalse(separator.isAccessibilityElement);
    XCTAssertTrue(separator.accessibilityElementsHidden);
    separator.accessibilityLabel = @"Divider";
    XCTAssertTrue(separator.isAccessibilityElement);
}

- (void)testRemoveItemMovesTheReservedRole {
    CYLAnimatedItemStackView *stack = [[CYLAnimatedItemStackView alloc] initWithItemViews:@[] actions:nil];
    CYLAnimatedItemView *first = [stack appendItemWithTitle:@"One" image:nil animationURL:nil action:nil spacingBefore:0];
    CYLAnimatedItemView *second = [stack appendItemWithTitle:@"Two" image:nil animationURL:nil action:nil spacingBefore:0];
    stack.backgroundAction = @"reload";
    [stack removeItemView:first];
    XCTAssertNil(first.superview);
    XCTAssertEqual(stack.firstItemView, second);
    XCTAssertTrue(second.accessibilityTraits & UIAccessibilityTraitButton);
}

- (void)testLongTitleWrapsToTheViewWidth {
    CYLAnimatedItemStackView *stack = [[CYLAnimatedItemStackView alloc] initWithItemViews:@[] actions:nil];
    stack.frame = CGRectMake(0, 0, 200, 600);
    NSString *text = @"A very long hint that cannot fit on one line of a narrow placeholder, so it wraps onto several lines";
    CYLAnimatedItemView *hint = [stack appendItemWithTitle:text image:nil animationURL:nil action:nil spacingBefore:0];
    [stack setNeedsLayout];
    [stack layoutIfNeeded];
    XCTAssertLessThanOrEqual(CGRectGetWidth(hint.frame), 200 - 2 * stack.contentMargin + 0.5);
    CGFloat oneLine = ceil(hint.titleLabel.font.lineHeight);
    XCTAssertGreaterThan(CGRectGetHeight(hint.frame), oneLine * 1.5, @"the title wraps instead of widening the stack");
}

- (void)testDisabledItemTakesNoTapsAndIsNotAButton {
    __block NSInteger count = 0;
    CYLAnimatedItemStackView *stack = [[CYLAnimatedItemStackView alloc] initWithItemViews:@[] actions:@{
        @"retry": ^(CYLAnimatedItemStackView *view, NSString *action) { count++; },
    }];
    CYLAnimatedItemView *retry = [stack appendItemWithTitle:@"Retry" image:nil animationURL:nil action:@"retry" spacingBefore:0];
    XCTAssertTrue([stack isItemViewInteractive:retry]);
    retry.enabled = NO;
    XCTAssertFalse([stack isItemViewInteractive:retry]);
    XCTAssertFalse(retry.userInteractionEnabled, @"a disabled item lets the background act");
    XCTAssertFalse(retry.accessibilityTraits & UIAccessibilityTraitButton);
    [self sendTouchUpInsideTo:retry];
    XCTAssertEqual(count, 0);
    retry.enabled = YES;
    XCTAssertTrue(retry.userInteractionEnabled);
    [self sendTouchUpInsideTo:retry];
    XCTAssertEqual(count, 1);
}

- (void)testSubclassDecidesWhichItemsAreInteractive {
    __block NSInteger count = 0;
    CYLAnimatedItemTestStack *stack = [[CYLAnimatedItemTestStack alloc] initWithItemViews:@[] actions:@{
        @"retry": ^(CYLAnimatedItemStackView *view, NSString *action) { count++; },
    }];
    [stack appendItemWithTitle:@"No connection" image:nil animationURL:nil action:nil spacingBefore:0];
    CYLAnimatedItemView *retry = [stack appendItemWithTitle:@"Retry" image:nil animationURL:nil action:@"retry" spacingBefore:16];
    stack.blockedItemViews = @[retry];
    XCTAssertFalse(retry.userInteractionEnabled, @"an item with an action but interaction off lets the background act");
    XCTAssertFalse(retry.accessibilityTraits & UIAccessibilityTraitButton);
    XCTAssertEqualObjects([stack actionForItemView:retry], @"retry", @"the action is kept");
    [self sendTouchUpInsideTo:retry];
    XCTAssertEqual(count, 0);
    stack.blockedItemViews = @[];
    XCTAssertTrue(retry.userInteractionEnabled);
    [self sendTouchUpInsideTo:retry];
    XCTAssertEqual(count, 1);
}

@end
