//
//  UIViewController+CYLConfigurationDemo.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] The configuration file demo of the settings section: a tab bar controller from a sample file, a resource route, a
 *      manifest or a URL, and the simulated failures of docs/Configuration-File.md. Translated from Objective-C
 *      (docs/Swift-Migration.md, step 31); selectors and the class names of the automatically registered pages are kept.
 * [CN] 设置分组中的配置文件演示：由示例文件、资源路由、清单或 URL 创建 TabBarController，以及 docs/Configuration-File.md 中的模拟意外情况。
 *      已从 Objective-C 翻译（docs/Swift-Migration.md，第 31 步）；selector 与自动注册页面的类名不变。
 */
enum CYLConfigurationDemo {

    static let sampleURLString = "https://raw.githubusercontent.com/ChenYilong/CYLTabBarController/master/Example-Shared/Configurations/cyl_tabbar_configuration.yaml"

    /**
     * [EN] Text shown as is in every language (routes, file names, manifest themes). [CN] 在所有语言中原样显示的文字（路由、文件名、清单主题）。
     */
    static func untranslated(_ text: String) -> String {
        text
    }

    /**
     * [EN] The text a page shows for its configuration file: the file, or the parsed dictionary for binary data (a protobuf
     *      message can be valid UTF-8).
     * [CN] 页面显示的配置文件文本：文件本身；二进制数据（protobuf 消息也可能是合法的 UTF-8）显示为解析后的字典。
     */
    static func sourceText(_ path: String?, _ configuration: [String: Any]?) -> String {
        var binary = CharacterSet.controlCharacters
        binary.remove(charactersIn: "\t\n\r")
        if let path, let text = try? String(contentsOfFile: path, encoding: .utf8), !text.isEmpty,
           text.rangeOfCharacter(from: binary) == nil {
            return text
        }
        return configuration.map { ($0 as NSDictionary).description } ?? ""
    }

    /**
     * [EN] The title of a tab, from its configuration, or its page ID. [CN] Tab 的标题（来自其配置），否则为页面 ID。
     */
    static func title(_ pageIdentifier: String, _ tabAttributes: [String: Any]) -> String {
        (tabAttributes[CYLTabBarItemTitle] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? pageIdentifier
    }

    /**
     * [EN] A demo page: its title and a text, in a navigation controller. [CN] 演示页面：标题与一段文字，包裹在导航控制器中。
     */
    static func page(_ title: String, _ text: String) -> UIViewController {
        let page = UIViewController()
        page.navigationItem.title = title
        page.view.backgroundColor = .systemBackground
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = text
        label.translatesAutoresizingMaskIntoConstraints = false
        page.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: page.view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: page.view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: page.view.trailingAnchor, constant: -24),
        ])
        return UINavigationController(rootViewController: page)
    }

    /**
     * [EN] The pages of the samples and the simulated failures, in the shared registry, once: "home", "message", "discover",
     *      "me", "tab", "publish", and "web", which shows the URL of its CYLTabBarItemPageParameters (docs/Tab-Page-Registry.md).
     * [CN] 示例与模拟意外情况使用的页面，一次性注册到全局注册表："home"、"message"、"discover"、"me"、"tab"、"publish"，以及显示其
     *      CYLTabBarItemPageParameters 中 URL 的 "web"（docs/Tab-Page-Registry.md）。
     */
    static let registerPages: Void = {
        let registry = CYLTabBarPageRegistry.shared
        registry.register({ pageIdentifier, tabAttributes in
            page(title(pageIdentifier, tabAttributes), "page ID: \(pageIdentifier)")
        }, forPageIdentifiers: ["home", "message", "discover", "me", "tab", "publish"])
        registry.register({ pageIdentifier, tabAttributes in
            let url = (tabAttributes[CYLTabBarItemPageParameters] as? [String: Any])?["url"] as? String ?? "(no url)"
            return page(title(pageIdentifier, tabAttributes), "page ID: \(pageIdentifier)\nCYLTabBarItemPageParameters.url:\n\(url)")
        }, forPageIdentifier: "web")
    }()

    /**
     * [EN] Stands in for a download: copies the samples into Caches/CYLConfigurationDemo with the names of
     *      docs/Resource-Routes.md, and the string tables into Localization/.
     * [CN] 代替下载：把示例复制到 Caches/CYLConfigurationDemo，文件名遵循 docs/Resource-Routes.md，字符串表放在 Localization/ 中。
     */
    static func copySamplesIntoSandbox(_ samples: String) {
        let manager = FileManager.default
        guard let folder = CYLResourceRoute.path(forRoute: "sandbox:Caches/CYLConfigurationDemo", baseDirectory: nil) else { return }
        try? manager.removeItem(atPath: folder)
        try? manager.createDirectory(atPath: folder, withIntermediateDirectories: true)
        let copies = [
            "tabbar@1.0.json": "cyl_tabbar_configuration.json",
            "tabbar@2.0.json": "cyl_tabbar_configuration.json",
            "tabbar-dark@1.0.json": "cyl_tabbar_configuration.json",
            "tabbar-dark@2.0.yaml": "cyl_tabbar_configuration.yaml",
            "Localization": "Localization",
        ]
        for (name, source) in copies {
            try? manager.copyItem(atPath: (samples as NSString).appendingPathComponent(source), toPath: (folder as NSString).appendingPathComponent(name))
        }
    }

    /**
     * [EN] Stands in for a server: copies the built-in manifest and its 2.1.0 images into tmp/CYLManifestServer/ and returns
     *      the manifest's file URL; `broken`: one hash is wrong, so the loader falls back.
     * [CN] 代替服务器：把内置清单及其 2.1.0 图片复制到 tmp/CYLManifestServer/ 并返回清单的文件 URL；`broken`：有一个哈希错误，加载器会回退。
     */
    static func publishManifest(broken: Bool) -> URL {
        let manager = FileManager.default
        let server = (NSTemporaryDirectory() as NSString).appendingPathComponent("CYLManifestServer")
        try? manager.removeItem(atPath: server)
        try? manager.createDirectory(atPath: server, withIntermediateDirectories: true)
        if let skins = CYLResourceRoute.path(forRoute: "bundle:Configurations/Skins/2.1.0", baseDirectory: nil) {
            for theme in (try? manager.contentsOfDirectory(atPath: skins)) ?? [] {
                try? manager.copyItem(atPath: (skins as NSString).appendingPathComponent(theme), toPath: (server as NSString).appendingPathComponent(theme))
            }
        }
        var manifest: [String: Any] = [:]
        if let path = CYLResourceRoute.path(forRoute: "bundle:Configurations/Manifests/cyl_tabbar_manifest.json", baseDirectory: nil),
           let data = FileManager.default.contents(atPath: path),
           let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            manifest = object
        }
        if broken, var assets = manifest["assets"] as? [String: Any], var list = assets["list"] as? [[String: Any]], !list.isEmpty {
            manifest["version"] = "9.0.0"
            list[0]["hash"] = "sha256-tampered"
            assets["list"] = list
            manifest["assets"] = assets
        }
        let published = (server as NSString).appendingPathComponent(broken ? "manifest-broken.json" : "manifest.json")
        try? JSONSerialization.data(withJSONObject: manifest).write(to: URL(fileURLWithPath: published))
        return URL(fileURLWithPath: published)
    }
}

extension UIViewController {

