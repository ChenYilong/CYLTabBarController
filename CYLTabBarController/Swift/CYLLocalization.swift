//
//  CYLLocalization.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] Short names for the tab item keys (`CYLTabBarItemTitle` …, now Swift constants in `CYLConstants+Keys.swift`; a seam
 *      with copied strings until they moved, docs/Swift-Migration.md).
 * [CN] 接缝（docs/Swift-Migration.md）：TabBarItem 的 key，与 `CYLTabBarController.h` 中的 `CYLTabBarItemTitle` … 字符串相同；这些常量
 *      仍是 Swift 层看不到的 Objective-C 常量。`CYLTabBarController` 的常量迁移到 Swift 后删除。
 */
enum CYLLocalizationItemKeys {
    static let title = CYLTabBarItemTitle
    static let image = CYLTabBarItemImage
    static let selectedImage = CYLTabBarItemSelectedImage
    static let darkImage = CYLTabBarItemDarkImage
}

/**
 * [EN] Tab item attributes with localized titles (`CYLLocalizedString`), images, selected images and dark images by
 *      index. Translated from Objective-C (docs/Swift-Migration.md); Objective-C callers keep the C function (`@_cdecl`).
 * [CN] 生成 TabBarItem 属性：本地化标题（`CYLLocalizedString`）、图片、选中图片，以及按索引给出的深色图片。已从 Objective-C 翻译
 *      （docs/Swift-Migration.md）；Objective-C 调用方继续使用 C 函数（`@_cdecl`）。
 */
public func CYLLocalizedTabBarItemsAttributes(_ titles: [String], _ images: [Any], _ selectedImages: [Any],
                                              _ darkImages: [NSNumber: Any]?) -> [[AnyHashable: Any]] {
    titles.enumerated().map { index, title in
        var item: [AnyHashable: Any] = [CYLLocalizationItemKeys.title: CYLLocalizedString(title)]
        item[CYLLocalizationItemKeys.image] = index < images.count ? images[index] : nil
        item[CYLLocalizationItemKeys.selectedImage] = index < selectedImages.count ? selectedImages[index] : nil
        item[CYLLocalizationItemKeys.darkImage] = darkImages?[NSNumber(value: index)]
        return item
    }
}

@_cdecl("CYLLocalizedTabBarItemsAttributes")
public func cylLocalizedTabBarItemsAttributesEntryPoint(_ titles: NSArray, _ images: NSArray, _ selectedImages: NSArray,
                                                        _ darkImages: NSDictionary?) -> NSArray {
    let darkImagesByIndex = darkImages as? [NSNumber: Any]
    return CYLLocalizedTabBarItemsAttributes(titles.compactMap { $0 as? String }, images as? [Any] ?? [],
                                             selectedImages as? [Any] ?? [], darkImagesByIndex) as NSArray
}

/**
 * [EN] Localizing the texts of a view tree. Translated from Objective-C (docs/Swift-Migration.md).
 * [CN] 本地化视图树中的文字。已从 Objective-C 翻译（docs/Swift-Migration.md）。
 */
extension UIView {

    /**
     * [EN] Replaces the texts of this view and its subviews (button titles, label texts, text field placeholders) with
     *      `CYLLocalizedString` of them.
     * [CN] 用 `CYLLocalizedString` 替换本视图及其子视图的文字（按钮标题、标签文字、输入框占位文字）。
     */
    @objc(cyl_localizeTexts)
    public func cyl_localizeTexts() {
        if let button = self as? UIButton {
            for state: UIControl.State in [.normal, .highlighted, .selected, .disabled] {
                if let title = button.title(for: state), !title.isEmpty {
                    button.setTitle(CYLLocalizedString(title), for: state)
                }
            }
            return
        }
        if let label = self as? UILabel, let text = label.text, !text.isEmpty {
            label.text = CYLLocalizedString(text)
        } else if let textField = self as? UITextField, let placeholder = textField.placeholder, !placeholder.isEmpty {
            textField.placeholder = CYLLocalizedString(placeholder)
        }
        for subview in subviews {
            subview.cyl_localizeTexts()
        }
    }
}

/**
 * [EN] The language row and picker of the demos. Translated from Objective-C (docs/Swift-Migration.md).
 * [CN] 示例中的语言行与语言选择器。已从 Objective-C 翻译（docs/Swift-Migration.md）。
 */
extension UIViewController {

    private static let languageCellIdentifier = "CYLLanguageCell"

    /**
     * [EN] The languages the picker offers (override to change them).
     * [CN] 选择器提供的语言（可重写以修改）。
     */
    @objc(cyl_pickerLanguages)
    open dynamic class func cyl_pickerLanguages() -> [String] {
        ["en", "zh-Hans", "hi", "es", "ar"]
    }

