//
//  CYLBadgeHosting.swift
//  CYLBadge
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//
//  [EN] Not compiled yet: written statically on Linux (docs/Animated-Item-Badge.md, step 11).
//  [CN] 尚未编译：在 Linux 上静态编写（docs/Animated-Item-Badge.md，第 11 步）。
//

import UIKit

/**
 [EN] A view that hands its badge to one of its subviews (for example an animated item, whose badge sits on a view kept on
      its icon). The badge component sends `cyl_showBadge…`, `cyl_clearBadge` and the other messages to `cylBadgeAnchorView`,
      and writes the accessibility description to `cylBadgeAccessibilityHost`. Requirements only: no default implementations
      and no stored properties here. A new member of this released protocol is always `@objc optional`.
 [CN] 把角标交给某个子视图的视图（例如动效 item，其角标位于一个保持在图标上的视图）。角标组件把 `cyl_showBadge…`、`cyl_clearBadge` 等消息
      发给 `cylBadgeAnchorView`，并把无障碍描述写到 `cylBadgeAccessibilityHost`。这里只有要求：没有默认实现，也没有存储属性。此协议发布后，
      新成员一律使用 `@objc optional`。
 */
@objc public protocol CYLBadgeHosting: NSObjectProtocol {
    /** [EN] The view the badge is added to (for example a view kept on the icon). [CN] 角标所加到的视图（例如保持在图标上的视图）。 */
    @objc var cylBadgeAnchorView: UIView { get }
    /** [EN] The element whose `accessibilityValue` gets the badge description; the host itself when not implemented. [CN] 其 `accessibilityValue` 获得角标描述的元素；未实现时为宿主本身。 */
    @objc optional var cylBadgeAccessibilityHost: NSObject { get }
}
