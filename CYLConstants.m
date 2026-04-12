//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.21.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2018 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLConstants.h"

@implementation CYLConstants

static CGFloat uiBasisWScale_ = 1.0;
static CGFloat uiBasisHScale_ = 1.0;

+ (void)initialize {
//    uiBasisWScale_ =  / 375.0;
//    uiBasisHScale_ = Env.screenHeight / 667.0;
}

+ (CGFloat)UIBasisWidthScale {
    return uiBasisWScale_;
}

+ (CGFloat)UIBasisHeightScale {
    return uiBasisHScale_;
}

@end