    /**
     * [EN] A table row that shows the current language; selecting it should call `cyl_presentLanguagePicker()`.
     * [CN] 显示当前语言的表格行；选中时应调用 `cyl_presentLanguagePicker()`。
     */
    @objc(cyl_languageCellForTableView:)
    public func cyl_languageCell(for tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UIViewController.languageCellIdentifier)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: UIViewController.languageCellIdentifier)
        cell.accessoryType = .disclosureIndicator
        cell.detailTextLabel?.textColor = .gray
        let language = CYLLocalizationLanguage()
        let languageTitle = CYLLocalizedString("语言")
        cell.textLabel?.text = "🌐 \(languageTitle)：\(CYLLanguageNames.flaggedName(language))"
        cell.detailTextLabel?.text = CYLLocalizedStringForLanguage("点击切换语言", nil)
        cell.accessibilityLabel = "\(languageTitle), \(CYLLanguageNames.nativeName(language))"
        cell.accessibilityHint = cell.detailTextLabel?.text
        cell.accessibilityTraits = .button
        return cell
    }

    /**
     * [EN] Presents an action sheet with the languages, "follow the system" and cancel.
     * [CN] 弹出包含各语言、"跟随系统"与取消的操作表。
     */
    @objc(cyl_presentLanguagePicker)
    public func cyl_presentLanguagePicker() {
        let picker = UIAlertController(title: CYLLocalizedString("语言"), message: CYLLocalizedStringForLanguage("点击切换语言", nil),
                                       preferredStyle: .actionSheet)
        for language in type(of: self).cyl_pickerLanguages() {
            let action = UIAlertAction(title: CYLLanguageNames.flaggedName(language), style: .default) { _ in
                CYLSetLocalizationLanguage(language)
            }
            action.accessibilityLabel = CYLLanguageNames.nativeName(language)
            picker.addAction(action)
        }
        picker.addAction(UIAlertAction(title: CYLLocalizedString("跟随系统"), style: .default) { _ in
            CYLSetLocalizationLanguage(nil)
        })
        picker.addAction(UIAlertAction(title: CYLLocalizedString("取消"), style: .cancel))
        picker.popoverPresentationController?.sourceView = view
        picker.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        present(picker, animated: true)
    }
}

/**
 * [EN] Rebuilding the root view controller when the language changes. Translated from Objective-C
 *      (docs/Swift-Migration.md).
 * [CN] 语言变化时重建根控制器。已从 Objective-C 翻译（docs/Swift-Migration.md）。
 */
extension UIWindow {

    private static let rootProviderObserverKey = CYLUtilsKeys.key("cyl_setRootViewControllerProvider:")

    /**
     * [EN] Sets the root view controller from `provider` now and again after every language change (right-to-left
     *      languages flip the layout). In DEBUG, logs when the replaced root view controller is still alive 3 s later
     *      (issue #488).
     * [CN] 立即用 `provider` 设置根控制器，并在每次语言变化后重新设置（从右到左的语言会翻转布局）。DEBUG 下，被替换的根控制器 3 秒后
     *      仍未释放时打印日志（issue #488）。
     */
    @objc(cyl_setRootViewControllerProvider:)
    public func cyl_setRootViewControllerProvider(_ provider: @escaping () -> UIViewController) {
        if let previousObserver = objc_getAssociatedObject(self, UIWindow.rootProviderObserverKey) {
            NotificationCenter.default.removeObserver(previousObserver)
        }
        let reload: () -> Void = { [weak self] in
            let rightToLeft = Locale.characterDirection(forLanguage: CYLLocalizationLanguage()) == .rightToLeft
            UIView.appearance().semanticContentAttribute = rightToLeft ? .forceRightToLeft : .unspecified
            let previousRootViewController = self?.rootViewController
            self?.rootViewController = provider()
            UIWindow.warnIfStillAliveAfterReplacement(previousRootViewController)
        }
        reload()
        let observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name(CYLLocalizationLanguageDidChangeNotification), object: nil, queue: .main) { _ in
            reload()
        }
        objc_setAssociatedObject(self, UIWindow.rootProviderObserverKey, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private static func warnIfStillAliveAfterReplacement(_ viewController: UIViewController?) {
        #if DEBUG
        guard let viewController else {
            return
        }
        let description = "<\(NSStringFromClass(type(of: viewController))): \(Unmanaged.passUnretained(viewController).toOpaque())>"
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak viewController] in
            if viewController != nil {
                NSLog("⚠️ CYLTabBarController: %@ is still alive 3s after it was replaced as the root view controller; "
                      + "something keeps a strong reference to it (see the Xcode Memory Graph). #488", description)
            }
        }
        #endif
    }
}

/**
 * [EN] Language names for the picker.
 * [CN] 选择器使用的语言名称。
 */
private enum CYLLanguageNames {

    static func nativeName(_ language: String) -> String {
        let locale = Locale(identifier: language)
        guard let name = (locale as NSLocale).localizedString(forLanguageCode: language), !name.isEmpty else {
            return language
        }
        return name.prefix(1).uppercased(with: locale) + name.dropFirst()
    }

    static func flaggedName(_ language: String) -> String {
        let flags = ["en": "🇺🇸", "zh-Hans": "🇨🇳", "hi": "🇮🇳", "es": "🇪🇸", "ar": "🇸🇦"]
        return "\(flags[language] ?? "🌐") \(nativeName(language))"
    }
}
