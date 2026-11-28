/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

//CYLBadgeProtocol is a protocol which any Class supported (such UIView, UITabBarItem and UIBarButtonItem) should confirm
//At present, there are same classes support CYLBadgeExtention(UIView, UITabBarItem and UIBarButtonItem). However, there may be more classes to support. Thus, it is necessary to abstract a protocol. 20260812.


#ifndef CYLBadgeProtocol_h
#define CYLBadgeProtocol_h

#import <UIKit/UIKit.h>

#pragma mark -- types definition

/*!
 * [EN] Animation keys: the `forKey:` a badge animation is added to the badge's layer under. They are strings, defined
 *      here with `CYLBadgeAnimationType` (below) because they are two views of the same thing: each type has one key,
 *      listed in `CYLBadgeAnimationKeyForType`. The difference in use:
 *      - the enum picks WHICH animation a badge plays: `[view cyl_showBadgeValue:@"3" animationType:CYLBadgeAnimationTypeShake]`;
 *      - the key IDENTIFIES a running animation on `view.cyl_badge.layer`, to query or stop it:
 *        `[view.cyl_badge.layer animationForKey:CYLBadgeShakeAnimationKey]`,
 *        `[view.cyl_badge.layer removeAnimationForKey:CYLBadgeShakeAnimationKey]`.
 *      Repeating types (Scale, Shake, Bounce, Breathe) can be queried like this; the "Once" types finish by themselves.
 *      `CYLBadgeRotateAnimationKey` belongs to no type: it is reserved for a rotation you add yourself with
 *      `+[CAAnimation cyl_rotation:degree:direction:repeatCount:]`.
 *      To add an animation type: add it to the enum, add its key here, and add it to the three functions below.
 * [CN] 动画 key：角标动画添加到角标 layer 时使用的 `forKey:`。它们是字符串，与 `CYLBadgeAnimationType`（见下）定义在一起，
 *      因为二者描述同一件事：每个类型对应一个 key，见 `CYLBadgeAnimationKeyForType`。用法不同：
 *      - 枚举决定角标播放哪种动画：`[view cyl_showBadgeValue:@"3" animationType:CYLBadgeAnimationTypeShake]`；
 *      - key 用来标识 `view.cyl_badge.layer` 上正在运行的动画，用于查询或停止：
 *        `[view.cyl_badge.layer animationForKey:CYLBadgeShakeAnimationKey]`、
 *        `[view.cyl_badge.layer removeAnimationForKey:CYLBadgeShakeAnimationKey]`。
 *      可以这样查询的是循环类型（Scale、Shake、Bounce、Breathe）；"Once" 类型会自行结束。
 *      `CYLBadgeRotateAnimationKey` 不对应任何类型：留给你用 `+[CAAnimation cyl_rotation:degree:direction:repeatCount:]` 自行添加的旋转动画。
 *      新增动画类型时：在枚举中添加，在这里添加它的 key，并更新下面的三个函数。
 */
#define CYLBadgeBreatheAnimationKey     @"cyl.badge.breathe"
#define CYLBadgeRotateAnimationKey      @"cyl.badge.rotate"
#define CYLBadgeShakeAnimationKey       @"cyl.badge.shake"
#define CYLBadgeScaleAnimationKey       @"cyl.badge.scale"
#define CYLBadgeBounceAnimationKey      @"cyl.badge.bounce"
#define CYLBadgeLeftRightOnceAnimationKey   @"cyl.badge.LeftRightOnce"
#define CYLBadgeRightLeftOnceAnimationKey   @"cyl.badge.RightLeftOnce"
#define CYLBadgeFadeInOnceAnimationKey      @"cyl.badge.FadeInOnce"
#define CYLBadgeRollingOnceAnimationKey     @"cyl.badge.RollingOnce"
#define CYLBadgeScaleOnceAnimationKey     @"cyl.badge.ScaleOnce"

/*!
 * [EN] `CYLBadgeStyle`, `CYLBadgeAnimationType`, `CYLBadgeProtocol` and the helpers `CYLBadgeAnimationKeyForType()`, `CYLBadgeAnimationTypeRepeats()` and `CYLBadgeAllAnimationKeys()` are Swift since docs/Swift-Migration.md step 115 (phase ③, group A of docs/Swift-Migration-Phase3.md): Objective-C
 *      sees it through the generated Swift interface (`CYLSwiftInterface.h`), with the same names.
 * [CN] `CYLBadgeStyle`, `CYLBadgeAnimationType`, `CYLBadgeProtocol` and the helpers `CYLBadgeAnimationKeyForType()`, `CYLBadgeAnimationTypeRepeats()` and `CYLBadgeAllAnimationKeys()` are 自第 115 步（第 ③ 阶段 A 组）起为 Swift：Objective-C 通过生成的 Swift 接口（`CYLSwiftInterface.h`）看到它，名称不变。
 */



#endif
