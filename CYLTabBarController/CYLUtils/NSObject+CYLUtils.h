//
//  NSObject+CYLUtils.h
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

/*!
 * FIX: issue #535
 * [EN] Moved from `NSObject+CYLTabBarControllerExtention.h` (Core), which imports this header; shared with CYLBadgeView.
 * [CN] 从 Core 的 `NSObject+CYLTabBarControllerExtention.h` 移入（该头文件会导入本文件），与 CYLBadgeView 共用。
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (CYLUtils)

/*!
 * [EN] KVC `valueForKey:` that catches exceptions and returns nil instead of crashing.
 * [CN] 安全的 KVC 取值，捕获异常，失败时返回 nil 而不是崩溃。
 */
- (id)cyl_valueForKey:(NSString *)key;

/*!
 * [EN] KVC `setValue:forKey:` that catches exceptions instead of crashing.
 * [CN] 安全的 KVC 赋值，捕获异常而不是崩溃。
 */
- (void)cyl_setValue:(id)value forKey:(NSString *)key;

/*!
 * [EN] YES for a placeholder, e.g. the tab button under a plus button or a hidden view kept in place by
 *      `-cyl_setHidden:`. For a view controller, also YES when its navigation controller's root view controller is one.
 * [CN] 是否为占位对象，例如 PlusButton 下方的 Tab 按钮，或通过 `-cyl_setHidden:` 保留位置的视图。对视图控制器而言，
 *      其导航控制器的根控制器是占位对象时也为 YES。
 */
@property (nonatomic, assign, getter=cyl_isPlaceholder, setter=cyl_setIsPlaceholder:) BOOL cyl_isPlaceholder;

@end

NS_ASSUME_NONNULL_END
