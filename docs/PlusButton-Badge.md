# [CN]PlusButton 角标：每次点击都会变化
# [EN]PlusButton badge: changes on every tap

| 中文 | English |
|:---|:---|
| PlusButton（中间凸起按钮）可以像其他 Tab 一样显示角标，并在 `tabBarController:didSelectControl:` 中随每次点击更新。本文介绍用法，以及本次修复的问题：点击 PlusButton 后角标不变化。 | The plus button (the raised center button) can show a badge like the other tabs and update it on every tap in `tabBarController:didSelectControl:`. This page shows how, and the bug fixed here: the badge did not change when the plus button was tapped. |

## [CN]问题
## [EN]The problem

| 中文 | English |
|:---|:---|
| 实现了 `+plusChildViewController` 的 PlusButton 有**两个图层**：PlusButton 本身，以及它下方 `plusChildViewController` 的系统 Tab 按钮。修复前点击 PlusButton 时： | A plus button that implements `+plusChildViewController` has **two layers**: the plus button itself, and the system tab button of `plusChildViewController` under it. Before the fix, a tap on the plus button: |
| 1. 代理可能收到下方的系统 Tab 按钮而不是 PlusButton，`-cyl_isPlusButton` 返回 NO，角标代码没有执行； | 1. could reach the delegate as that system tab button instead of the plus button, so `-cyl_isPlusButton` was NO and the badge code did not run; |
| 2. 子控制器已选中时，该系统 Tab 按钮被禁用，回调直接被跳过； | 2. was skipped when the child view controller was already selected, because that system tab button is disabled then; |
| 3. 液态玻璃（iOS 26+）下一次点击会回调两次（`selectedViewController` 的 setter 一次，`-setSelectedIndex:` 一次），每次回调切换一次的角标被切换两次，看起来没有变化。 | 3. was reported twice on Liquid Glass (iOS 26+): once by the `selectedViewController` setter and once by `-setSelectedIndex:`. A badge that toggles on each callback flipped twice and looked unchanged. |

## [CN]修复后的行为
## [EN]Behavior after the fix

| 中文 | English |
|:---|:---|
| **总是上报 PlusButton**：点击 PlusButton 或其下方的子控制器 Tab 按钮，`tabBarController:didSelectControl:` 收到的都是 PlusButton 本身，包括再次点击已选中的 PlusButton。 | **Always the plus button**: a tap on the plus button, or on the child view controller's tab button under it, reaches `tabBarController:didSelectControl:` as the plus button itself, including a repeat tap on a selected plus button. |
| **每次点击只回调一次**：同一 runloop 内对带子控制器的 PlusButton 的多次上报合并为一次。 | **One callback per tap**: reports of a plus button with a child view controller within one run loop turn are merged into one. |
| **代码隔离**：以上处理仅在 `hasPlusButton` 时生效；涉及子控制器（第二个图层）的部分仅在 `hasPlusChildViewController` 时生效。没有 PlusButton 的 TabBar 与普通 Tab 按钮行为完全不变。 | **Isolated by guards**: all of this runs only when `hasPlusButton` is YES, and the parts about the child view controller (the second layer) only when `hasPlusChildViewController` is YES. Tab bars without a plus button, and ordinary tab buttons, behave exactly as before. |
| **可以关闭**：`plusButton.cyl_userInteractionDisabled = YES` 仍然会让 PlusButton 不触发该回调。 | **Opt-out still works**: `plusButton.cyl_userInteractionDisabled = YES` still keeps the plus button out of this callback. |
| 适用于所有非扁平样式（默认、系统、液态玻璃）。扁平样式（FlatDesign）本来就每次点击只上报一次，行为不变。 | Applies to every non-flat style (default, system, Liquid Glass). The flat design style already reported each tap once and is unchanged. |

## [CN]用法：在 didSelectControl 中更新角标
## [EN]Usage: update the badge in didSelectControl

