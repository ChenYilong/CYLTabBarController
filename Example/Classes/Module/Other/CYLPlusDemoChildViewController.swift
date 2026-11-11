//
//  CYLPlusDemoChildViewController.swift
//  CYLTabBarController
//
//  Ported from Objective-C on 2026/11/11: the examples are Swift only.
//

import UIKit
import CYLTabBarController

/// [EN] The plus button's page in the demo. `@objc(...)` keeps the Objective-C name while the rest of the demo is ported.
/// [CN] 示例中 PlusButton 的页面。`@objc(...)` 在其余示例移植期间保留 Objective-C 类名。
@objc(CYLPlusDemoChildViewController)
final class CYLPlusDemoChildViewController: UIViewController {

    deinit {
        NSLog(cylDemoLocalizedString("🔴类名与方法名：%@（在第%@行）, 描述：%@"), "\(type(of: self)).deinit", "\(#line)", "")
    }
}
