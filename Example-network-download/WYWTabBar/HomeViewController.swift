//
//  HomeViewController.swift
//  WYWTabBar
//
//  Ported from Objective-C on 2026/11/11: the examples are Swift only.
//

import UIKit
import CYLTabBarController

final class HomeViewController: UIViewController {

    private lazy var styleControl: UISegmentedControl = {
        let control = UISegmentedControl(items: [cylDemoLocalizedString("LiquidGlass"), cylDemoLocalizedString("FlatDesign")])
        control.addTarget(self, action: #selector(styleChanged(_:)), for: .valueChanged)
        return control
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        // [EN] The network icons and the title update in both styles.
        // [CN] 网络图标与标题更新在两种样式下都可用。
        navigationItem.titleView = styleControl
        updateSelectedSegment()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSelectedSegment()
    }

    private func updateSelectedSegment() {
        let isFlatDesign = cyl_owningTabBarController()?.tabBarStyleType == .flatDesign
        styleControl.selectedSegmentIndex = isFlatDesign ? 1 : 0
    }

    @objc private func styleChanged(_ control: UISegmentedControl) {
        let style: CYLTabBarStyleType = (control.selectedSegmentIndex == 1) ? .flatDesign : .liquidGlass
        (view.window?.windowScene?.delegate as? SceneDelegate)?.showTabBarController(style: style)
    }
}