    /**
     * [EN] The sample configuration files of the app (Example-Shared/Configurations, bundled as "Configurations"), sorted;
     *      configuration files only, not the .proto schema.
     * [CN] App 的示例配置文件（Example-Shared/Configurations，以 "Configurations" 打包），已排序；只含配置文件，不含 .proto 结构定义。
     */
    @objc(cyl_sampleConfigurationFilePaths)
    public class func cyl_sampleConfigurationFilePaths() -> [String] {
        guard let directory = CYLResourceRoute.path(forRoute: "bundle:Configurations", baseDirectory: nil) else { return [] }
        let extensions = CYLTabBarConfigurationParser.supportedPathExtensions()
        return ((try? FileManager.default.contentsOfDirectory(atPath: directory)) ?? []).sorted().filter {
            !$0.hasPrefix(".") && extensions.contains(($0 as NSString).pathExtension.lowercased())
        }.map { (directory as NSString).appendingPathComponent($0) }
    }

    /**
     * [EN] The cell that opens the configuration demo. [CN] 打开配置文件演示的 cell。
     */
    @objc(cyl_configurationDemoCellForTableView:)
    public func cyl_configurationDemoCell(for tableView: UITableView) -> UITableViewCell {
        let identifier = "CYLConfigurationDemoCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
            cell.textLabel?.font = .boldSystemFont(ofSize: 15)
            cell.detailTextLabel?.textColor = .gray
            cell.detailTextLabel?.numberOfLines = 0
            cell.accessoryType = .disclosureIndicator
            cell.imageView?.image = UIImage(systemName: "doc.text")
            return cell
        }()
        cell.textLabel?.text = CYLLocalizedString("从配置文件创建 TabBarController")
        cell.detailTextLabel?.text = CYLLocalizedString("一个文件生成整个 TabBar：可选 JSON、YAML、TOML、plist、XML、INI 等格式，或从网络 URL 加载。")
        return cell
    }

    /**
     * [EN] An action sheet of sources: each sample file, a resource route, a sandbox route, manifests (built in, downloaded,
     *      downloaded with a bad asset) and a network URL.
     * [CN] 选择来源的操作表：每个示例文件、资源路由、沙盒路由、清单（内置、下载、资源错误的下载）与网络 URL。
     */
    @objc(cyl_presentConfigurationDemo)
    public func cyl_presentConfigurationDemo() {
        CYLConfigurationDemo.registerPages
        let sheet = UIAlertController(title: CYLLocalizedString("选择配置文件"), message: nil, preferredStyle: .actionSheet)
        func add(_ title: String, _ handler: @escaping () -> Void) {
            sheet.addAction(UIAlertAction(title: title, style: .default) { _ in handler() })
        }
        for path in UIViewController.cyl_sampleConfigurationFilePaths() {
            let name = (path as NSString).lastPathComponent
            add(name) { [weak self] in
                var error: NSError?
                let tabBarController = Self.cyl_tabBarController { try CYLTabBarController(configurationFile: path) } error: { error = $0 }
                let configuration = try? CYLTabBarController.configuration(withContentsOfFile: path)
                self?.cyl_presentConfigurationDemoTabBarController(tabBarController, source: name,
                                                                    sourceText: CYLConfigurationDemo.sourceText(path, configuration), error: error)
            }
        }
        // [EN] A resource route instead of a path (docs/Resource-Routes.md). [CN] 用资源路由代替路径（docs/Resource-Routes.md）。
        let route = "bundle:Configurations?name=cyl_tabbar_configuration"
        if let routedPath = CYLResourceRoute.path(forRoute: route, baseDirectory: nil) {
            add(CYLConfigurationDemo.untranslated(route)) { [weak self] in
                var error: NSError?
                let tabBarController = Self.cyl_tabBarController { try CYLTabBarController(configurationRoute: route) } error: { error = $0 }
                let configuration = try? CYLTabBarController.configuration(withRoute: route)
                self?.cyl_presentConfigurationDemoTabBarController(tabBarController, source: "\(route)\n→ \((routedPath as NSString).lastPathComponent)",
                                                                    sourceText: CYLConfigurationDemo.sourceText(routedPath, configuration), error: error)
            }
            // [EN] Resources downloaded into the sandbox (several versions and themes), then the route picks one file.
            // [CN] 下载到沙盒的资源（多个版本与主题），再由路由选出一个文件。
            let sandboxRoute = "sandbox:Caches/CYLConfigurationDemo?name=tabbar&theme=dark"
            add(CYLConfigurationDemo.untranslated(sandboxRoute)) { [weak self] in
                CYLConfigurationDemo.copySamplesIntoSandbox((routedPath as NSString).deletingLastPathComponent)
                var error: NSError?
                let tabBarController = Self.cyl_tabBarController { try CYLTabBarController(configurationRoute: sandboxRoute) } error: { error = $0 }
                let path = CYLResourceRoute.path(forRoute: sandboxRoute, baseDirectory: nil)
                let configuration = path.flatMap { try? CYLTabBarController.configuration(withContentsOfFile: $0) }
                self?.cyl_presentConfigurationDemoTabBarController(
                    tabBarController, source: "\(sandboxRoute)\n→ \(path.map { ($0 as NSString).lastPathComponent } ?? "-")",
                    sourceText: CYLConfigurationDemo.sourceText(path, configuration), error: error)
            }
        }
        cyl_addManifestActions(add)
        add(CYLLocalizedString("从网络 URL 加载")) { [weak self] in
            guard let url = URL(string: CYLConfigurationDemo.sampleURLString) else { return }
            CYLTabBarController.loadConfiguration(with: url) { configuration, error in
                var tabBarController = configuration.map { CYLTabBarController(configuration: $0) }
                if (tabBarController?.viewControllers?.count ?? 0) == 0 {
                    tabBarController = nil
                }
                self?.cyl_presentConfigurationDemoTabBarController(tabBarController, source: url.absoluteString,
                                                                    sourceText: CYLConfigurationDemo.sourceText(nil, configuration),
                                                                    error: error as NSError?)
            }
        }
        sheet.addAction(UIAlertAction(title: CYLLocalizedString("取消"), style: .cancel))
        // [EN] iPad: an action sheet needs an anchor. [CN] iPad 上的操作表需要锚点。
        sheet.popoverPresentationController?.sourceView = view
        sheet.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        present(sheet, animated: true)
    }

    /**
     * [EN] Manifests (docs/Configuration-Manifest.md): built in, in two themes; downloaded (a local "server" folder) into the
     *      sandbox; and a download whose asset fails its hash, which falls back to the cached or built-in manifest.
     * [CN] 配置清单（docs/Configuration-Manifest.md）：App 内置（两个主题）；下载（本地模拟服务器目录）到沙盒；以及资源哈希校验失败的下载，
     *      回退到缓存或内置清单。
     */
    private func cyl_addManifestActions(_ add: (String, @escaping () -> Void) -> Void) {
        let manifestRoute = "bundle:Configurations/Manifests/cyl_tabbar_manifest.json"
        guard let manifestPath = CYLResourceRoute.path(forRoute: manifestRoute, baseDirectory: nil),
              FileManager.default.fileExists(atPath: manifestPath) else {
            return
        }
        for theme in ["light", "christmas"] {
            add(CYLConfigurationDemo.untranslated("Manifest · \(theme) · \(manifestRoute)")) { [weak self] in
                var error: NSError?
                var manifest: CYLTabBarManifest?
                var tabBarController: CYLTabBarController?
                do {
                    manifest = try CYLTabBarManifest.manifest(withRoute: manifestRoute)
                    tabBarController = try manifest?.tabBarController() as? CYLTabBarController
                } catch let caught as NSError {
                    error = caught
                }
                // [EN] After the manifest registered its themes; a skin other than light / dark stops following the system.
                // [CN] 在清单注册其主题之后；浅色 / 深色以外的皮肤停止跟随系统外观。
                let manager = CYLThemeManagerCenter.themeManager(withName: "CYLConfigurationDemo" as NSString)
                if theme != "light" {
                    manager.respondsSystemStyleAutomatically = false
                    manager.identifierForTrait = nil
                }
                manager.currentThemeIdentifier = theme as NSString
                self?.cyl_presentConfigurationDemoTabBarController(
                    tabBarController, source: "\(manifestRoute)\nversion \(manifest?.version ?? "-") · theme \(theme)",
                    sourceText: CYLConfigurationDemo.sourceText(manifestPath, manifest?.dictionary), error: error)
            }
        }
        for broken in [false, true] {
            let title = broken ? "Manifest · download with a bad asset → fallback" : "Manifest · download into sandbox:Caches"
            add(CYLConfigurationDemo.untranslated(title)) { [weak self] in
                let url = CYLConfigurationDemo.publishManifest(broken: broken)
                let loader = CYLTabBarManifestLoader()
                loader.embeddedManifestRoute = manifestRoute
                loader.loadManifest(with: url) { manifest, source, error in
                    let sources = ["none", "remote", "cache", "embedded"]
                    var createError: NSError?
                    var tabBarController: CYLTabBarController?
                    do {
                        tabBarController = try manifest?.tabBarController() as? CYLTabBarController
                    } catch let caught as NSError {
                        createError = caught
                    }
                    let fallback = error.map { "\nfallback because: " + $0.localizedDescription } ?? ""
                    let summary = "\(url.lastPathComponent)\nsource: \(sources[source.rawValue]) · version \(manifest?.version ?? "-")\(fallback)"
                    self?.cyl_presentConfigurationDemoTabBarController(tabBarController, source: summary,
                                                                        sourceText: CYLConfigurationDemo.sourceText(nil, manifest?.dictionary),
                                                                        error: createError)
                }
            }
        }
    }

    /**
     * [EN] Runs a throwing factory, reporting its error. [CN] 执行可能抛错的工厂方法，并报告错误。
     */
    static func cyl_tabBarController(_ make: () throws -> CYLTabBarController, error report: (NSError) -> Void) -> CYLTabBarController? {
        do {
            return try make()
        } catch let error as NSError {
            report(error)
            return nil
        }
    }

    /**
     * [EN] Presents the created tab bar controller, each page showing its source, or an alert with the error.
     * [CN] 展示生成的 TabBarController（每个页面显示其来源），或用弹窗显示错误。
     */
    func cyl_presentConfigurationDemoTabBarController(_ tabBarController: CYLTabBarController?, source: String, sourceText: String,
                                                      error: NSError?) {
        guard let tabBarController else {
            let alert = UIAlertController(title: CYLLocalizedString("无法创建 TabBarController"), message: error?.localizedDescription,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: CYLLocalizedString("关闭"), style: .cancel))
            present(alert, animated: true)
            return
        }
        for viewController in tabBarController.viewControllers ?? [] {
            let page = (viewController as? UINavigationController)?.viewControllers.first ?? viewController
            cyl_decorateConfigurationDemoPage(page, tabBarController: tabBarController, source: source, sourceText: sourceText)
        }
        tabBarController.modalPresentationStyle = .fullScreen
        present(tabBarController, animated: true)
    }

    private func cyl_decorateConfigurationDemoPage(_ page: UIViewController, tabBarController: CYLTabBarController, source: String,
                                                   sourceText: String) {
        page.view.backgroundColor = .systemBackground
        // [EN] The bar button item keeps its target weak, so the tab bar controller is not retained.
        // [CN] UIBarButtonItem 弱引用 target，不会造成循环引用。
        page.navigationItem.leftBarButtonItem = UIBarButtonItem(title: CYLLocalizedString("关闭"), style: .plain, target: tabBarController,
                                                                action: #selector(UIViewController.cyl_dismissConfigurationDemo))
        let header = UILabel()
        header.numberOfLines = 0
        header.font = .boldSystemFont(ofSize: 15)
        header.text = String(format: CYLLocalizedString("本页由配置文件 %@ 创建："), source)
        let textView = UITextView()
        textView.isEditable = false
        textView.text = sourceText
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 8
        let stack = UIStackView(arrangedSubviews: [header, textView])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        page.view.addSubview(stack)
        let guide = page.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: guide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -12),
        ])
    }

    /**
     * [EN] The Close button of the configuration demos: dismisses what this controller presents, or itself.
     * [CN] 配置文件演示页的关闭按钮：关闭本控制器所展示的内容，或它自己。
     */
    @objc(cyl_dismissConfigurationDemo)
    func cyl_dismissConfigurationDemo() {
        dismiss(animated: true)
    }
}

