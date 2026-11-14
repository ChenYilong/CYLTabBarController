//
//  UIViewController+CYLFlatDesignTabBarItem.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] The FlatDesign item of a page, moved from `UIViewController (CYLTabBarControllerExtention)` into the FlatDesign
 *      subspec, so Core builds without FlatDesign (docs/Swift-Migration.md, step 27). Selectors kept.
 * [CN] 页面的扁平样式 item，从 `UIViewController (CYLTabBarControllerExtention)` 移到扁平样式子库中，使 Core 不依赖扁平样式也能编译
 *      （docs/Swift-Migration.md，第 27 步）。selector 不变。
 */
extension UIViewController {

    private static let cyl_flatDesignTabBarItemKey = CYLUtilsKeys.key("cyl_tabBarItem")

    private func cyl_storeFlatDesignTabBarItem(_ item: CYLFlatDesignTabBarItem?) {
        objc_setAssociatedObject(self, Self.cyl_flatDesignTabBarItemKey, item, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(cyl_getViewControllerInsteadOfNavigation(), Self.cyl_flatDesignTabBarItemKey, item,
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /**
     * [EN] The page's FlatDesign item. If not set explicitly, it is created lazily from UIKit's `tabBarItem` (title, image,
     *      selected image) or the page's title; setting nil creates an empty one.
     * [CN] 页面的扁平样式 item。未显式设置时，根据 UIKit 的 `tabBarItem`（标题、图片、选中图片）或页面标题延迟创建；设为 nil 时创建空 item。
     */
    @objc(cyl_tabBarItem)
    public var cyl_tabBarItem: CYLFlatDesignTabBarItem! {
        @objc(cyl_tabBarItem) get {
            if let item = objc_getAssociatedObject(self, Self.cyl_flatDesignTabBarItemKey) as? CYLFlatDesignTabBarItem {
                return item
            }
            let item = cyl_makeFlatDesignTabBarItem()
            cyl_storeFlatDesignTabBarItem(item)
            return item
        }
        @objc(cyl_setTabBarItem:) set {
            let item = newValue ?? CYLFlatDesignTabBarItem(title: title, image: nil)
            // [EN] FIXME: `-[CYLFlatDesignTabBarButton setTabBarItem:]` must run before this, or the item has no button yet.
            // [CN] FIXME：`-[CYLFlatDesignTabBarButton setTabBarItem:]` 需要在此之前调用，否则 item 还没有按钮。
            let contentItem = objc_getAssociatedObject(cyl_getViewControllerInsteadOfNavigation(), Self.cyl_flatDesignTabBarItemKey)
                as? CYLFlatDesignTabBarItem
            let oldItem: CYLFlatDesignTabBarItem = contentItem ?? cyl_tabBarItem
            // [EN] PATCH(aifirx): the item is bound to the page even when the (weak) tab bar controller is gone, else the
            //      page loses its icon and title.
            // [CN] PATCH(aifirx)：即使（弱引用的）TabBarController 已释放，也要把 item 绑定到页面，否则页面会丢失图标和标题。
            if let tabBarController = cylflatdesign_tabBarController as? CYLTabBarController,
               tabBarController.cyl_isFlatDesignStyleTabBar() {
                tabBarController.change(oldItem, to: item)
                if let button = item.tabBarButton {
                    cyl_tabButton = button
                }
            }
            cyl_storeFlatDesignTabBarItem(item)
        }
    }

    /**
     * [EN] FIX: the FlatDesign "More" tab had no icon: the values now come from UIKit's `tabBarItem`, and the system "More"
     *      item, which has no `image` (UIKit draws it), gets "ellipsis". No title (e.g. the slot under the plus button) stays
     *      empty, so VoiceOver reads nothing there.
     * [CN] FIX：扁平样式的「More」Tab 没有图标：现在取自 UIKit 的 `tabBarItem`，没有 `image` 的系统「More」item（由 UIKit 绘制）使用
     *      "ellipsis"。没有标题（例如 PlusButton 下方的位置）时保持为空，VoiceOver 不会读出内容。
     */
    private func cyl_makeFlatDesignTabBarItem() -> CYLFlatDesignTabBarItem {
        let systemItem = tabBarItem
        var image = systemItem?.image
        var selectedImage = systemItem?.selectedImage
        // [EN] Matched by class name, so the lazy `moreNavigationController` getter is never triggered from here.
        // [CN] 按类名匹配，避免在这里触发懒加载的 `moreNavigationController` getter。
        if image == nil, NSStringFromClass(type(of: self)) == "UIMoreNavigationController" {
            image = UIImage(systemName: "ellipsis")
            selectedImage = image
        }
        let placeholder = UIImage.cyl_tabItemPlaceholder()
        let item = CYLFlatDesignTabBarItem(title: systemItem?.title ?? title ?? "", image: image ?? placeholder,
                                           selectedImage: selectedImage ?? image ?? placeholder)
        item.index = UInt(NSNotFound)
        return item
    }
}
