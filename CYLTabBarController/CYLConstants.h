//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.14.0 Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2015 https://github.com/ChenYilong . All rights reserved.
//

#ifndef CYLConstants_h
#define CYLConstants_h

#define CYL_DEPRECATED(explain) __attribute__((deprecated(explain)))
#define CYL_IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define CYL_IS_IPHONE_X (CYL_IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 812.0f)
#define CYL_IS_IOS_11  ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.f)

#endif /* CYLConstants_h */


