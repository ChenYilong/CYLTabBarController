//
//  CYLTabBarControllerTests.m
//  CYLTabBarControllerTests
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 15/10/25.
// [CN] Copyright (c) 2026年 https://github.com/ChenYilong .All rights reserved.
// [EN] Copyright (c) 2026 https://github.com/ChenYilong .All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <CYLTabBarController/CYLTabBarController.h>

@interface CYLTabBarControllerTests : XCTestCase

@end

@implementation CYLTabBarControllerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

/// [EN] `reportsTapsToDelegate` replaces the deprecated `cyl_userInteractionDisabled` for the plus button's reports: YES by
///      default, the deprecated flag still opts out while the property is not set, and a value set on it wins.
/// [CN] `reportsTapsToDelegate` 取代已废弃的 `cyl_userInteractionDisabled` 控制 PlusButton 的上报：默认 YES；未设置时废弃标记仍可关闭上报；
///      设置后以它为准。
- (void)testPlusButtonReportsTapsToDelegate {
    CYLPlusButton *plusButton = [[CYLPlusButton alloc] init];
    XCTAssertTrue(plusButton.reportsTapsToDelegate, @"reported by default");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    plusButton.cyl_userInteractionDisabled = YES;
    XCTAssertFalse(plusButton.reportsTapsToDelegate, @"the deprecated flag still opts out while the property is not set");
    plusButton.reportsTapsToDelegate = YES;
    XCTAssertTrue(plusButton.reportsTapsToDelegate, @"a value set on the property wins over the deprecated flag");
    XCTAssertTrue(plusButton.cyl_userInteractionDisabled, @"the deprecated flag itself is unchanged");
#pragma clang diagnostic pop
    plusButton.reportsTapsToDelegate = NO;
    XCTAssertFalse(plusButton.reportsTapsToDelegate);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
