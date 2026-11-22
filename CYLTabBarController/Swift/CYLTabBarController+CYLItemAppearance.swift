//
//  CYLTabBarController+CYLItemAppearance.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

// [EN] Block 2 of the sections handed over by Mac-CYLTabBarController文件夹 (docs/Swift-Migration.md, step 125): the title offset
//      (issue #475) and image insets (issue #95) of the tabs at run time, the looping Lottie tabs, and the image helper. The
//      property setters `-setTitlePositionAdjustment:` / `-updateImageInsets:` stay in CYLTabBarController.m (they store the
//      ivar) and call `-cyl_applyTitlePositionAdjustmentToItems:` / `-cyl_applyImageInsetsToItems:`. The FlatDesign parts are in
//      CYLFlatDesignTabBar-ObjectiveC/Swift/CYLTabBarController+CYLFlatDesignItemAppearance.swift, reached through
//      `CYLFlatDesignItemAppearance`. The observers of `standardAppearance` stay in the `.m` with the KVO context they share.
// [CN] 另一会话移交的第 2 块（第 125 步）：运行时 Tab 的标题偏移（issue #475）与图片内边距（issue #95）、循环播放的 Lottie Tab 以及图片辅助方法。
//      属性 setter `-setTitlePositionAdjustment:` / `-updateImageInsets:` 留在 CYLTabBarController.m（它们保存实例变量）并调用这里的方法。扁平样式部分
//      位于 CYLFlatDesignTabBar-ObjectiveC/Swift/CYLTabBarController+CYLFlatDesignItemAppearance.swift，通过 `CYLFlatDesignItemAppearance` 调用。
//      `standardAppearance` 的观察留在 `.m` 中，与其共用的 KVO context 在一起。

/// [EN] The title offset a tab asked for itself (issue #475). [CN] Tab 自身设置的标题偏移（issue #475）。
private let cylTitlePositionAdjustmentItemOffsetKey = CYLUtilsKeys.key("cyl_titlePositionAdjustmentItemOffset")
/// [EN] The image insets a tab asked for itself (issue #95). [CN] Tab 自身设置的图片内边距（issue #95）。
private let cylImageInsetsItemKey = CYLUtilsKeys.key("cyl_imageInsetsItem")
/// [EN] What the automatic adjustment of image-only tabs wrote into an item (the `.m` macro of the same selector name).
/// [CN] 纯图标 Tab 自动调整写入 item 的记录（与 `.m` 中同一 selector 名称的宏相同）。
private let cylImageOnlyTabAdjustmentKey = CYLUtilsKeys.key("cyl_imageOnlyTabAdjustment")

/**
 [EN] Remembers the title offset a tab asked for itself, so the controller's offset does not override it (nil for zero).
      Called by CYLTabBarController.m by this C name.
 [CN] 记住 Tab 自身设置的标题偏移，使控制器的偏移不会覆盖它（为零时清除）。CYLTabBarController.m 以此 C 名称调用。
 */
