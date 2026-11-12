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

/*!
 * [EN] Implemented in Swift (`Swift/NSObject+CYLUtils.swift`); declared here for Objective-C callers only, and hidden from Swift
 *      (`__swift__`), which uses the Swift extension itself (docs/Swift-Migration.md).
 * [CN] 在 Swift 中实现（`Swift/NSObject+CYLUtils.swift`）；这里只为 Objective-C 调用方声明，并对 Swift 隐藏（`__swift__`），
 *      Swift 直接使用该 Swift 扩展（docs/Swift-Migration.md）。
 */
#ifndef __swift__
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
 * [EN] YES for the plus button's slot: the placeholder view controller of a plus button without a child view controller,
 *      or the tab button under the plus button. For a view controller, also YES when its navigation controller's root
 *      view controller is one. `-cyl_setHidden:` does not change it (it only changes visibility).
 * [CN] 是否为 PlusButton 的 slot：没有子控制器的 PlusButton 对应的占位控制器，或 PlusButton 下方的 Tab 按钮。对视图控制器而言，
 *      其导航控制器的根控制器是占位对象时也为 YES。`-cyl_setHidden:` 不会改变它（只改变可见性）。
 */
@property (nonatomic, assign, getter=cyl_isPlaceholder, setter=cyl_setIsPlaceholder:) BOOL cyl_isPlaceholder;

/*!
 * [EN] Stores `object` as an associated object of the receiver under `key`, holding it weakly: it is not retained, and
 *      `-cyl_weakAssociatedObjectForKey:` returns nil once it is deallocated. Use it to point back to an owner (e.g. a
 *      child to its tab bar controller) without a retain cycle. nil removes the value.
 * [CN] 以 `key` 把 `object` 保存为接收者的关联对象，且弱引用：不会被持有，释放后 `-cyl_weakAssociatedObjectForKey:` 返回 nil。
 *      用于指回持有者（例如子控制器指向其 TabBarController）而不产生循环引用。传 nil 会移除该值。
 */
- (void)cyl_setWeakAssociatedObject:(nullable id)object forKey:(const void *)key;

/*!
 * [EN] The object stored with `-cyl_setWeakAssociatedObject:forKey:`, or nil (never set, removed, or deallocated).
 * [CN] 通过 `-cyl_setWeakAssociatedObject:forKey:` 保存的对象；未设置、已移除或已释放时为 nil。
 */
- (nullable id)cyl_weakAssociatedObjectForKey:(const void *)key;

@end
#endif

NS_ASSUME_NONNULL_END
