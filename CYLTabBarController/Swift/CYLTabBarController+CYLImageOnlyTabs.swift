//
//  CYLTabBarController+CYLImageOnlyTabs.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] The associated object keys shared with CYLTabBarController.m, which reads and writes them too (selector-based
 *      keys, the same pointer on both sides).
 * [CN] 与 CYLTabBarController.m 共用的关联对象 key（它也会读写；基于 selector 的 key，两边是同一个指针）。
 */
private enum CYLImageOnlyTabKeys {
    /// [EN] What the adjustment wrote into an item. [CN] 自动调整写入 item 的记录。
    static let adjustment = CYLUtilsKeys.key("cyl_imageOnlyTabAdjustment")
    /// [EN] The title offset a tab asked for itself. [CN] Tab 自身设置的标题偏移。
    static let itemTitleOffset = CYLUtilsKeys.key("cyl_titlePositionAdjustmentItemOffset")
    /// [EN] The record's entries (the same strings as CYLTabBarController.m). [CN] 记录中的键（与 CYLTabBarController.m 相同）。
    static let originalInsets = "insets"
    static let appliedInsets = "appliedInsets"
    static let originalTitle = "title"
    static let appliedTitle = "appliedTitle"
}

/**
 * FIX: issue #257, issue #522
 * [EN] The automatic adjustment of image-only tabs. What it wrote into a tab bar item is recorded, so it is written only
 *      where the app set nothing, never twice, and can be undone (`automaticallyAdjustsImageOnlyTabs = NO`). Record
 *      entries: `insets` / `appliedInsets`, the item's `imageInsets` before / after; `title` / `appliedTitle`, the same
 *      for `titlePositionAdjustment`. A pair is missing when that value was left to the app. Translated from Objective-C
 *      (docs/Swift-Migration.md, step 58).
 * [CN] 纯图标 Tab 的自动调整。写入 TabBarItem 的内容会被记录：只在 App 未设置的地方写入、不会重复写入、并且可以撤销
 *      （`automaticallyAdjustsImageOnlyTabs = NO`）。记录的键：`insets` / `appliedInsets`，item 原来 / 写入后的 `imageInsets`；
 *      `title` / `appliedTitle`，`titlePositionAdjustment` 的对应值。某一对缺失表示该值留给 App。已从 Objective-C 翻译
 *      （docs/Swift-Migration.md，第 58 步）。
 */
extension CYLTabBarController {

    private typealias CYLImageOnlyTabRecord = [String: NSValue]

    @objc(automaticallyAdjustsImageOnlyTabs)
    open var automaticallyAdjustsImageOnlyTabs: Bool {
        @objc(automaticallyAdjustsImageOnlyTabs) get { cylAutomaticallyAdjustsImageOnlyTabs() }
        @objc(setAutomaticallyAdjustsImageOnlyTabs:) set { cylSetAutomaticallyAdjustsImageOnlyTabs(newValue) }
    }

    func cylAutomaticallyAdjustsImageOnlyTabs() -> Bool {
        !cylPrivate.cylImageOnlyTabsAdjustmentDisabled()
    }

    func cylSetAutomaticallyAdjustsImageOnlyTabs(_ automaticallyAdjustsImageOnlyTabs: Bool) {
        if cylAutomaticallyAdjustsImageOnlyTabs() == automaticallyAdjustsImageOnlyTabs {
            return
        }
        cylPrivate.cylSetImageOnlyTabsAdjustmentDisabled(!automaticallyAdjustsImageOnlyTabs)
        // [EN] Read the stored tab bar: the getter would create one. [CN] 读取已保存的 TabBar：getter 会创建新的 TabBar。
        guard tabBarStyleType != .flatDesign, let tabBar = cylPrivate.cylStoredTabBar() as? CYLTabBar else {
            return
        }
        guard automaticallyAdjustsImageOnlyTabs else {
            cylRestoreImageOnlyTabItems(tabBar.items ?? [])
            return
        }
        if tabBar.tabImageViewDefaultOffset != 0 {
            offsetTabBarTabImageView(toFit: tabBar.tabImageViewDefaultOffset)
        } else {
            // [EN] Not measured yet: the next layout measures it. [CN] 尚未测量：下次布局时测量。
            tabBar.setNeedsLayout()
        }
    }