| 中文 | English |
|:---|:---|
| 与其他 Tab 一样，在代理方法中更新角标。判断时用 `cyl_isPlusControl`（包括 PlusButton 和其下方的子控制器 Tab 按钮）。有子控制器时**两个图层都要更新**：PlusButton 本身，以及 `plusChildViewController`（与其他 Tab 一样，在控制器上设置）。 | Update the badge in the delegate method, as for the other tabs. Check with `cyl_isPlusControl` (the plus button and the child view controller's tab button under it). With a child view controller, **update both layers**: the plus button, and `plusChildViewController` (set on the view controller, like the other tabs). |

### Swift

| 中文 | English |
|:---|:---|
| 摘自 [`Example-Shared/CYLPlusButtonBadgeDemo.swift`](../Example-Shared/CYLPlusButtonBadgeDemo.swift)（所有 Swift Demo 共用）： | From [`Example-Shared/CYLPlusButtonBadgeDemo.swift`](../Example-Shared/CYLPlusButtonBadgeDemo.swift) (shared by every Swift demo): |

```swift
class MainTabBarController: CYLTabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self   // [CN] 没有 delegate 就不会回调 didSelectControl  [EN] no delegate, no didSelectControl
    }

    override func tabBarController(_ tabBarController: CYLTabBarController, didSelect control: UIControl) {
        // [CN] 守卫：仅在有 PlusButton 时处理  [EN] Guard: plus button code only with a plus button
        guard hasPlusButton(), control.cyl_isPlusControl() else { return }
        guard let plusButton = CYLPlusButton.plusButton(forOwner: self) else { return }

        plusButton.tag += 1                                   // [CN] 每次点击加 1  [EN] +1 per tap
        let badgeValue = "\(plusButton.tag)"

        // [CN] 图层 1：PlusButton  [EN] Layer 1: the plus button
        plusButton.cyl_showBadgeValue(badgeValue, animationType: .bounce)
        // [CN] 图层 2：仅在有 PlusButton 子控制器时存在
        // [EN] Layer 2: only exists with a plus child view controller
        if hasPlusChildViewController() {
            CYLPlusButton.plusChildViewController(forOwner: self)?.cyl_showBadgeValue(badgeValue, animationType: .bounce)
        }
    }
}
```

### Objective-C

| 中文 | English |
|:---|:---|
| 摘自 [`Example/MainTabBarController.m`](../Example/MainTabBarController.m)： | From [`Example/MainTabBarController.m`](../Example/MainTabBarController.m): |

```objc
- (void)tabBarController:(CYLTabBarController *)tabBarController didSelectControl:(UIControl *)control {
    // Guard: plus button code only with a plus button. 仅在有 PlusButton 时处理。
    BOOL isPlusControl = [tabBarController hasPlusButton] && [control cyl_isPlusControl];
    if (isPlusControl) {
        [tabBarController cyl_demo_plusButtonDidTap];           // count + 1, then both layers
    }
    if ([control cyl_isTabButton] && !isPlusControl) {
        // [CN] 其他 Tab：切换红点  [EN] other tabs: toggle the red dot
        if ([control cyl_isShowBadge]) {
            [tabBarController.selectedViewController cyl_clearBadge];
        } else {
            [tabBarController.selectedViewController cyl_showBadge];
        }
    }
}

// CYLTabBarController (CYLPlusButtonBadgeDemo)
- (void)cyl_demo_showPlusButtonBadge {
    if (![self hasPlusButton]) { return; }                      // guard
    UIButton *plusButton = [CYLPlusButton plusButtonForOwner:self];
    NSString *badgeValue = [NSString stringWithFormat:@"%@", @(count)];
    [plusButton cyl_showBadgeValue:badgeValue animationType:CYLBadgeAnimationTypeBounce];      // layer 1
    if ([self hasPlusChildViewController]) {                     // guard: layer 2 only with a child view controller
        UIViewController *plusChildViewController = [CYLPlusButton plusChildViewControllerForOwner:self];
        [plusChildViewController cyl_showBadgeValue:badgeValue animationType:CYLBadgeAnimationTypeBounce]; // layer 2
    }
}
```

## [CN]相关 API
## [EN]Related API

| API | 中文 | English |
|:---|:---|:---|
| `-tabBarController:didSelectControl:` / `tabBarController(_:didSelect:)` | 每次点击 Tab 按钮或 PlusButton 回调一次 | Called once per tap on a tab button or the plus button |
| `-[UIControl cyl_isPlusControl]` | PlusButton 或其子控制器的系统 Tab 按钮 | The plus button or its child view controller's system tab button |
| `-[UIView cyl_isPlusButton]` | 仅 PlusButton 本身 | The plus button only |
| `-[CYLTabBarController hasPlusButton]` | 是否有 PlusButton；处理 PlusButton 前先判断 | Whether there is a plus button; check before any plus button code |
| `-[CYLTabBarController hasPlusChildViewController]`（新公开 / newly public） | PlusButton 是否有子控制器（第二个图层）；处理子控制器前先判断 | Whether the plus button has a child view controller (the second layer); check before touching it |
| `+[CYLPlusButton plusButtonForOwner:]` | 某个 TabBarController 的 PlusButton | A tab bar controller's plus button |
| `+[CYLPlusButton plusChildViewControllerForOwner:]` | 某个 TabBarController 的 PlusButton 子控制器 | A tab bar controller's plus child view controller |
| `-cyl_showBadgeValue:animationType:` | 显示角标（`@""` 为红点） | Shows a badge (`@""` for a red dot) |
| `cyl_userInteractionDisabled` | 设为 YES 时该控件不触发 didSelectControl | YES keeps the control out of didSelectControl |

## [CN]测试与截图
## [EN]Testing and screenshots

| 中文 | English |
|:---|:---|
| 本次修改在 Linux 环境中完成，无法运行 Xcode 和 iOS 模拟器，因此**没有截图**，也没有在设备上验证。请在 iOS 26（液态玻璃）和 iOS 18 / UI 兼容模式（经典样式）上分别运行 `Example` 与 `Example-Swift`，连续点击 PlusButton，确认角标数字每次加 1，且 `didSelectControl` 每次点击只打印一次。验证后的截图请放在 `docs/assets/` 中，并用 `![](assets/文件名.png)` 引用。 | This change was made on Linux, where Xcode and the iOS simulator cannot run, so there are **no screenshots** and it was not verified on a device. Run `Example` and `Example-Swift` on iOS 26 (Liquid Glass) and on iOS 18 / UI compatibility mode (classic style), tap the plus button several times, and check that the badge number goes up by 1 each time and `didSelectControl` logs once per tap. Put screenshots from that check in `docs/assets/` and reference them as `![](assets/file-name.png)`. |
