//
//  CYLPlusButton.h
//  CYLCustomTabBarDemo
//
//  Created by 微博@iOS程序犭袁 (http://weibo.com/luohanchenyilong/) on 10/20/15.
//  Copyright © 2015 https://github.com/ChenYilong . All rights reserved.
//
@import Foundation;
#import <UIKit/UIKit.h>

@protocol CYLPlusButtonSubclassing
@required
+ (instancetype)plusButton;
@optional
+ (NSUInteger)indexOfPlusButtonInTabBar;
+ (CGFloat)multiplerInCenterY;
@end

@class CYLTabBar;

extern UIButton<CYLPlusButtonSubclassing> *CYLExternPushlishButton;

@interface CYLPlusButton : UIButton
+ (void)registerSubclass;
@end