// MARK: - Simulated failures (docs/Configuration-File.md)

enum CYLConfigurationEdgeCases {

    static let resultsKey = CYLUtilsKeys.key("cyl_configurationEdgeCaseResults")
    static let tableViewKey = CYLUtilsKeys.key("cyl_configurationEdgeCaseTableView")

    /**
     * [EN] The cases: (ID of docs/Configuration-File.md, title). [CN] 各情况：（docs/Configuration-File.md 中的编号, 标题）。
     */
    static let all: [(id: String, title: String)] = [
        ("A3", "Empty file"), ("A4", "Comments only"), ("A13", "Malformed JSON"), ("A11", "Top level is a list"),
        ("A7", "YAML in a .json file"), ("A5", "Not UTF-8"), ("A16", "UTF-16 encoded"), ("A10", "Nested 10,000 levels"),
        ("A9", "A 6 MB file"), ("B1", "No tabs"), ("D7", "An HTML page (file)"), ("B5", "Wrong types and null"),
        ("B7", "NaN and Infinity insets"), ("B9", "Unknown style"), ("C11", "Unregistered page IDs"),
        ("C12", "A page provider raises (code)"), ("C13", "Pages that cannot be tabs (code)"),
        ("C14", "Automatic registration (CYLTabBarPage)"), ("C15", "Registry and resolver of wrong types"),
        ("C16", "Two tab bars, one page ID"), ("C18", "Lookup order and automatic registration"),
        ("B22", "Other platforms and newer versions"),
        ("B23", "Invalid platforms, versions and parameters"), ("B27", "Reload with new tabs (code)"),
        ("C20", "Asynchronous pages (code)"), ("B28", "Animation keys, options and speed"), ("B30", "GIF keys and a file that is not a GIF"),
        ("B13", "Invalid URLs and Lottie files"),
        ("B12", "Duplicate identifiers"), ("B11", "Misspelled keys"), ("B19", "Invalid colors and fonts"), ("B21", "Empty strings"),
        ("A12", "Truncated protobuf"),
        ("A12", "Corrupted binary plist"), ("A14", "XML external entity"), ("A2", "Missing file"),
        ("E1", "Created on a background thread"), ("C6", "Non-controllers and duplicates (code)"),
        ("B18", "Configuration is not a dictionary (code)"), ("C9", "Empty view controller list (code)"),
        ("D3", "HTTP 404"), ("D4", "Unknown host"), ("D5", "Server timeout (3 s)"), ("D10", "Request cancelled"),
        ("C10", "Request without a URL"),
        ("D7", "An HTML page (network)"),
        ("L1", "Localized texts (tables in the sandbox)"),
    ]

    /**
     * [EN] Two valid tabs, as JSON. [CN] 两个有效的 Tab（JSON）。
     */
    static let tabsJSON = #"[{"CYLTabBarItemTitle": "Home", "CYLTabBarItemImage": "system:house", "CYLTabBarItemIdentifier": "home"}, {"CYLTabBarItemTitle": "Me", "CYLTabBarItemImage": "system:person", "CYLTabBarItemIdentifier": "me"}]"#

    static let twoTabs: [[String: Any]] = [
        [CYLTabBarItemTitle: "Home", CYLTabBarItemImage: "system:house", CYLTabBarItemIdentifier: "home"],
        [CYLTabBarItemTitle: "Me", CYLTabBarItemImage: "system:person", CYLTabBarItemIdentifier: "me"],
    ]

