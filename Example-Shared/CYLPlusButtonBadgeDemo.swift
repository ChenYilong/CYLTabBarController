//
//  CYLPlusButtonBadgeDemo.swift
//  CYLTabBarController demos
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import CYLTabBarController
import UIKit

/*!
 * #535 demo, shared by every Swift demo (Example-Swift, -02, -03, -04, SwiftManager, SwiftManager-FlatDesign).
 * [EN] A badge on the plus button, like the tabs' badges: a bouncing number that goes up by 1 on each tap. The badge
 *      API comes from the CYLBadgeView subspec and `CYLUtils` from the CYLUtils subspec; Core depends on both, so every
 *      demo builds with its Podfile / package unchanged.
 *      A tab bar controller calls `demoShowPlusButtonBadgeAfterLayout()` from `viewDidAppear(_:)` and
 *      `demoPlusButtonDidTap(_:)` from `tabBarController(_:didSelect:)`.
 * [CN] PlusButton 的角标，与 Tab 角标效果一致：带弹跳动画的数字，每次点击加 1。角标 API 来自 CYLBadgeView subspec，`CYLUtils`
 *      来自 CYLUtils subspec；Core 依赖二者，因此所有 Demo 无需修改 Podfile / Package 即可编译。
 *      TabBarController 在 `viewDidAppear(_:)` 中调用 `demoShowPlusButtonBadgeAfterLayout()`，在
 *      `tabBarController(_:didSelect:)` 中调用 `demoPlusButtonDidTap(_:)`。
 */
extension CYLTabBarController {

    /// This tab bar controller's plus button, found by its #408 identifier. 通过 #408 的标识找到的 PlusButton。
    var demoPlusButton: UIControl? {
        return cyl_tabBarItemIdentifiers.lazy
            .compactMap { self.cyl_control(withTabBarItemIdentifier: $0) }
            .first { $0.cyl_isPlusButton() }
    }

    /// Shows the badge (1) once the tab bar is laid out, delayed like the ObjC demo's tab badges.
    /// TabBar 布局完成后显示角标（1），与 ObjC Demo 的 Tab 角标一样延迟显示。
    func demoShowPlusButtonBadgeAfterLayout() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.demoUpdatePlusButtonBadge(addingOne: false)
        }
    }

    /// A tap on the plus button adds 1 to its badge. 点击 PlusButton 时角标数字加 1。
    func demoPlusButtonDidTap(_ control: UIControl) {
        guard control.cyl_isPlusButton() else { return }
        demoUpdatePlusButtonBadge(addingOne: true)
    }

    /// The count is kept in the plus button's `tag` (0: no badge yet). 数字保存在 PlusButton 的 `tag` 中（0 表示尚未显示）。
    private func demoUpdatePlusButtonBadge(addingOne: Bool) {
        guard let plusButton = demoPlusButton else { return }
        if !addingOne && plusButton.tag > 0 {
            return
        }
        plusButton.tag = max(plusButton.tag, 0) + 1
        plusButton.cyl_showBadgeValue("\(plusButton.tag)", animationType: .bounce)
        NSLog("[#535] plus button badge %ld (Liquid Glass: %@, from CYLUtils)", plusButton.tag, CYLUtils.isLiquidGlassActive() ? "YES" : "NO")
    }
}

/// #535 demo: a plus button for the demos that have none (Swift-04, SwiftManager-FlatDesign), to show its badge. It has
/// no child view controller: a tap only changes the badge. Register it before creating the tab bar controller.
/// #535 演示：供原本没有 PlusButton 的 Demo（Swift-04、SwiftManager-FlatDesign）使用，用于演示其角标。没有子控制器，点击只改变角标。
/// 需在创建 TabBarController 之前注册。
final class DemoPlusButton: CYLPlusButton, CYLPlusButtonSubclassing {
    static func plusButton() -> Any {
        let configuration = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
        let image = UIImage(systemName: "plus.circle.fill", withConfiguration: configuration) ?? UIImage()
        return DemoPlusButton.cyl_plusButton(with: image, title: CYLLocalizedString("发布"),
                                             selectedTitle: nil, selectedTitleColor: nil)
    }

    // #408: the plus button's identifier. PlusButton 的标识。
    static func tabBarItemIdentifier() -> String {
        return "plus"
    }
}
