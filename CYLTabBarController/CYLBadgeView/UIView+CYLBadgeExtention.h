/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import <UIKit/UIKit.h>
// FIX: issue #535 — shared with Core through CYLUtils. 通过 CYLUtils 与 Core 共用。
#if __has_include("../CYLUtils/UIView+CYLUtils.h")
#import "../CYLUtils/UIView+CYLUtils.h"
#else
#import "UIView+CYLUtils.h"
#endif
#import "CYLBadgeProtocol.h"
@protocol CYLBadgeTextDisplaying;

NS_ASSUME_NONNULL_BEGIN

#pragma mark -- badge apis

/*!
 * [EN] What VoiceOver says for a badge value: @"" (red dot) → "New content", a number → "3 new messages", @"new" / @"NEW" →
 *      their translation, other text as is; nil for nil or a number of 0 or less. Texts are in the app's language.
 * [CN] 角标值对应的 VoiceOver 朗读内容：@""（红点）→“有新内容”，数字 →“3 条新消息”，@"new" / @"NEW" → 其译文，其他文字原样；
 *      nil 或小于等于 0 的数字返回 nil。使用 App 当前语言。
 */
FOUNDATION_EXTERN NSString * _Nullable CYLBadgeAccessibilityDescription(NSString * _Nullable value);

/*!
 * [EN] `UIView (CYLBadgeExtention)` (`CYLBadgeProtocol` and the members below it) is implemented in Swift
 *      (`CYLBadgeView/Swift/UIView+CYLBadgeExtention.swift`) and declared by the generated Swift interface imported at the end
 *      of this header (docs/Swift-Migration.md, step 21). Every selector is kept. The conformance to `CYLBadgeProtocol` is
 *      declared here: its members are internal in Swift, so the generated header does not import the umbrella header.
 * [CN] `UIView (CYLBadgeExtention)`（`CYLBadgeProtocol` 及其下方的成员）在 Swift 中实现（`CYLBadgeView/Swift/UIView+CYLBadgeExtention.swift`），
 *      由本头文件末尾导入的 Swift 生成接口声明（docs/Swift-Migration.md，第 21 步）。保留所有 selector。遵守 `CYLBadgeProtocol` 的声明
 *      保留在这里：其成员在 Swift 中为 internal，因此生成的头文件不会导入伞头文件。
 */
@interface UIView (CYLBadgeExtention)<CYLBadgeProtocol>
@end


NS_ASSUME_NONNULL_END

#import "CYLSwiftInterface.h"
