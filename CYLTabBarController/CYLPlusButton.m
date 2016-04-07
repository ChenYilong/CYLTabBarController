//
//  CYLPlusButton.m
//  CYLCustomTabBarDemo
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2015 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLPlusButton.h"
#import "CYLTabBarController.h"

CGFloat CYLPlusButtonWidth = 0.0f;

UIButton<CYLPlusButtonSubclassing> *CYLExternPlusButton = nil;

@implementation CYLPlusButton

#pragma mark -
#pragma mark - Private Methods

+ (void)registerSubclass {
    if ([self conformsToProtocol:@protocol(CYLPlusButtonSubclassing)]) {
        Class<CYLPlusButtonSubclassing> class = self;
        UIButton<CYLPlusButtonSubclassing> *plusButton = [class plusButton];
        CYLExternPlusButton = plusButton;
        CYLPlusButtonWidth = plusButton.frame.size.width;
    }
}

@end
