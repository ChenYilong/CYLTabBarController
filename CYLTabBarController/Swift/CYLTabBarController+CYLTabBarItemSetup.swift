//
//  CYLTabBarController+CYLTabBarItemSetup.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

#if canImport(CYLUtilsKit)
import CYLUtilsKit
#endif
#if canImport(CYLBadge)
import CYLBadge
#endif
/**
 * [EN] What a tab item's attributes give: read once by `-cyl_tabBarItemSetupForViewController:idx:` for every tab bar style.
 *      `idx` is the index to add the view controller at (one less after the plus child view controller, except in Liquid Glass
 *      with a plus button, issue #563). Translated from Objective-C (docs/Swift-Migration.md, step 76); declared for
 *      CYLTabBarController.m in `CYLTabBarController+CYLPrivate.h`, under the same Objective-C name.
 * [CN] Tab item 属性解析的结果：由 `-cyl_tabBarItemSetupForViewController:idx:` 为所有 TabBar 样式统一读取一次。`idx` 为添加该 ViewController 的索引
 *      （PlusButton 子控制器之后减一，液态玻璃且有 PlusButton 时除外，issue #563）。已从 Objective-C 翻译（第 76 步）；在 `CYLTabBarController+CYLPrivate.h`
 *      中以相同的 Objective-C 名称为 CYLTabBarController.m 声明。
 */
@objc(CYLTabBarItemSetup)
final class CYLTabBarItemSetup: NSObject {
    @objc var idx: UInt = 0
    @objc var title: String?
    @objc var normalImageInfo: Any?
    @objc var selectedImageInfo: Any?
    @objc var titlePositionAdjustment: UIOffset = .zero
    @objc var imagePositionAdjustment: UIOffset = .zero
    @objc var imageInsets: UIEdgeInsets = .zero
    @objc var animationURL: URL?
    @objc var animationFilePath: String?
    @objc var animationSizeValue: NSValue?
}

/**
 * [EN] The FlatDesign side of adding a tab, implemented in the FlatDesign subspec (CYLTabBarController+CYLFlatDesign.swift).
 *      Optional: without that subspec nothing answers.
 * [CN] 添加 Tab 的扁平样式部分，由扁平样式子库实现。可选：没有该子库时无人响应。
 */
@objc protocol CYLFlatDesignChildSetup {
    @objc(setupChildViewController:idx:) optional func cylFlatDesignSetupChildViewController(_ viewController: UIViewController, idx: UInt)
}

extension CYLTabBarController {

    /**
     * [EN] Whether the tab bar plays `URL`: a local file that exists, with an animator for its type (`-addAnimationWithURL:…` of
     *      the engine). A remote URL, a missing file, or no engine in the build: the tab's image, or the placeholder.
     * [CN] TabBar 能否播放 `URL`：存在的本地文件，且有其类型的 animator（引擎的 `-addAnimationWithURL:…`）。远程 URL、不存在的文件或构建中没有引擎时：
     *      显示 Tab 的图片，没有时显示占位图。
     */
    private static func cylTabBarAnimationCanPlay(_ url: URL) -> Bool {
        guard url.isFileURL, !url.path.isEmpty, FileManager.default.fileExists(atPath: url.path),
              let registry = NSClassFromString("CYLTabBarItemAnimatorRegistry") as AnyObject? else {
            return false
        }
        let selector = NSSelectorFromString("animatorForURL:")
        guard registry.responds(to: selector) else {
            return false
        }
        return registry.perform(selector, with: url)?.takeUnretainedValue() != nil
    }

