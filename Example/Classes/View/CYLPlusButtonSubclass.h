//
//  CYLPlusButtonSubclass.h
//  CYLTabBarControllerDemo
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 15/10/24.
//  Copyright (c) 2026年 https://github.com/ChenYilong . All rights reserved.
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
