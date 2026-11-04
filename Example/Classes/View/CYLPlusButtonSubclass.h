//
//  CYLPlusButtonSubclass.h
//  CYLTabBarControllerDemo
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 15/10/24.
// [CN] Copyright (c) 2026年 https://github.com/ChenYilong . All rights reserved.
// [EN] Copyright (c) 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLPlusButton.h"

@interface CYLPlusButtonSubclass : CYLPlusButton <CYLPlusButtonSubclassing>

/*!
 * [EN] The title under the icon. `CYLSecondPlusButtonSubclass` overrides it.
 * [CN] 图标下方的标题。`CYLSecondPlusButtonSubclass` 重写了它。
 */
+ (NSString *)plusButtonTitle;

/*!
 * [EN] The plus button class the NEXT tab bar controller should use: the other one of the demo's two plus buttons,
 *      i.e. not the one of the tab bar controller `owner` (a view or view controller in it) belongs to. Both stay
 *      registered, each for its own context, so the tab bar controller you came from keeps its plus button.
 * [CN] 下一个 TabBarController 应该使用的 PlusButton 类：Demo 的两个 PlusButton 中的另一个，即不是 `owner`（其中的 View 或
 *      ViewController）所属 TabBarController 使用的那个。两个都保持注册（各自一个 context），所以返回时原来的 TabBarController 依然有自己的 PlusButton。
 */
+ (Class)alternatePlusButtonClassForOwner:(id)owner;

@end

/*!
 * [EN] A second plus button for the demo. It inherits from `CYLPlusButtonSubclass` and only changes the icon, the title
 *      and the context (`+tabBarContext`). A tab bar controller whose `context` is that context shows this plus button,
 *      next to others that show `CYLPlusButtonSubclass`. See issues #414, #489.
 * [CN] Demo 的第二个 PlusButton。继承自 `CYLPlusButtonSubclass`，只改了图标、标题和 context（`+tabBarContext`）。
 *      `context` 与之相同的 TabBarController 显示这个 PlusButton，同时其他 TabBarController 显示 `CYLPlusButtonSubclass`。见 issue #414、#489。
 */
@interface CYLSecondPlusButtonSubclass : CYLPlusButtonSubclass

@end

/*!
 * [EN] Issue #202 demo: a third plus button, with its own context, that carries an X button as a subview at its top
 *      right. Tapping the X gives it a random color and does not trigger the plus button; tapping the rest of the plus
 *      button works as with `CYLPlusButtonSubclass`. Open it from the "Message" tab: "Push a TabBarController with a new
 *      context". See docs/PlusButton-Subview-Touches.md.
 * [CN] Issue #202 演示：第三个 PlusButton，使用自己的 context，右上角有一个 X 按钮子视图。点击 X 时 X 随机改变颜色，不触发
 *      PlusButton；点击 PlusButton 其他位置与 `CYLPlusButtonSubclass` 相同。从“消息”页的“Push 新 context 的 TabBarController”一行打开。
 *      见 docs/PlusButton-Subview-Touches.md。
 */
@interface CYLCloseSubviewPlusButtonSubclass : CYLPlusButtonSubclass

/*!
 * [EN] The X button, a subview of the plus button.
 * [CN] X 按钮，PlusButton 的子视图。
 */
@property (nonatomic, strong, readonly) UIButton *closeButton;

@end