    /**
     * [EN] Undoes what `-offsetTabBarTabImageViewToFit:` wrote, where the app has not changed the value since.
     * [CN] 撤销 `-offsetTabBarTabImageViewToFit:` 写入的值（App 之后未修改过的值）。
     */
    @objc(cyl_restoreImageOnlyTabItems:)
    func cylRestoreImageOnlyTabItems(_ tabBarItems: [UITabBarItem]) {
        for item in tabBarItems {
            guard let record = objc_getAssociatedObject(item, CYLImageOnlyTabKeys.adjustment) as? CYLImageOnlyTabRecord else {
                continue
            }
            if let appliedInsets = record[CYLImageOnlyTabKeys.appliedInsets], item.imageInsets == appliedInsets.uiEdgeInsetsValue {
                item.imageInsets = record[CYLImageOnlyTabKeys.originalInsets]?.uiEdgeInsetsValue ?? .zero
            }
            if let appliedTitle = record[CYLImageOnlyTabKeys.appliedTitle], item.titlePositionAdjustment == appliedTitle.uiOffsetValue {
                item.titlePositionAdjustment = record[CYLImageOnlyTabKeys.originalTitle]?.uiOffsetValue ?? .zero
            }
            objc_setAssociatedObject(item, CYLImageOnlyTabKeys.adjustment, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /**
     * [EN] Moves the images of the image-only tabs by `tabImageViewDefaultOffset` (measured once by `CYLTabBar`). Only
     *      items without a title are written, only values the app left at zero, and a value already written is not
     *      written again; before, every item was written on every notification, replacing the app's offsets, moving
     *      titles off screen (#522) and laying the tab bar out again in a loop (#257).
     * [CN] 按 `tabImageViewDefaultOffset`（由 `CYLTabBar` 测量一次）移动纯图标 Tab 的图片。只写入没有标题的 item，只写入 App 保持为零的值，
     *      已写入的值不会重复写入；以前每次通知都会写入所有 item，替换 App 的偏移、把标题移出屏幕（#522），并循环触发 TabBar 布局（#257）。
     */
    @objc(offsetTabBarTabImageViewToFit:)
    func offsetTabBarTabImageView(toFit tabImageViewDefaultOffset: CGFloat) {
        guard tabBarStyleType != .flatDesign, cylAutomaticallyAdjustsImageOnlyTabs(), imageInsets == .zero else {
            return
        }
        let shouldCustomizeTitlePositionAdjustment = titlePositionAdjustment != .zero
        let imageInset = UIEdgeInsets(top: tabImageViewDefaultOffset, left: 0, bottom: -tabImageViewDefaultOffset, right: 0)
        let hiddenTitleOffset = UIOffset(horizontal: 0, vertical: CGFloat(Float.greatestFiniteMagnitude))
        for item in (cyl_tabBar as? UITabBar)?.items ?? [] {
            // [EN] A tab with a title is not image-only. [CN] 有标题的 Tab 不是纯图标 Tab。
            if let title = item.title, !title.isEmpty {
                continue
            }
            let record = objc_getAssociatedObject(item, CYLImageOnlyTabKeys.adjustment) as? CYLImageOnlyTabRecord
            var newRecord = record ?? [:]
            // [EN] Each value is judged by its own entry: `-updateImageInsets:` forgets the insets entry but keeps the title one.
            // [CN] 每个值按各自的记录判断：`-updateImageInsets:` 会清除内边距记录，但保留标题记录。
            let appliedInsets = record?[CYLImageOnlyTabKeys.appliedInsets]
            let insetsAreOurs = appliedInsets.map { item.imageInsets == $0.uiEdgeInsetsValue } ?? false
            let insetsAreFree = appliedInsets == nil && item.imageInsets == .zero
            if insetsAreOurs || insetsAreFree {
                if item.imageInsets != imageInset {
                    item.imageInsets = imageInset
                }
                if insetsAreFree {
                    newRecord[CYLImageOnlyTabKeys.originalInsets] = NSValue(uiEdgeInsets: .zero)
                }
                newRecord[CYLImageOnlyTabKeys.appliedInsets] = NSValue(uiEdgeInsets: imageInset)
            }
            // [EN] The item's own offset, kept by CYL (`CYLTabBarItemTitlePositionAdjustment` or the controller-level offset).
            // [CN] CYL 记录的 item 自身偏移（`CYLTabBarItemTitlePositionAdjustment` 或控制器级别的偏移）。
            let titleOffsetSetByCYL = objc_getAssociatedObject(item, CYLImageOnlyTabKeys.itemTitleOffset) != nil ||
                objc_getAssociatedObject(item, CYLTitlePositionAdjustmentKeys.setByCYL) != nil
            let appliedTitle = record?[CYLImageOnlyTabKeys.appliedTitle]
            let titleIsOurs = appliedTitle.map { item.titlePositionAdjustment == $0.uiOffsetValue } ?? false
            let titleIsFree = appliedTitle == nil && !titleOffsetSetByCYL && item.titlePositionAdjustment == .zero
            if !shouldCustomizeTitlePositionAdjustment && (titleIsOurs || titleIsFree) {
                if item.titlePositionAdjustment != hiddenTitleOffset {
                    item.titlePositionAdjustment = hiddenTitleOffset
                }
                if titleIsFree {
                    newRecord[CYLImageOnlyTabKeys.originalTitle] = NSValue(uiOffset: .zero)
                }
                newRecord[CYLImageOnlyTabKeys.appliedTitle] = NSValue(uiOffset: hiddenTitleOffset)
            }
            objc_setAssociatedObject(item, CYLImageOnlyTabKeys.adjustment, newRecord.isEmpty ? nil : newRecord as NSDictionary,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