@_cdecl("CYLRememberItemTitlePositionAdjustment")
public func cylRememberItemTitlePositionAdjustment(_ item: AnyObject?, _ offset: UIOffset) {
    guard let item else { return }
    let value: NSValue? = offset == .zero ? nil : NSValue(uiOffset: offset)
    objc_setAssociatedObject(item, cylTitlePositionAdjustmentItemOffsetKey, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
}

/**
 [EN] Remembers the image insets a tab asked for itself (nil for zero). Called by CYLTabBarController.m by this C name.
 [CN] 记住 Tab 自身设置的图片内边距（为零时清除）。CYLTabBarController.m 以此 C 名称调用。
 */
@_cdecl("CYLRememberItemImageInsets")
public func cylRememberItemImageInsets(_ item: AnyObject?, _ insets: UIEdgeInsets) {
    guard let item else { return }
    let value: NSValue? = insets == .zero ? nil : NSValue(uiEdgeInsets: insets)
    objc_setAssociatedObject(item, cylImageInsetsItemKey, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
}

/// [EN] The title offset of a tab: its own, else the controller's. [CN] Tab 的标题偏移：自身的，否则为控制器的。
func cylTitlePositionAdjustment(forItem item: AnyObject?, controllerOffset: UIOffset) -> UIOffset {
    guard let item, let value = objc_getAssociatedObject(item, cylTitlePositionAdjustmentItemOffsetKey) as? NSValue else {
        return controllerOffset
    }
    return value.uiOffsetValue
}

/// [EN] The image insets of a tab: its own, else the controller's. [CN] Tab 的图片内边距：自身的，否则为控制器的。
func cylImageInsets(forItem item: AnyObject?, controllerInsets: UIEdgeInsets) -> UIEdgeInsets {
    guard let item, let value = objc_getAssociatedObject(item, cylImageInsetsItemKey) as? NSValue else {
        return controllerInsets
    }
    return value.uiEdgeInsetsValue
}

/**
 [EN] The FlatDesign parts of block 2, implemented by CYLTabBarController+CYLFlatDesignItemAppearance.swift in the FlatDesign
      subspec (optional, so the core builds without it).
 [CN] 第 2 块的扁平样式部分，由扁平样式子库中的 CYLTabBarController+CYLFlatDesignItemAppearance.swift 实现（可选，核心在没有它时也能构建）。
 */
@objc protocol CYLFlatDesignItemAppearance {
    @objc(cyl_flatDesignApplyTitlePositionAdjustment:) optional func cylFlatDesignApplyTitlePositionAdjustment(_ offset: UIOffset) -> Bool
    @objc(cyl_flatDesignApplyImageInsets:) optional func cylFlatDesignApplyImageInsets(_ insets: UIEdgeInsets) -> Bool
}

extension CYLTabBarController {

    private var cylFlatDesignItemAppearance: CYLFlatDesignItemAppearance {
        unsafeBitCast(self, to: CYLFlatDesignItemAppearance.self)
    }

    /**
     [EN] Applies the controller's title offset to every tab that did not ask for its own (issue #475); FlatDesign items in
          the FlatDesign subspec. Called by `-setTitlePositionAdjustment:`.
     [CN] 把控制器的标题偏移应用到没有自行设置的每个 Tab（issue #475）；扁平样式的 item 由扁平样式子库处理。由 `-setTitlePositionAdjustment:` 调用。
     */
    @objc(cyl_applyTitlePositionAdjustmentToItems:)
    func cylApplyTitlePositionAdjustmentToItems(_ offset: UIOffset) {
        if tabBarStyleType == .flatDesign {
            _ = cylFlatDesignItemAppearance.cylFlatDesignApplyTitlePositionAdjustment?(offset)
            return
        }
        for viewController in viewControllers ?? [] {
            let item = viewController.tabBarItem
            cylApplyTitlePositionAdjustment(cylTitlePositionAdjustment(forItem: item, controllerOffset: offset), to: item)
        }
    }

    /**
     [EN] Applies the controller's image insets to every tab that did not ask for its own (issue #95), clearing what the
          image-only adjustment wrote, then lets that adjustment run again for zero insets; FlatDesign items in the FlatDesign
          subspec. Called by `-updateImageInsets:`.
     [CN] 把控制器的图片内边距应用到没有自行设置的每个 Tab（issue #95），清除纯图标调整写入的记录，内边距为零时让该调整重新执行；扁平样式的 item
          由扁平样式子库处理。由 `-updateImageInsets:` 调用。
     */
    @objc(cyl_applyImageInsetsToItems:)
    func cylApplyImageInsetsToItems(_ insets: UIEdgeInsets) {
        if tabBarStyleType == .flatDesign {
            _ = cylFlatDesignItemAppearance.cylFlatDesignApplyImageInsets?(insets)
            return
        }
        for viewController in viewControllers ?? [] {
            guard let item = viewController.tabBarItem,
                  objc_getAssociatedObject(item, cylImageInsetsItemKey) == nil else { continue }
            if var record = objc_getAssociatedObject(item, cylImageOnlyTabAdjustmentKey) as? [String: NSValue] {
                record.removeValue(forKey: "insets")
                record.removeValue(forKey: "appliedInsets")
                objc_setAssociatedObject(item, cylImageOnlyTabAdjustmentKey, record.isEmpty ? nil : record as NSDictionary,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            if item.imageInsets != insets {
                item.imageInsets = insets
            }
        }
        if insets == .zero, let tabBar = cylPrivate.cylStoredTabBar() as? CYLTabBar, tabBar.tabImageViewDefaultOffset != 0 {
            offsetTabBarTabImageView(toFit: tabBar.tabImageViewDefaultOffset)
        }
    }

    /**
     [EN] Tabs with `CYLTabBarLottieLoopsWhenUnselected`: their Lottie views loop while unselected and pause while selected,
          in both Liquid Glass layers. Without Lottie in the build there is no Lottie view, so nothing happens.
     [CN] 带 `CYLTabBarLottieLoopsWhenUnselected` 的 Tab：未选中时 Lottie 视图循环播放，选中时暂停，液态玻璃的两个图层都如此。构建中没有 Lottie 时
          不存在 Lottie 视图，因此不做任何事。
     */
    @objc(cyl_updateLoopingLottieViews)
    func cylUpdateLoopingLottieViews() {
        let viewControllers = self.viewControllers ?? []
        for (index, viewController) in viewControllers.enumerated() {
            guard let attributes = tabBarItemAttributes(at: UInt(index)),
                  (attributes["CYLTabBarLottieLoopsWhenUnselected"] as? NSNumber)?.boolValue == true,
                  let control = viewController.tabBarItem.cyl_tabButton ?? viewController.cyl_tabButton else { continue }
            var controls = [control]
            if CYLConstants.isLiquidGlassActive(), let selectedLayer = control.cylPlatterSelected(), selectedLayer !== control {
                controls.append(selectedLayer)
            }
            let selected = viewController === selectedViewController
            for each in controls {
                guard let lottieView = each.cylTabBarItemAnimationView() else { continue }
                if selected {
                    cylCallIfImplemented(lottieView, "pause")
                    continue
                }
                if lottieView.responds(to: NSSelectorFromString("setLoopAnimationCount:")) {
                    lottieView.setValue(-1, forKey: "loopAnimationCount")
                } else if lottieView.responds(to: NSSelectorFromString("setLoopAnimation:")) {
                    lottieView.setValue(true, forKey: "loopAnimation")
                }
                let playing = lottieView.responds(to: NSSelectorFromString("isAnimationPlaying"))
                    && (lottieView.value(forKey: "isAnimationPlaying") as? Bool) == true
                if !playing {
                    cylCallIfImplemented(lottieView, "play")
                }
            }
        }
    }

    private func cylCallIfImplemented(_ object: NSObject, _ selectorName: String) {
        let selector = NSSelectorFromString(selectorName)
        guard object.responds(to: selector) else { return }
        typealias Call = @convention(c) (AnyObject, Selector) -> Void
        unsafeBitCast(object.method(for: selector), to: Call.self)(object, selector)
    }

    /// [EN] An image from a name, a path, a URL or an image (`+[UIImage cyl_getImageFromImageInfo:]`). [CN] 由名称、路径、URL 或图片得到图片。
    @objc(getImageFromImageInfo:)
    func cylGetImage(fromImageInfo imageInfo: Any?) -> UIImage? {
        guard let imageInfo else { return nil }
        return UIImage.cylGetImage(fromImageInfo: imageInfo)
    }
}
