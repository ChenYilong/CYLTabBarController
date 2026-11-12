//
//  CYLUtilsSwiftTests.m
//  CYLTabBarControllerTests
//
//  [EN] The CYLUtils helpers translated to Swift (docs/Swift-Migration.md), called from Objective-C through the old
//       headers, so the selectors are checked too.
//  [CN] 已翻译为 Swift 的 CYLUtils 辅助方法（docs/Swift-Migration.md），通过原来的头文件从 Objective-C 调用，同时检查 selector。
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <CYLTabBarController/CYLTabBarController.h>
#import <objc/runtime.h>

@interface CYLUtilsSwiftTestsObject : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger count;
@end

@implementation CYLUtilsSwiftTestsObject
@end

static char CYLUtilsSwiftTestsWeakKey;

@interface CYLUtilsSwiftTests : XCTestCase
@end

@implementation CYLUtilsSwiftTests

/// [EN] Known keys work; an unknown key and nil for a scalar do not raise. [CN] 已知 key 正常；未知 key 与给标量传 nil 不抛异常。
- (void)testSafeKeyValueCoding {
    CYLUtilsSwiftTestsObject *object = [CYLUtilsSwiftTestsObject new];
    [object cyl_setValue:@"tab" forKey:@"name"];
    XCTAssertEqualObjects([object cyl_valueForKey:@"name"], @"tab");
    [object cyl_setValue:@3 forKey:@"count"];
    XCTAssertEqualObjects([object cyl_valueForKey:@"count"], @3);
    XCTAssertNoThrow([object cyl_setValue:nil forKey:@"count"]);
    XCTAssertEqual(object.count, 3, @"nil for a scalar is ignored");
    XCTAssertNoThrow([object cyl_setValue:@1 forKey:@"missing"]);
    XCTAssertNil([object cyl_valueForKey:@"missing"]);
    XCTAssertEqualObjects([@{@"a" : @1} cyl_valueForKey:@"a"], @1, @"a class that handles KVC itself is asked directly");
}

/// [EN] A view controller's flag is also set on, and read from, its root view controller. [CN] 视图控制器的标记也写入并读取其根控制器。
- (void)testPlaceholderFlagFollowsTheRootViewController {
    UIViewController *root = [UIViewController new];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:root];
    XCTAssertFalse(navigationController.cyl_isPlaceholder);
    navigationController.cyl_isPlaceholder = YES;
    XCTAssertTrue(navigationController.cyl_isPlaceholder);
    XCTAssertTrue(root.cyl_isPlaceholder, @"set on the root view controller too");
    UIView *view = [UIView new];
    view.cyl_isPlaceholder = YES;
    XCTAssertTrue(view.cyl_isPlaceholder);
    XCTAssertTrue([view cyl_canNotResponseEvent]);
}

/// [EN] A weak associated object goes away with its object. [CN] 弱关联对象随对象释放而消失。
- (void)testWeakAssociatedObject {
    NSObject *owner = [NSObject new];
    @autoreleasepool {
        NSObject *value = [NSObject new];
        [owner cyl_setWeakAssociatedObject:value forKey:&CYLUtilsSwiftTestsWeakKey];
        XCTAssertEqual([owner cyl_weakAssociatedObjectForKey:&CYLUtilsSwiftTestsWeakKey], value);
        value = nil;
    }
    XCTAssertNil([owner cyl_weakAssociatedObjectForKey:&CYLUtilsSwiftTestsWeakKey]);
    [owner cyl_setWeakAssociatedObject:nil forKey:&CYLUtilsSwiftTestsWeakKey];
    XCTAssertNil([owner cyl_weakAssociatedObjectForKey:&CYLUtilsSwiftTestsWeakKey]);
}

/// [EN] A flagged subview receives touches outside its superview's bounds. [CN] 设置了标记的子视图接收父视图范围之外的触摸。
- (void)testHitTestOutsideSuperviewBounds {
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    UIView *child = [[UIView alloc] initWithFrame:CGRectMake(90, 90, 40, 40)];
    [container addSubview:child];
    XCTAssertNil([container hitTest:CGPointMake(120, 120) withEvent:nil], @"UIKit alone: outside the bounds");
    child.cyl_respondsOutsideSuperviewBounds = YES;
    XCTAssertTrue(child.cyl_respondsOutsideSuperviewBounds);
    XCTAssertEqual([container hitTest:CGPointMake(120, 120) withEvent:nil], child);
    XCTAssertEqual([container hitTest:CGPointMake(10, 10) withEvent:nil], container, @"inside: as UIKit");
    child.cyl_respondsOutsideSuperviewBounds = NO;
    XCTAssertNil([container hitTest:CGPointMake(120, 120) withEvent:nil]);
}

/// [EN] Hiding, visibility and the nearest control. [CN] 隐藏、可见性与最近的控件。
- (void)testViewHelpers {
    UIView *superview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    UIControl *control = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    UIView *leaf = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    [superview addSubview:control];
    [control addSubview:leaf];
    XCTAssertEqual([leaf cyl_nearestControlBelowView:nil], control);
    XCTAssertNil([leaf cyl_nearestControlBelowView:control], @"the stop view is not included");
    XCTAssertFalse([leaf cyl_isInvisiable]);
    [leaf cyl_setHidden:YES];
    XCTAssertTrue(leaf.hidden);
    XCTAssertEqual(leaf.alpha, 0);
    XCTAssertFalse(leaf.userInteractionEnabled);
    XCTAssertTrue([leaf cyl_isInvisiable]);
    [leaf cyl_setHidden:NO];
    XCTAssertTrue(leaf.userInteractionEnabled);
    XCTAssertNil([[UIBarItem new] cyl_view], @"a plain UIBarItem has no view");
}

@end