    /**
     * [EN] The English name of a skip reason (an identifier, not translated). [CN] 跳过原因的英文名称（标识符，不翻译）。
     */
    static func name(of reason: CYLTabBarPageSkipReason) -> String {
        switch reason {
        case .invalidTab: return "invalid tab"
        case .missingIdentifier: return "no page ID"
        case .unregistered: return "unregistered"
        case .excluded: return "excluded"
        case .providerFailed: return "provider failed"
        @unknown default: return "unknown"
        }
    }

    /**
     * [EN] Writes `data` to a temporary file and returns its path. [CN] 将 `data` 写入临时文件并返回路径。
     */
    static func file(_ name: String, _ data: Data) -> String {
        let directory = (NSTemporaryDirectory() as NSString).appendingPathComponent("CYLConfigurationEdgeCases")
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        let path = (directory as NSString).appendingPathComponent(name)
        try? data.write(to: URL(fileURLWithPath: path), options: .atomic)
        return path
    }

    /**
     * [EN] A request for a URL string, or a request without a URL when the string is not a URL (C10).
     * [CN] URL 字符串对应的请求；字符串不是 URL 时为没有 URL 的请求（C10）。
     */
    static func request(_ string: String, timeout: TimeInterval = 0) -> URLRequest {
        guard let url = URL(string: string) else {
            return (NSURLRequest() as URLRequest)
        }
        return timeout > 0 ? URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout) : URLRequest(url: url)
    }

    static func data(_ text: String) -> Data {
        Data(text.utf8)
    }

    /**
     * [EN] The configuration files written by the file cases, by title. [CN] 文件类情况写入的配置文件，按标题索引。
     */
    static let files: [String: (name: String, text: String)] = [
        "Comments only": ("comments.yaml", "# nothing but comments\n# 只有注释\n"),
        "Malformed JSON": ("malformed.json", #"{"CYLTabBarControllerTabBarItemsAttributes": [ {"CYLTabBarItemTitle": "Home" "#),
        "Top level is a list": ("list.json", tabsJSON),
        "YAML in a .json file": ("yaml.json", "CYLTabBarControllerTabBarItemsAttributes:\n  - CYLTabBarItemTitle: Home\n    CYLTabBarItemImage: system:house\n    CYLTabBarItemIdentifier: home\n  - CYLTabBarItemTitle: Me\n    CYLTabBarItemImage: system:person\n    CYLTabBarItemIdentifier: me\n"),
        "Nested 10,000 levels": ("deep.json", #"{"CYLTabBarControllerTabBarItemsAttributes": "# + String(repeating: "[", count: 10000) + String(repeating: "]", count: 10000) + "}"),
        "No tabs": ("no_tabs.json", #"{"CYLTabBarControllerContext": "NoTabs"}"#),
        "An HTML page (file)": ("portal.xml", "<html><head><title>Wi-Fi</title></head><body><form>Accept</form></body></html>"),
        "Wrong types and null": ("types.json", #"{"CYLTabBarControllerContext": [1, 2], "CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": ["a", "list"], "CYLTabBarItemImage": null, "CYLTabBarItemIdentifier": 7, "CYLTabBarItemPageIdentifier": "home"}, "not a tab", {"CYLTabBarItemTitle": 42, "CYLTabBarItemImage": {"a": 1}, "CYLTabBarItemIdentifier": "me"}]}"#),
        "NaN and Infinity insets": ("nan.yaml", "CYLTabBarControllerImageInsets: \"{nan, 0, 0, 0}\"\nCYLTabBarControllerTitlePositionAdjustment: [1e999, -3]\nCYLTabBarControllerTabBarItemsAttributes:\n  - CYLTabBarItemTitle: Home\n    CYLTabBarItemIdentifier: home\n    CYLTabBarItemImage: system:house\n    CYLTabBarItemImageInsets: \"{inf, 0, -inf, 0}\"\n    CYLTabBarLottieSize: \"{-24, 0}\"\n"),
        "Unknown style": ("style.toml", "CYLTabBarControllerStyleType = 99\n[[CYLTabBarControllerTabBarItemsAttributes]]\nCYLTabBarItemTitle = \"Home\"\nCYLTabBarItemIdentifier = \"home\"\nCYLTabBarItemImage = \"system:house\"\n"),
        // [EN] C11: "home" is registered; "no_such_page" and a tab without any ID are skipped.
        // [CN] C11："home" 已注册；"no_such_page" 与没有任何 ID 的 Tab 会被跳过。
        "Unregistered page IDs": ("unregistered.json", #"{"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home", "CYLTabBarItemImage": "system:house", "CYLTabBarItemIdentifier": "home"}, {"CYLTabBarItemTitle": "Unknown", "CYLTabBarItemPageIdentifier": "no_such_page"}, {"CYLTabBarItemTitle": "No ID"}]}"#),
        // [EN] C14: "auto" and "conflict" come from classes that adopt CYLTabBarPage; no registration code.
        // [CN] C14："auto" 与 "conflict" 来自遵守 CYLTabBarPage 的类，无需注册代码。
        "Automatic registration (CYLTabBarPage)": ("automatic.json", #"{"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Auto", "CYLTabBarItemImage": "system:wand.and.stars", "CYLTabBarItemPageIdentifier": "auto"}, {"CYLTabBarItemTitle": "Conflict", "CYLTabBarItemImage": "system:exclamationmark.2", "CYLTabBarItemPageIdentifier": "conflict"}]}"#),
        // [EN] C15: the registry and the resolver are strings in a file: ignored with a warning; the shared registry is used.
        // [CN] C15：文件中的注册表与解析回调是字符串：忽略并输出警告；使用全局注册表。
        "Registry and resolver of wrong types": ("wrong_registry.json", #"{"CYLTabBarControllerPageRegistry": "MyRegistry", "CYLTabBarControllerPageResolver": "resolve:", "CYLTabBarControllerTabBarItemsAttributes": "# + tabsJSON + "}"),
        // [EN] C18: "shared, bogus" keeps "shared" (the unknown entry is dropped with a warning) and "no" turns automatic
        //      registration off: "home" stays, "auto" and "maybe" are skipped and listed in `cyl_skippedTabs`.
        // [CN] C18："shared, bogus" 保留 "shared"（未知项丢弃并警告），"no" 关闭自动注册："home" 保留，"auto" 与 "maybe" 被跳过并记录在
        //      `cyl_skippedTabs` 中。
        "Lookup order and automatic registration": ("lookup_order.json", #"{"CYLTabBarControllerPageLookupOrder": "shared, bogus", "CYLTabBarControllerAutomaticPageRegistration": "no", "CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home", "CYLTabBarItemImage": "system:house", "CYLTabBarItemIdentifier": "home"}, {"CYLTabBarItemTitle": "Auto", "CYLTabBarItemPageIdentifier": "auto"}, {"CYLTabBarItemTitle": "Maybe", "CYLTabBarItemPageIdentifier": "maybe"}]}"#),
        // [EN] B28 / B29: a Rive URL with options, a generic animation path of a missing file, options that are not a
        //      dictionary, an invalid speed and loop flag: ignored with warnings; the tabs are created in every case.
        // [CN] B28 / B29：带选项的 Rive URL、指向不存在文件的通用动画路径、不是字典的选项、无效的速度与循环开关：忽略并警告；Tab 都会创建。
        "Animation keys, options and speed": ("animation.json", #"{"CYLTabBarControllerTabBarItemAnimationSpeed": "fast", "CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home", "CYLTabBarItemImage": "system:house", "CYLTabBarItemIdentifier": "home", "CYLTabBarRiveURL": "https://example.com/icons.riv", "CYLTabBarAnimationOptions": {"artboard": "HOME", "input": "active", "duration": 2, "bad": [1, 2]}}, {"CYLTabBarItemTitle": "Me", "CYLTabBarItemImage": "system:person", "CYLTabBarItemIdentifier": "me", "CYLTabBarAnimationFilePath": "no_such_animation.pag", "CYLTabBarAnimationOptions": "not a dictionary", "CYLTabBarLottieLoopsWhenUnselected": "maybe"}]}"#),
        // [EN] B22: "android only" and "version 999" are left out on iOS; the other two tabs stay.
        // [CN] B22："仅 Android" 与 "版本 999" 在 iOS 上不显示；其余两个 Tab 保留。
        "Other platforms and newer versions": ("platforms.json", #"{"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home", "CYLTabBarItemImage": "system:house", "CYLTabBarItemIdentifier": "home", "CYLTabBarItemPlatforms": ["ios", "android"]}, {"CYLTabBarItemTitle": "Android only", "CYLTabBarItemIdentifier": "message", "CYLTabBarItemPlatforms": "android"}, {"CYLTabBarItemTitle": "Version 999", "CYLTabBarItemIdentifier": "discover", "CYLTabBarItemMinimumAppVersion": "999.0"}, {"CYLTabBarItemTitle": "Me", "CYLTabBarItemImage": "system:person", "CYLTabBarItemIdentifier": "me", "CYLTabBarItemMinimumAppVersion": "0.1"}]}"#),
        // [EN] B23-B25: a number as platforms, "abc" as a version and a list as page parameters are ignored with warnings.
        // [CN] B23–B25：数字作为平台、"abc" 作为版本、数组作为页面参数，都会被忽略并输出警告。
        "Invalid platforms, versions and parameters": ("invalid_remote.json", #"{"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home", "CYLTabBarItemImage": "system:house", "CYLTabBarItemIdentifier": "home", "CYLTabBarItemPlatforms": 42, "CYLTabBarItemMinimumAppVersion": "abc"}, {"CYLTabBarItemTitle": "Web", "CYLTabBarItemImage": "system:globe", "CYLTabBarItemPageIdentifier": "web", "CYLTabBarItemPageParameters": ["not", "a", "dictionary"], "CYLTabBarItemMinimumAppVersion": "2.x"}]}"#),
        "Invalid URLs and Lottie files": ("urls.json", #"{"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home", "CYLTabBarItemIdentifier": "home", "CYLTabBarItemImage": "system:house", "CYLTabBarItemImageURL": "javascript:alert(1)", "CYLTabBarLottieURL": "ftp://example.com/a.json", "CYLTabBarLottieFilePath": "/no/such/animation.json", "CYLTabBarLottieDarkURL": "no_such_animation.json"}]}"#),
        "Duplicate identifiers": ("ids.json", #"{"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "A", "CYLTabBarItemIdentifier": "tab"}, {"CYLTabBarItemTitle": "B", "CYLTabBarItemIdentifier": "tab"}, {"CYLTabBarItemTitle": "C", "CYLTabBarItemIdentifier": "tab"}]}"#),
        "Misspelled keys": ("typos.json", #"{"CYLTabBarControllerContxt": "typo", "CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitel": "Typo", "CYLTabBarItemTitle": "Home", "CYLTabBarItemIdentifier": "home", "CYLTabBarItemImage": "system:house"}]}"#),
        "Invalid colors and fonts": ("colors.json", ##"{"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home", "CYLTabBarItemIdentifier": "home", "CYLTabBarItemImage": "system:house", "CYLTabBarItemTitleColor": "not a color", "CYLTabBarItemIconColor": "#12345", "CYLTabBarItemSelectedTitleColor": "#FF3B30", "CYLTabBarItemBackgroundColor": 123, "CYLTabBarItemTitleFont": 0, "CYLTabBarItemSelectedTitleFont": "NoSuchFont:12", "CYLTabBarItemAccessibilityLabel": [1, 2]}, {"CYLTabBarItemTitle": "Me", "CYLTabBarItemIdentifier": "me", "CYLTabBarItemImage": "system:person", "CYLTabBarItemTitleFont": "bold:12", "CYLTabBarItemSelectedIconColor": "#34C759"}]}"##),
        "XML external entity": ("xxe.xml", "<?xml version=\"1.0\"?>\n<!DOCTYPE r [<!ENTITY xxe SYSTEM \"file:///etc/passwd\">]>\n<r><CYLTabBarControllerContext>&xxe;</CYLTabBarControllerContext><CYLTabBarControllerTabBarItemsAttributes><item CYLTabBarItemTitle=\"Home\" CYLTabBarItemIdentifier=\"home\" CYLTabBarItemImage=\"system:house\"/></CYLTabBarControllerTabBarItemsAttributes></r>"),
        // [EN] B21: empty URLs, Lottie files, image URLs, colors, fonts and platforms are left out; an empty page ID falls
        //      back to CYLTabBarItemIdentifier; the tabs stay.
        // [CN] B21：空的 URL、Lottie 文件、图片 URL、颜色、字体与平台会被忽略；空的页面 ID 改用 CYLTabBarItemIdentifier；Tab 保留。
        "Empty strings": ("empty_strings.json", #"{"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home", "CYLTabBarItemImage": "system:house", "CYLTabBarLottieURL": "", "CYLTabBarLottieFilePath": "", "CYLTabBarItemImageURL": "", "CYLTabBarItemIdentifier": "home", "CYLTabBarItemPageIdentifier": "", "CYLTabBarItemTitleColor": "", "CYLTabBarItemTitleFont": ""}, {"CYLTabBarItemTitle": "Me", "CYLTabBarItemImage": "system:", "CYLTabBarItemIdentifier": "me", "CYLTabBarItemPlatforms": ""}]}"#),
    ]

    /**
     * [EN] The network cases: (URL string, timeout, cancel), by title. [CN] 网络类情况：（URL 字符串、超时、是否取消），按标题索引。
     */
    static let requests: [String: (url: String, timeout: TimeInterval, cancel: Bool)] = [
        "HTTP 404": ("https://raw.githubusercontent.com/ChenYilong/CYLTabBarController/master/no_such_configuration.json", 0, false),
        "Unknown host": ("https://configuration.cyltabbarcontroller.invalid/tabbar.json", 0, false),
        // [EN] 10.255.255.1 is not routed: the request can only time out. [CN] 10.255.255.1 不可路由：请求只会超时。
        "Server timeout (3 s)": ("https://10.255.255.1/tabbar.json", 3, false),
        "Request cancelled": (CYLConfigurationDemo.sampleURLString, 0, true),
        "An HTML page (network)": ("https://example.com/", 0, false),
        // [EN] C10: a request without a URL gives a FileNotFound error. [CN] C10：没有 URL 的请求返回 FileNotFound 错误。
        "Request without a URL": ("", 0, false),
    ]
}

extension UIViewController {

    /**
     * [EN] The title of the simulated failures section. [CN] 模拟意外情况分组的标题。
     */
    @objc(cyl_configurationEdgeCaseSectionTitle)
    public class func cyl_configurationEdgeCaseSectionTitle() -> String {
        CYLLocalizedString("配置文件：模拟意外情况")
    }

    /**
     * [EN] The number of simulated failures. [CN] 模拟意外情况的数量。
     */
    @objc(cyl_configurationEdgeCaseRowCount)
    public func cyl_configurationEdgeCaseRowCount() -> Int {
        CYLConfigurationEdgeCases.all.count
    }

    private var cyl_configurationEdgeCaseResults: NSMutableDictionary {
        if let results = objc_getAssociatedObject(self, CYLConfigurationEdgeCases.resultsKey) as? NSMutableDictionary {
            return results
        }
        let results = NSMutableDictionary()
        objc_setAssociatedObject(self, CYLConfigurationEdgeCases.resultsKey, results, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return results
    }

    /**
     * [EN] The cell of case `row`: its ID and title, and its last result. [CN] 第 `row` 个情况的 cell：编号与标题，以及最近一次结果。
     */
    @objc(cyl_configurationEdgeCaseCellForTableView:row:)
    public func cyl_configurationEdgeCaseCell(for tableView: UITableView, row: Int) -> UITableViewCell {
        objc_setAssociatedObject(self, CYLConfigurationEdgeCases.tableViewKey, CYLWeakTableView(tableView), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        let identifier = "CYLConfigurationEdgeCaseCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
            cell.textLabel?.font = .systemFont(ofSize: 15)
            cell.detailTextLabel?.textColor = .gray
            cell.detailTextLabel?.numberOfLines = 0
            cell.imageView?.image = UIImage(systemName: "exclamationmark.triangle")
            return cell
        }()
        let cases = CYLConfigurationEdgeCases.all
        let edgeCase = cases.indices.contains(row) ? cases[row] : ("", "")
        cell.textLabel?.text = "\(edgeCase.0) · \(edgeCase.1)"
        cell.detailTextLabel?.text = cyl_configurationEdgeCaseResults[row] as? String
        return cell
    }

    /**
     * [EN] Runs case `row` and shows the outcome in its row and in an alert ("View" opens a created controller).
     * [CN] 执行第 `row` 个情况，并在该行与弹窗中显示结果（“查看”打开创建的控制器）。
     */
    @objc(cyl_runConfigurationEdgeCaseAtRow:)
    public func cyl_runConfigurationEdgeCase(atRow row: Int) {
        CYLConfigurationDemo.registerPages
        let cases = CYLConfigurationEdgeCases.all
        guard cases.indices.contains(row) else { return }
        let (caseID, title) = cases[row]
        let finish: (CYLTabBarController?, NSError?, String) -> Void = { [weak self] tabBarController, error, source in
            self?.cyl_showConfigurationEdgeCaseRow(row, title: "\(caseID) · \(title)", tabBarController: tabBarController, error: error, source: source)
        }
        let fromFile: (String, Data) -> Void = { name, data in
            let path = CYLConfigurationEdgeCases.file(name, data)
            var error: NSError?
            let tabBarController = UIViewController.cyl_tabBarController { try CYLTabBarController(configurationFile: path) } error: { error = $0 }
            let text = String(data: data, encoding: .utf8)
            let shown = text.map { $0.count > 2000 ? String($0.prefix(2000)) + "…" : $0 } ?? "(binary)"
            finish(tabBarController, error, shown)
        }
        if let file = CYLConfigurationEdgeCases.files[title] {
            fromFile(file.name, CYLConfigurationEdgeCases.data(file.text))
            return
        }
        if let request = CYLConfigurationEdgeCases.requests[title] {
            let urlRequest = CYLConfigurationEdgeCases.request(request.url, timeout: request.timeout)
            let task = CYLTabBarController.load(withConfigurationURLRequest: urlRequest) { tabBarController, error in
                finish(tabBarController, error as NSError?, urlRequest.url?.absoluteString ?? "")
            }
            if request.cancel {
                task?.cancel()
            }
            return
        }
        let json = #"{"CYLTabBarControllerTabBarItemsAttributes": "# + CYLConfigurationEdgeCases.tabsJSON + "}"
        switch title {
        case "Empty file":
            fromFile("empty.json", Data())
        case "Not UTF-8":
            fromFile("latin.json", Data([0x7B, 0x22, 0xC3, 0x28, 0x22, 0x3A, 0x31, 0x7D]))
        case "UTF-16 encoded":
            fromFile("utf16.json", Data([0xFF, 0xFE]) + (json.data(using: .utf16LittleEndian) ?? Data()))
        case "A 6 MB file":
            fromFile("huge.json", Data(repeating: 0x20, count: 6 * 1024 * 1024))
        case "Truncated protobuf":
            fromFile("truncated.binpb", Data([0x0A, 0x40, 0x0A, 0x04, 0x48, 0x6F, 0x6D, 0x65]))
        case "Corrupted binary plist":
            var data = (try? PropertyListSerialization.data(fromPropertyList: ["a": [1]], format: .binary, options: 0)) ?? Data()
            if data.count > 9 {
                data[data.count - 9] = 0xFF // [EN] The offset table points past the end. [CN] 偏移表越界。
            }
            fromFile("corrupted.plist", data)
        case "GIF keys and a file that is not a GIF":
            // [EN] B30 (#605): a ".gif" that holds text is refused by its signature; a GIF URL with a size is kept and plays only
            //      with the GIF subspec.
            // [CN] B30（#605）：内容是文本的 ".gif" 因签名不对被拒绝；带尺寸的 GIF URL 保留，只有引入 GIF 子库时才播放。
            let fakeGIF = (NSTemporaryDirectory() as NSString).appendingPathComponent("not_a_gif.gif")
            try? CYLConfigurationEdgeCases.data("this is not a GIF").write(to: URL(fileURLWithPath: fakeGIF), options: .atomic)
            let gifJSON = #"{"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home", "CYLTabBarItemImage": "system:house", "CYLTabBarItemIdentifier": "home", "CYLTabBarGIFFilePath": ""# + fakeGIF + #""}, {"CYLTabBarItemTitle": "Me", "CYLTabBarItemImage": "system:person", "CYLTabBarItemIdentifier": "me", "CYLTabBarGIFURL": "https://example.com/tab_me.gif", "CYLTabBarGIFSize": "{30, 30}"}]}"#
            fromFile("gif.json", CYLConfigurationEdgeCases.data(gifJSON))
        case "Two tab bars, one page ID":
            cyl_presentTwoTabBarsDemo()
            cyl_configurationEdgeCaseResults[row] = CYLLocalizedString("两个 TabBar 使用同一份配置，各自的注册表把相同的页面 ID 对应到不同页面。")
        case "Missing file":
            var error: NSError?
            let tabBarController = UIViewController.cyl_tabBarController { try CYLTabBarController(configurationFile: "no_such_configuration.yaml") } error: { error = $0 }
            finish(tabBarController, error, "no_such_configuration.yaml")
        case "Created on a background thread":
            let path = CYLConfigurationEdgeCases.file("background.json", CYLConfigurationEdgeCases.data(json))
            DispatchQueue.global(qos: .utility).async {
                var error: NSError?
                let tabBarController = UIViewController.cyl_tabBarController { try CYLTabBarController(configurationFile: path) } error: { error = $0 }
                DispatchQueue.main.async { finish(tabBarController, error, json) }
            }
        case "Localized texts (tables in the sandbox)":
            cyl_runLocalizedTextsCase(finish)
        default:
            cyl_runCodeEdgeCase(title, finish)
        }
    }

    /**
     * [EN] The cases built in code, without a configuration file. [CN] 用代码构造、不经配置文件的情况。
     */
    private func cyl_runCodeEdgeCase(_ title: String, _ finish: @escaping (CYLTabBarController?, NSError?, String) -> Void) {
        let twoTabs = CYLConfigurationEdgeCases.twoTabs
        switch title {
        case "A page provider raises (code)":
            let registry = CYLTabBarPageRegistry()
            registry.register({ _, _ in
                NSException(name: .internalInconsistencyException, reason: "a provider that raises").raise()
                return nil
            }, forPageIdentifier: "raises")
            finish(CYLTabBarController(configuration: [
                CYLTabBarControllerPageRegistry: registry,
                CYLTabBarControllerTabBarItemsAttributes: [[CYLTabBarItemTitle: "Raises", CYLTabBarItemPageIdentifier: "raises"],
                                                           [CYLTabBarItemTitle: "Home", CYLTabBarItemIdentifier: "home"]],
            ]), nil, "provider of \"raises\": [NSException raise:...]")
        case "Pages that cannot be tabs (code)":
            // [EN] C13: nil, a string, a tab bar controller, a page inside another navigation controller and one page for two
            //      tabs are refused; only "home" stays.
            // [CN] C13：nil、字符串、TabBarController、已在其他导航控制器中的页面、两个 Tab 共用一个页面都会被拒绝；只保留 "home"。
            let shared = UIViewController()
            let owner = UINavigationController(rootViewController: UIViewController())
            // [EN] A string where a page is expected, as Objective-C code could return it. [CN] 在需要页面的位置返回字符串，与 Objective-C 代码可能的写法相同。
            let notAPage = unsafeBitCast("not a page" as NSString, to: UIViewController.self)
            let pages: [String: () -> UIViewController?] = [
                "nil": { nil }, "string": { notAPage }, "tabBar": { UITabBarController() },
                "owned": { owner.viewControllers.first }, "sharedA": { shared }, "sharedB": { shared },
            ]
            let resolver: CYLTabBarPageProvider = { pageIdentifier, _ in pages[pageIdentifier]?() ?? nil }
            let attributes = ["nil", "string", "tabBar", "owned", "sharedA", "sharedB", "home"].map {
                [CYLTabBarItemTitle: $0, CYLTabBarItemPageIdentifier: $0]
            }
            finish(CYLTabBarController(configuration: [CYLTabBarControllerPageResolver: resolver, CYLTabBarControllerTabBarItemsAttributes: attributes]),
                   nil, "CYLTabBarControllerPageResolver: nil, a string, a UITabBarController, a page inside a UINavigationController, one page for two tabs")
        case "Reload with new tabs (code)":
            // [EN] B27: `-reloadTabBarItemsWithAttributes:` creates the page of "message", reuses the page of "home" (same
            //      object, state kept) and skips "no_such_page".
            // [CN] B27：`-reloadTabBarItemsWithAttributes:` 创建 "message" 的页面、复用 "home" 的页面（同一对象，状态保留）、跳过 "no_such_page"。
            let tabBarController = CYLTabBarController(configuration: [CYLTabBarControllerTabBarItemsAttributes: twoTabs])
            let home = tabBarController.viewControllers?.first
            tabBarController.reloadTabBarItems(withAttributes: [
                [CYLTabBarItemTitle: "Message", CYLTabBarItemImage: "system:message", CYLTabBarItemIdentifier: "message"],
                [CYLTabBarItemTitle: "Home", CYLTabBarItemImage: "system:house", CYLTabBarItemIdentifier: "home"],
                [CYLTabBarItemTitle: "Unknown", CYLTabBarItemPageIdentifier: "no_such_page"],
            ])
            let viewControllers = tabBarController.viewControllers ?? []
            let reused = viewControllers.count > 1 && viewControllers[1] === home
            finish(tabBarController, nil, "[tabBarController reloadTabBarItemsWithAttributes:@[message, home, no_such_page]]\n// home page reused: \(reused ? "YES" : "NO")")
        case "Asynchronous pages (code)":
            // [EN] C20: "later" delivers its page after 2 s, "never" delivers nil after 2 s (the tab is removed); the completion
            //      is called twice and off the main thread on purpose.
            // [CN] C20："later" 在 2 秒后交付页面，"never" 在 2 秒后交付 nil（该 Tab 被移除）；故意在非主线程调用两次 completion。
            let registry = CYLTabBarPageRegistry()
            registry.register(asyncFactory: { request, completion in
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 2) {
                    var page: UIViewController?
                    if request.pageIdentifier == "later" {
                        DispatchQueue.main.sync {
                            page = UIViewController()
                            page?.title = request.title
                            page?.view.backgroundColor = .systemGreen
                        }
                    }
                    completion(page)
                    completion(page)
                }
                return nil
            }, forPageIdentifiers: ["later", "never"])
            finish(CYLTabBarController(configuration: [
                CYLTabBarControllerPageRegistry: registry,
                CYLTabBarControllerTabBarItemsAttributes: [
                    [CYLTabBarItemTitle: "Later", CYLTabBarItemImage: "system:clock", CYLTabBarItemPageIdentifier: "later"],
                    [CYLTabBarItemTitle: "Home", CYLTabBarItemImage: "system:house", CYLTabBarItemIdentifier: "home"],
                    [CYLTabBarItemTitle: "Never", CYLTabBarItemImage: "system:xmark", CYLTabBarItemPageIdentifier: "never"],
                ],
            ]), nil, "registerAsyncPageFactory: \"later\" -> a page after 2 s, \"never\" -> nil after 2 s (the tab is removed)")
        case "Non-controllers and duplicates (code)":
            let page = UIViewController()
            finish(CYLTabBarController(configuration: [
                CYLTabBarControllerViewControllers: ["not a view controller", page, page],
                CYLTabBarControllerTabBarItemsAttributes: twoTabs,
            ]), nil, #"CYLTabBarControllerViewControllers : @[ @"not a view controller", page, page ]"#)
        case "Configuration is not a dictionary (code)":
            // [EN] An array where a dictionary is expected, as Objective-C code could pass it. [CN] 在需要字典的位置传入数组，与 Objective-C 代码可能的写法相同。
            let make = CYLTabBarController.perform(NSSelectorFromString("tabBarControllerWithConfiguration:"), with: [1, 2] as NSArray)
            finish(make?.takeUnretainedValue() as? CYLTabBarController, nil, "[CYLTabBarController tabBarControllerWithConfiguration:@[ @1, @2 ]]")
        case "Empty view controller list (code)":
            finish(CYLTabBarController(configuration: [CYLTabBarControllerViewControllers: [UIViewController](),
                                                       CYLTabBarControllerTabBarItemsAttributes: twoTabs]),
                   nil, "CYLTabBarControllerViewControllers : @[]")
        default:
            break
        }
    }

    /**
     * [EN] L1: the app writes its tables into the sandbox, as if downloaded, and the configuration names them with a location
     *      route (docs/Configuration-Localization.md). The titles follow the library's language; a language without a table
     *      falls back to English.
     * [CN] L1：App 把字符串表写入沙盒（如同下载），配置用位置路由指定它们（docs/Configuration-Localization.md）。标题跟随本库语言；没有
     *      字符串表的语言回退到英文。
     */
    private func cyl_runLocalizedTextsCase(_ finish: (CYLTabBarController?, NSError?, String) -> Void) {
        let caches = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? NSTemporaryDirectory()
        let folder = (caches as NSString).appendingPathComponent("CYLConfigurationLocalizationDemo")
        let tables = [
            "en": "\"demo.home\" = \"Home (localized)\";\n\"demo.me\" = \"Me (localized)\";\n",
            "zh-Hans": "\"demo.home\" = \"首页（本地化）\";\n\"demo.me\" = \"我的（本地化）\";\n",
            "ja": "\"demo.home\" = \"ホーム（ローカライズ）\";\n\"demo.me\" = \"マイページ（ローカライズ）\";\n",
        ]
        for (language, table) in tables {
            let lproj = (folder as NSString).appendingPathComponent(language + ".lproj")
            try? FileManager.default.createDirectory(atPath: lproj, withIntermediateDirectories: true)
            try? table.write(toFile: (lproj as NSString).appendingPathComponent("Tabs.strings"), atomically: true, encoding: .utf8)
        }
        let text = #"{"CYLTabBarControllerLocalization": {"CYLTabBarLocalizationTableName": "Tabs", "CYLTabBarLocalizationPath": "sandbox:Caches/CYLConfigurationLocalizationDemo"},"#
            + "\n" + #" "CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "demo.home", "CYLTabBarItemImage": "system:house", "CYLTabBarItemIdentifier": "home"},"#
            + #" {"CYLTabBarItemTitle": "demo.me", "CYLTabBarItemImage": "system:person", "CYLTabBarItemIdentifier": "me"}]}"#
        let path = (folder as NSString).appendingPathComponent("localized.json")
        try? CYLConfigurationEdgeCases.data(text).write(to: URL(fileURLWithPath: path), options: .atomic)
        var error: NSError?
        let tabBarController = UIViewController.cyl_tabBarController { try CYLTabBarController(configurationFile: path) } error: { error = $0 }
        finish(tabBarController, error, text)
    }

    private func cyl_showConfigurationEdgeCaseRow(_ row: Int, title: String, tabBarController: CYLTabBarController?, error: NSError?,
                                                  source: String) {
        var result: String
        if let tabBarController {
            result = "✅ " + String(format: CYLLocalizedString("已安全创建 TabBarController：%@ 个 Tab"),
                                   NSNumber(value: tabBarController.viewControllers?.count ?? 0))
        } else {
            result = "❌ \(error?.localizedDescription ?? "") (\(error?.code ?? 0))"
        }
        if let skipped = tabBarController?.cyl_skippedTabs, !skipped.isEmpty {
            // [EN] The tabs that got no page, with the reason (docs/Tab-Page-Registry.md). [CN] 没有页面的 Tab 及原因（docs/Tab-Page-Registry.md）。
            let names = skipped.map { "\($0.title ?? $0.pageIdentifier ?? "?") (\(CYLConfigurationEdgeCases.name(of: $0.reason)))" }
            result += "\n" + String(format: CYLLocalizedString("跳过 %1$@ 个 Tab：%2$@"), NSNumber(value: names.count), names.joined(separator: ", "))
        }
        cyl_configurationEdgeCaseResults[row] = result
        if let tableView = (objc_getAssociatedObject(self, CYLConfigurationEdgeCases.tableViewKey) as? CYLWeakTableView)?.tableView,
           tableView.window != nil {
            tableView.reloadData()
        }
        guard view.window != nil, presentedViewController == nil else { return }
        let alert = UIAlertController(title: title, message: result, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: CYLLocalizedString("关闭"), style: .cancel))
        if let tabBarController, (tabBarController.viewControllers?.count ?? 0) > 0 {
            alert.addAction(UIAlertAction(title: CYLLocalizedString("查看"), style: .default) { [weak self] _ in
                self?.cyl_presentConfigurationDemoTabBarController(tabBarController, source: title, sourceText: source, error: nil)
            })
        }
        present(alert, animated: true)
    }

    /**
     * [EN] C16: two tab bar controllers on one screen, from the same configuration: each passes its own CYLTabBarPageRegistry,
     *      so the same page IDs ("home", "me") give different pages (blue and orange).
     * [CN] C16：同一屏幕上的两个 TabBarController，由同一份配置创建：各自传入自己的 CYLTabBarPageRegistry，因此相同的页面 ID（"home"、"me"）
     *      得到不同的页面（蓝色与橙色）。
     */
    private func cyl_presentTwoTabBarsDemo() {
        let container = UIViewController()
        container.view.backgroundColor = .systemBackground
        var views: [UIView] = []
        for (index, color) in [UIColor.systemBlue, UIColor.systemOrange].enumerated() {
            let name = index == 0 ? "Tab bar A" : "Tab bar B"
            let registry = CYLTabBarPageRegistry()
            registry.register({ pageIdentifier, _ in
                let page = UIViewController()
                page.view.backgroundColor = color.withAlphaComponent(0.25)
                let label = UILabel()
                label.text = "\(name) · page ID \"\(pageIdentifier)\""
                label.translatesAutoresizingMaskIntoConstraints = false
                page.view.addSubview(label)
                NSLayoutConstraint.activate([label.centerXAnchor.constraint(equalTo: page.view.centerXAnchor),
                                             label.centerYAnchor.constraint(equalTo: page.view.centerYAnchor)])
                return page
            }, forPageIdentifiers: ["home", "me"])
            let tabBarController = CYLTabBarController(configuration: [
                CYLTabBarControllerTabBarItemsAttributes: CYLConfigurationEdgeCases.twoTabs,
                CYLTabBarControllerPageRegistry: registry,
                CYLTabBarControllerContext: name,
            ])
            container.addChild(tabBarController)
            tabBarController.view.translatesAutoresizingMaskIntoConstraints = false
            container.view.addSubview(tabBarController.view)
            tabBarController.didMove(toParent: container)
            views.append(tabBarController.view)
        }
        let safeArea = container.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            views[0].topAnchor.constraint(equalTo: safeArea.topAnchor),
            views[0].leadingAnchor.constraint(equalTo: container.view.leadingAnchor),
            views[0].trailingAnchor.constraint(equalTo: container.view.trailingAnchor),
            views[1].topAnchor.constraint(equalTo: views[0].bottomAnchor, constant: 8),
            views[1].heightAnchor.constraint(equalTo: views[0].heightAnchor),
            views[1].leadingAnchor.constraint(equalTo: container.view.leadingAnchor),
            views[1].trailingAnchor.constraint(equalTo: container.view.trailingAnchor),
            views[1].bottomAnchor.constraint(equalTo: container.view.bottomAnchor),
        ])
        let navigationController = UINavigationController(rootViewController: container)
        container.navigationItem.title = CYLLocalizedString("两个 TabBar，同一个页面 ID")
        container.navigationItem.leftBarButtonItem = UIBarButtonItem(title: CYLLocalizedString("关闭"), style: .plain, target: navigationController,
                                                                     action: #selector(UIViewController.cyl_dismissConfigurationDemo))
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
}

/**
 * [EN] The table view of the edge case rows, held weakly. [CN] 意外情况各行所在的 table view（弱引用）。
 */
final class CYLWeakTableView: NSObject {
    weak var tableView: UITableView?
    init(_ tableView: UITableView) { self.tableView = tableView }
}

/**
 * [EN] C14: registered automatically under "auto" by adopting CYLTabBarPage. [CN] C14：遵守 CYLTabBarPage，自动注册为 "auto"。
 */
@objc(CYLConfigurationDemoAutoPage)
final class CYLConfigurationDemoAutoPage: UIViewController, CYLTabBarPage {
    static func cylTabBarPageIdentifier() -> String { "auto" }

    static func cylTabBarPage(attributes tabAttributes: [String: Any]) -> UIViewController? {
        CYLConfigurationDemo.page(CYLConfigurationDemo.title(cylTabBarPageIdentifier(), tabAttributes),
                                  "\(NSStringFromClass(self))\n+cylTabBarPageIdentifier = \"\(cylTabBarPageIdentifier())\"\n(CYLTabBarPage, no registration code)")
    }
}

/**
 * [EN] C14: two classes claim "conflict"; the first in class name order (A) is used, with a warning.
 * [CN] C14：两个类都声明 "conflict"；按类名顺序使用第一个（A），并输出警告。
 */
@objc(CYLConfigurationDemoConflictPageA)
final class CYLConfigurationDemoConflictPageA: UIViewController, CYLTabBarPage {
    static func cylTabBarPageIdentifier() -> String { "conflict" }

    static func cylTabBarPage(attributes tabAttributes: [String: Any]) -> UIViewController? {
        CYLConfigurationDemo.page(CYLConfigurationDemo.title(cylTabBarPageIdentifier(), tabAttributes),
                                  "\(NSStringFromClass(self))\n(used: first in class name order)")
    }
}

@objc(CYLConfigurationDemoConflictPageB)
final class CYLConfigurationDemoConflictPageB: UIViewController, CYLTabBarPage {
    static func cylTabBarPageIdentifier() -> String { "conflict" }
}