    /**
     * [EN] Reads the attributes of the tab at `idx` (FIX: issue #604 — one place, for every style): title, images (with dark
     *      variants, #620, and the rendering mode, #787), animation (the component's placeholder when it cannot play), its
     *      identifier (#408), selected title (#433), the navigation title of a following page, and the per-tab offsets. The plus
     *      child view controller (and a placeholder without a slot entry) reads nothing (#563).
     * [CN] 读取第 `idx` 个 Tab 的属性（FIX: issue #604——所有样式共用一处）：标题、图片（含深色图片 #620 与渲染方式 #787）、动画（无法播放时使用组件的占位图）、
     *      标识（#408）、选中标题（#433）、跟随页面的导航标题以及单个 Tab 的偏移。PlusButton 子控制器（以及没有 slot 项的占位控制器）不读取（#563）。
     */
    @objc(cyl_tabBarItemSetupForViewController:idx:)
    func cylTabBarItemSetup(for viewController: UIViewController, idx: UInt) -> CYLTabBarItemSetup {
        let setup = CYLTabBarItemSetup()
        var idx = idx
        let includesPlusSlot = cylPrivate.cylTabBarItemsAttributesIncludePlusSlot()
        // [EN] FIX: placeholder count mismatch — a placeholder reads its own (marked) entry only when the attributes have one;
        //      otherwise it is skipped like the plus child view controller, so later tabs keep their own entries.
        // [CN] FIX：占位导致的数量不匹配——只有属性中有 slot 项时占位控制器才读取它；否则与 PlusButton 子控制器一样跳过。
        let readsAttributes = viewController !== cylPrivate.cylContextPlusChildViewController()
            && (!viewController.cyl_isPlaceholder || includesPlusSlot)
        if readsAttributes {
            let stored = tabBarItemsAttributes
            if Int(idx) < stored.count, let attributes = stored[Int(idx)] as? [String: Any] {
                // FIX: issue #437
                setup.title = attributes[cylTabBarItemTitle] as? String ?? ""
                // [EN] #620: an optional dark image per state, combined here so every style gets it.
                // [CN] #620：每种状态可选的深色图片，在这里合成，所有样式都能使用。
                let normalInfo = UIImage.cylImage(withImageInfo: attributes[cylTabBarItemImage], darkImageInfo: attributes[cylTabBarItemDarkImage])
                let selectedInfo = UIImage.cylImage(withImageInfo: attributes[cylTabBarItemSelectedImage],
                                                     darkImageInfo: attributes[cylTabBarItemSelectedDarkImage])
                let infos = Self.cylImageInfos(of: attributes, applyingIconRenderingModeTo: normalInfo, selectedImageInfo: selectedInfo)
                setup.normalImageInfo = infos[0] is NSNull ? nil : infos[0]
                setup.selectedImageInfo = infos[1] is NSNull ? nil : infos[1]
                var animationFilePath: NSString?
                setup.animationURL = cylTabBarItemAnimationURLFromAttributesEntryPoint(attributes as NSDictionary, &animationFilePath) as URL?
                setup.animationFilePath = animationFilePath as String?
                // [EN] Only an animation file that cannot play (no engine, no library, or a type whose engine is not in the build):
                //      the component's placeholder instead of an empty icon; a static image stays the fallback.
                // [CN] 只有无法播放的动画文件（没有引擎或动画库，或其类型的引擎未参与构建）：使用组件的占位图而不是空图标；有静态图片时仍以该图片兜底。
                if let unplayableURL = setup.animationURL ?? cylTabBarItemAnimationURLOfAnyType(attributes as NSDictionary) as URL?,
                   !Self.cylTabBarAnimationCanPlay(unplayableURL) {
                    // [EN] Debug builds: which pod to add. [CN] debug 构建：提示需要加入的 pod。
                    CYLAnimationWarnMissingEngine(attributes, unplayableURL)
                    if setup.normalImageInfo == nil && setup.selectedImageInfo == nil {
                        setup.normalImageInfo = CYLAnimatedItemView.defaultPlaceholderImage
                    }
                }
                setup.animationSizeValue = cylTabBarItemAttributesAnimationValueEntryPoint(attributes as NSDictionary,
                                                                                           cylTabBarAnimationSize as NSString) as? NSValue
                // FIX: issue #408 — the tab's identifier. [CN] Tab 的标识。
                viewController.cyl_tabBarItemIdentifier = attributes[cylTabBarItemIdentifier] as? String
                // FIX: issue #433 — the title shown while the tab is selected. [CN] 选中时显示的标题。
                cylRememberTabBarItemSelectedTitle(viewController, attributes as NSDictionary, setup.title as NSString?)
                // [EN] A page that follows its tab title gets it as its navigation bar title now. [CN] 跟随 Tab 标题的页面现在获得导航栏标题。
                Self.cylApplyNavigationTitle(ofFollowingPage: viewController, title: setup.title)
                setup.titlePositionAdjustment = (attributes[cylTabBarItemTitlePositionAdjustment] as? NSValue)?.uiOffsetValue ?? .zero
                setup.imagePositionAdjustment = (attributes[cylTabBarItemImagePositionAdjustment] as? NSValue)?.uiOffsetValue ?? .zero
                setup.imageInsets = (attributes[cylTabBarItemImageInsets] as? NSValue)?.uiEdgeInsetsValue ?? .zero
            }
        } else {
            // FIX: issue #563
            // [EN] The plus child view controller gets an empty title, or the other tabs lost their titles once the first tab was
            //      the plus button. Its page that follows its tab title gets the plus button's title. The index is guarded by
            //      the data (`-cyl_tabBarItemsAttributesIncludePlusSlot`), not by the style.
            // [CN] PlusButton 子控制器的标题设为空字符串，否则把第一个 Tab 设为 PlusButton 后其他 Tab 不显示标题。跟随 Tab 标题的页面获得 PlusButton 的标题。
            //      索引按数据判断（`-cyl_tabBarItemsAttributesIncludePlusSlot`），而不是按样式。
            setup.title = ""
            Self.cylApplyNavigationTitle(ofFollowingPage: viewController, title: CYLPlusButton.cylPlusButton(forOwner: self)?.cyl_title())
            if !includesPlusSlot {
                idx = idx &- 1
            }
        }
        setup.idx = idx
        return setup
    }
}
