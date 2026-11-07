package com.cyl.tabbar.demo

import android.graphics.Color
import android.os.Handler
import android.os.Looper
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import com.cyl.tabbar.CYLConstants
import com.cyl.tabbar.CYLTabBarConfiguration
import com.cyl.tabbar.CYLTabBarConfigurationParser
import com.cyl.tabbar.CYLTabBarController
import com.cyl.tabbar.CYLTabBarPageProvider
import com.cyl.tabbar.CYLTabBarPageRegistry
import java.io.File

/**
 * [EN] The "Configuration file" group (docs/Configuration-File.md): a tab bar controller from each sample file shared with
 *      iOS (or from the network URL), then one row per simulated failure, the same cases and IDs as the iOS
 *      `UIViewController+CYLConfigurationDemo` (A2 to E1). Each row shows its result: the tabs created, the tabs skipped
 *      and why, or the error and its code.
 * [CN] "配置文件" 分组（docs/Configuration-File.md）：由与 iOS 共用的每个示例文件（或网络 URL）创建 TabBarController，然后每个模拟意外情况一行，
 *      用例与编号与 iOS 的 `UIViewController+CYLConfigurationDemo` 相同（A2 到 E1）。每行显示结果：创建的 Tab、跳过的 Tab 及原因，或错误及其代码。
 */
object DemoConfiguration {
    const val SAMPLE_URL = "https://raw.githubusercontent.com/ChenYilong/CYLTabBarController/master/CYLTabBarController/Resources/CYLTabBarController.bundle/Configurations/cyl_tabbar_configuration.yaml"
    private const val TABS = """[{"CYLTabBarItemTitle": "Home", "CYLTabBarItemImage": "system:house", "CYLTabBarItemIdentifier": "home"}, {"CYLTabBarItemTitle": "Me", "CYLTabBarItemImage": "system:person", "CYLTabBarItemIdentifier": "me"}]"""
    private const val JSON = """{"CYLTabBarControllerTabBarItemsAttributes": $TABS}"""

    private val results = HashMap<String, String>()
    private val main = Handler(Looper.getMainLooper())

    /** [EN] The cases: ID, title, how to run it. [CN] 用例：编号、标题、执行方式。 */
    private class EdgeCase(val id: String, val title: String, val run: DemoListFragment.(finish: (CYLTabBarController?, Exception?) -> Unit) -> Unit)

    fun rows(): List<DemoRow> = listOf(DemoRow("A tab bar controller from a configuration file", { "Every sample file shared with iOS (JSON, JSON5, YAML, TOML, plist, XML, INI, properties, protobuf...), or the network URL" }) {
        presentConfigurationDemo(this)
    }) + edgeCases.map { edgeCase ->
        val key = edgeCase.id + edgeCase.title
        DemoRow("${edgeCase.id} · ${edgeCase.title}", { results[key] }) {
            DemoPages.registerOnce()
            edgeCase.run(this) { controller, error ->
                results[key] = describe(controller, error)
                if (isAdded) reload()
            }
        }
    }

    private fun describe(controller: CYLTabBarController?, error: Exception?): String {
        if (controller == null) {
            val code = (error as? CYLTabBarConfiguration.CYLConfigurationException)?.error?.let { "${it.name} (${it.code})" } ?: error?.javaClass?.simpleName
            return "❌ ${error?.message} · $code"
        }
        var result = "✅ A tab bar controller was created safely: ${controller.viewControllers.size} tabs"
        if (controller.cyl_skippedTabs.isNotEmpty()) {
            result += "\nSkipped ${controller.cyl_skippedTabs.size} tabs: " + controller.cyl_skippedTabs.joinToString(", ") { skipped ->
                "${skipped.tab?.title ?: skipped.pageId ?: "?"} (${skipped.reason.name.lowercase().replace('_', ' ')})"
            }
        }
        return result
    }

    // MARK: - The sample files 示例文件

    private fun presentConfigurationDemo(page: DemoListFragment) {
        DemoPages.registerOnce()
        val extensions = CYLTabBarConfigurationParser.supportedPathExtensions()
        val files = page.requireContext().assets.list("").orEmpty().filter { name -> extensions.contains(name.substringAfterLast('.', "").lowercase()) }.sorted()
        page.choose("Choose a configuration file", files + "Load from the network URL") { index ->
            if (index < files.size) {
                val file = files[index]
                val result = runCatching { CYLTabBarController.tabBarControllerWithConfigurationFile(page.requireActivity(), file) }
                result.exceptionOrNull()?.let { page.showMessage(file, it.message ?: it.javaClass.simpleName) }
                    ?: DemoHostActivity.openTabBar(page.requireContext(), file) { activity -> CYLTabBarController.tabBarControllerWithConfigurationFile(activity, file) }
            } else {
                // [EN] Downloaded first, so a failure shows an alert instead of an empty screen. [CN] 先下载，失败时弹窗而不是空白界面。
                CYLTabBarController.loadConfigurationWithURL(SAMPLE_URL) { configuration, error ->
                    if (configuration == null) page.showMessage(SAMPLE_URL, error?.message ?: "no configuration")
                    else DemoHostActivity.openTabBar(page.requireContext(), "URL") { activity -> CYLTabBarController(activity, configuration) }
                }
            }
        }
    }

    // MARK: - Simulated failures 模拟意外情况

    private fun DemoListFragment.fromFile(name: String, data: ByteArray, finish: (CYLTabBarController?, Exception?) -> Unit) {
        val directory = File(requireContext().cacheDir, "CYLConfigurationEdgeCases").apply { mkdirs() }
        val file = File(directory, name).apply { writeBytes(data) }
        try {
            finish(CYLTabBarController.tabBarControllerWithConfigurationFile(requireActivity(), file.absolutePath), null)
        } catch (error: Exception) {
            finish(null, error)
        }
    }

    private fun DemoListFragment.fromURL(url: String, timeout: Double, finish: (CYLTabBarController?, Exception?) -> Unit) {
        val activity = requireActivity()
        CYLTabBarController.loadTabBarControllerWithConfigurationURLRequest(activity, CYLTabBarConfiguration.CYLURLRequest(url, timeout)) { controller, error -> finish(controller, error) }
    }

    private fun DemoListFragment.fromCode(configuration: Map<String, Any?>, finish: (CYLTabBarController?, Exception?) -> Unit) {
        try {
            finish(CYLTabBarController(requireActivity(), configuration), null)
        } catch (error: Exception) {
            finish(null, error)
        }
    }

    private fun text(value: String) = value.toByteArray(Charsets.UTF_8)

    private fun tabs(vararg identifiers: String): List<Map<String, Any?>> = identifiers.map { identifier ->
        mapOf(CYLConstants.CYLTabBarItemTitle to identifier.replaceFirstChar { it.uppercase() }, CYLConstants.CYLTabBarItemImage to "system:house", CYLConstants.CYLTabBarItemIdentifier to identifier)
    }

    private val edgeCases: List<EdgeCase> = listOf(
        EdgeCase("A3", "Empty file") { finish -> fromFile("empty.json", ByteArray(0), finish) },
        EdgeCase("A4", "Comments only") { finish -> fromFile("comments.yaml", text("# nothing but comments\n"), finish) },
        EdgeCase("A13", "Malformed JSON") { finish -> fromFile("malformed.json", text("""{"CYLTabBarControllerTabBarItemsAttributes": [ {"CYLTabBarItemTitle": "Home" """), finish) },
        EdgeCase("A11", "Top level is a list") { finish -> fromFile("list.json", text(TABS), finish) },
        EdgeCase("A7", "YAML in a .json file") { finish ->
            fromFile("yaml.json", text("CYLTabBarControllerTabBarItemsAttributes:\n  - CYLTabBarItemTitle: Home\n    CYLTabBarItemImage: system:house\n    CYLTabBarItemIdentifier: home\n  - CYLTabBarItemTitle: Me\n    CYLTabBarItemImage: system:person\n    CYLTabBarItemIdentifier: me\n"), finish)
        },
        EdgeCase("A5", "Not UTF-8") { finish -> fromFile("latin.json", byteArrayOf('{'.code.toByte(), '"'.code.toByte(), 0xC3.toByte(), 0x28, '"'.code.toByte(), ':'.code.toByte(), '1'.code.toByte(), '}'.code.toByte()), finish) },
        EdgeCase("A16", "UTF-16 encoded") { finish -> fromFile("utf16.json", byteArrayOf(0xFF.toByte(), 0xFE.toByte()) + JSON.toByteArray(Charsets.UTF_16LE), finish) },
        EdgeCase("A10", "Nested 10,000 levels") { finish -> fromFile("deep.json", text("""{"CYLTabBarControllerTabBarItemsAttributes": ${"[".repeat(10000)}${"]".repeat(10000)}}"""), finish) },
        EdgeCase("A9", "A 6 MB file") { finish -> fromFile("huge.json", ByteArray(6 * 1024 * 1024) { ' '.code.toByte() }, finish) },
        EdgeCase("B1", "No tabs") { finish -> fromFile("no_tabs.json", text("""{"CYLTabBarControllerContext": "NoTabs"}"""), finish) },
        EdgeCase("D7", "An HTML page (file)") { finish -> fromFile("portal.xml", text("<html><head><title>Wi-Fi</title></head><body><form>Accept</form></body></html>"), finish) },
        EdgeCase("B5", "Wrong types and null") { finish ->
            fromFile("types.json", text("""{"CYLTabBarControllerContext": [1, 2], "CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": ["a", "list"], "CYLTabBarItemImage": null, "CYLTabBarItemIdentifier": 7, "CYLTabBarItemPageIdentifier": "home"}, "not a tab", {"CYLTabBarItemTitle": 42, "CYLTabBarItemImage": {"a": 1}, "CYLTabBarItemIdentifier": "me"}]}"""), finish)
        },
        EdgeCase("B7", "NaN and Infinity insets") { finish ->
            fromFile("nan.yaml", text("CYLTabBarControllerImageInsets: \"{nan, 0, 0, 0}\"\nCYLTabBarControllerTitlePositionAdjustment: [1e999, -3]\nCYLTabBarControllerTabBarItemsAttributes:\n  - CYLTabBarItemTitle: Home\n    CYLTabBarItemIdentifier: home\n    CYLTabBarItemImage: system:house\n    CYLTabBarItemImageInsets: \"{inf, 0, -inf, 0}\"\n    CYLTabBarLottieSize: \"{-24, 0}\"\n"), finish)
        },
        EdgeCase("B9", "Unknown style") { finish ->
            fromFile("style.toml", text("CYLTabBarControllerStyleType = 99\n[[CYLTabBarControllerTabBarItemsAttributes]]\nCYLTabBarItemTitle = \"Home\"\nCYLTabBarItemIdentifier = \"home\"\nCYLTabBarItemImage = \"system:house\"\n"), finish)
        },
        EdgeCase("C11", "Unregistered page IDs") { finish ->
            fromFile("unregistered.json", text("""{"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home", "CYLTabBarItemImage": "system:house", "CYLTabBarItemIdentifier": "home"}, {"CYLTabBarItemTitle": "Unknown", "CYLTabBarItemPageIdentifier": "no_such_page"}, {"CYLTabBarItemTitle": "No ID"}]}"""), finish)
        },
        EdgeCase("C12", "A page provider raises (code)") { finish ->
            val registry = CYLTabBarPageRegistry().apply { registerPageProvider({ _, _ -> throw IllegalStateException("a provider that raises") }, "raises") }
            fromCode(mapOf(CYLConstants.CYLTabBarControllerPageRegistry to registry,
                CYLConstants.CYLTabBarControllerTabBarItemsAttributes to listOf(mapOf(CYLConstants.CYLTabBarItemTitle to "Raises", CYLConstants.CYLTabBarItemPageIdentifier to "raises")) + tabs("home")), finish)
        },
        EdgeCase("C13", "Pages that cannot be tabs (code)") { finish ->
            val shared: Fragment = TextPageFragment.newInstance("shared")
            val pages = mapOf<String, () -> Fragment?>("nil" to { null }, "sharedA" to { shared }, "sharedB" to { shared })
            val resolver: CYLTabBarPageProvider = { id, _ -> pages[id]?.invoke() ?: if (id == "home") TextPageFragment.newInstance("home") else null }
            fromCode(mapOf(CYLConstants.CYLTabBarControllerPageResolver to resolver,
                CYLConstants.CYLTabBarControllerTabBarItemsAttributes to listOf("nil", "sharedA", "sharedB", "home").map { mapOf(CYLConstants.CYLTabBarItemTitle to it, CYLConstants.CYLTabBarItemPageIdentifier to it) }), finish)
        },
        EdgeCase("C14", "Automatic registration (TabPageFactory)") { finish ->
            fromFile("automatic.json", text("""{"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Auto", "CYLTabBarItemImage": "system:star", "CYLTabBarItemPageIdentifier": "auto"}, {"CYLTabBarItemTitle": "Conflict", "CYLTabBarItemPageIdentifier": "conflict"}]}"""), finish)
        },
        EdgeCase("C15", "Registry and resolver of wrong types") { finish ->
            fromFile("wrong_registry.json", text("""{"CYLTabBarControllerPageRegistry": "MyRegistry", "CYLTabBarControllerPageResolver": "resolve:", "CYLTabBarControllerTabBarItemsAttributes": $TABS}"""), finish)
        },
        EdgeCase("C16", "Two tab bars, one page ID") { finish ->
            startActivity(android.content.Intent(requireContext(), TwoTabBarsActivity::class.java))
            finish(null, null)
            results["C16Two tab bars, one page ID"] = "Two tab bars use one configuration; their own registries map the same page IDs to different pages."
        },
        EdgeCase("C18", "Lookup order and automatic registration") { finish ->
            fromFile("lookup_order.json", text("""{"CYLTabBarControllerPageLookupOrder": "shared, bogus", "CYLTabBarControllerAutomaticPageRegistration": "no", "CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home", "CYLTabBarItemImage": "system:house", "CYLTabBarItemIdentifier": "home"}, {"CYLTabBarItemTitle": "Auto", "CYLTabBarItemPageIdentifier": "auto"}, {"CYLTabBarItemTitle": "Maybe", "CYLTabBarItemPageIdentifier": "maybe"}]}"""), finish)
        },
        EdgeCase("B22", "Other platforms and newer versions") { finish ->
            fromFile("platforms.json", text("""{"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home", "CYLTabBarItemImage": "system:house", "CYLTabBarItemIdentifier": "home", "CYLTabBarItemPlatforms": ["ios", "android"]}, {"CYLTabBarItemTitle": "iOS only", "CYLTabBarItemIdentifier": "message", "CYLTabBarItemPlatforms": "ios"}, {"CYLTabBarItemTitle": "Version 999", "CYLTabBarItemIdentifier": "discover", "CYLTabBarItemMinimumAppVersion": "999.0"}, {"CYLTabBarItemTitle": "Me", "CYLTabBarItemImage": "system:person", "CYLTabBarItemIdentifier": "me", "CYLTabBarItemMinimumAppVersion": "0.1"}]}"""), finish)
        },
        EdgeCase("B23", "Invalid platforms, versions and parameters") { finish ->
            fromFile("invalid_remote.json", text("""{"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home", "CYLTabBarItemImage": "system:house", "CYLTabBarItemIdentifier": "home", "CYLTabBarItemPlatforms": 42, "CYLTabBarItemMinimumAppVersion": "abc"}, {"CYLTabBarItemTitle": "Web", "CYLTabBarItemImage": "system:globe", "CYLTabBarItemPageIdentifier": "web", "CYLTabBarItemPageParameters": ["not", "a", "dictionary"], "CYLTabBarItemMinimumAppVersion": "2.x"}]}"""), finish)
        },
        EdgeCase("B27", "Reload with new tabs (code)") { finish ->
            val controller = CYLTabBarController(requireActivity(), mapOf(CYLConstants.CYLTabBarControllerTabBarItemsAttributes to tabs("home", "me")))
            val home = controller.viewControllers.firstOrNull()
            controller.reloadTabBarItemsWithAttributes(tabs("message", "home") + listOf(mapOf(CYLConstants.CYLTabBarItemTitle to "Unknown", CYLConstants.CYLTabBarItemPageIdentifier to "no_such_page")))
            finish(controller, null)
            results["B27Reload with new tabs (code)"] += "\nhome page reused: ${controller.viewControllers.getOrNull(1) === home}"
        },
        EdgeCase("C20", "Asynchronous pages (code)") { finish ->
            val registry = CYLTabBarPageRegistry().apply {
                registerAsyncPageFactory({ request, completion ->
                    Thread {
                        Thread.sleep(2000)
                        val page = if (request.pageIdentifier == "later") TextPageFragment.newInstance("Later", background = Color.GREEN) else null
                        completion(page)
                        completion(page)
                    }.start()
                    null
                }, listOf("later", "never"))
            }
            fromCode(mapOf(CYLConstants.CYLTabBarControllerPageRegistry to registry,
                CYLConstants.CYLTabBarControllerTabBarItemsAttributes to listOf(
                    mapOf(CYLConstants.CYLTabBarItemTitle to "Later", CYLConstants.CYLTabBarItemImage to "system:clock", CYLConstants.CYLTabBarItemPageIdentifier to "later"),
                    mapOf(CYLConstants.CYLTabBarItemTitle to "Home", CYLConstants.CYLTabBarItemImage to "system:house", CYLConstants.CYLTabBarItemIdentifier to "home"),
                    mapOf(CYLConstants.CYLTabBarItemTitle to "Never", CYLConstants.CYLTabBarItemImage to "system:star", CYLConstants.CYLTabBarItemPageIdentifier to "never"))), finish)
        },
        EdgeCase("B28", "Animation keys, options and speed") { finish ->
            fromFile("animation.json", text("""{"CYLTabBarControllerTabBarItemAnimationSpeed": "fast", "CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home", "CYLTabBarItemImage": "system:house", "CYLTabBarItemIdentifier": "home", "CYLTabBarRiveURL": "https://example.com/icons.riv", "CYLTabBarAnimationOptions": {"artboard": "HOME", "input": "active", "duration": 2, "bad": [1, 2]}}, {"CYLTabBarItemTitle": "Me", "CYLTabBarItemImage": "system:person", "CYLTabBarItemIdentifier": "me", "CYLTabBarAnimationFilePath": "no_such_animation.pag", "CYLTabBarAnimationOptions": "not a dictionary", "CYLTabBarLottieLoopsWhenUnselected": "maybe"}]}"""), finish)
        },
        EdgeCase("B30", "GIF keys and a file that is not a GIF") { finish ->
            val fake = File(requireContext().cacheDir, "not_a_gif.gif").apply { writeText("this is not a GIF") }
            fromFile("gif.json", text("""{"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home", "CYLTabBarItemImage": "system:house", "CYLTabBarItemIdentifier": "home", "CYLTabBarGIFFilePath": "${fake.absolutePath}"}, {"CYLTabBarItemTitle": "Me", "CYLTabBarItemImage": "system:person", "CYLTabBarItemIdentifier": "me", "CYLTabBarGIFURL": "https://example.com/tab_me.gif", "CYLTabBarGIFSize": "{30, 30}"}]}"""), finish)
        },
        EdgeCase("B13", "Invalid URLs and Lottie files") { finish ->
            fromFile("urls.json", text("""{"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home", "CYLTabBarItemIdentifier": "home", "CYLTabBarItemImage": "system:house", "CYLTabBarItemImageURL": "javascript:alert(1)", "CYLTabBarLottieURL": "ftp://example.com/a.json", "CYLTabBarLottieFilePath": "/no/such/animation.json", "CYLTabBarLottieDarkURL": "no_such_animation.json"}]}"""), finish)
        },
        EdgeCase("B12", "Duplicate identifiers") { finish ->
            fromFile("ids.json", text("""{"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "A", "CYLTabBarItemIdentifier": "tab"}, {"CYLTabBarItemTitle": "B", "CYLTabBarItemIdentifier": "tab"}, {"CYLTabBarItemTitle": "C", "CYLTabBarItemIdentifier": "tab"}]}"""), finish)
        },
        EdgeCase("B11", "Misspelled keys") { finish ->
            fromFile("typos.json", text("""{"CYLTabBarControllerContxt": "typo", "CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitel": "Typo", "CYLTabBarItemTitle": "Home", "CYLTabBarItemIdentifier": "home", "CYLTabBarItemImage": "system:house"}]}"""), finish)
        },
        EdgeCase("B19", "Invalid colors and fonts") { finish ->
            fromFile("colors.json", text("""{"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home", "CYLTabBarItemIdentifier": "home", "CYLTabBarItemImage": "system:house", "CYLTabBarItemTitleColor": "not a color", "CYLTabBarItemIconColor": "#12345", "CYLTabBarItemSelectedTitleColor": "#FF3B30", "CYLTabBarItemBackgroundColor": 123, "CYLTabBarItemTitleFont": 0, "CYLTabBarItemSelectedTitleFont": "NoSuchFont:12", "CYLTabBarItemAccessibilityLabel": [1, 2]}, {"CYLTabBarItemTitle": "Me", "CYLTabBarItemIdentifier": "me", "CYLTabBarItemImage": "system:person", "CYLTabBarItemTitleFont": "bold:12", "CYLTabBarItemSelectedIconColor": "#34C759"}]}"""), finish)
        },
        EdgeCase("B21", "Empty strings") { finish ->
            fromFile("empty_strings.json", text("""{"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home", "CYLTabBarItemImage": "system:house", "CYLTabBarLottieURL": "", "CYLTabBarLottieFilePath": "", "CYLTabBarItemImageURL": "", "CYLTabBarItemIdentifier": "home", "CYLTabBarItemPageIdentifier": "", "CYLTabBarItemTitleColor": "", "CYLTabBarItemTitleFont": ""}, {"CYLTabBarItemTitle": "Me", "CYLTabBarItemImage": "system:", "CYLTabBarItemIdentifier": "me", "CYLTabBarItemPlatforms": ""}]}"""), finish)
        },
        EdgeCase("A12", "Truncated protobuf") { finish -> fromFile("truncated.binpb", byteArrayOf(0x0A, 0x40, 0x0A, 0x04, 'H'.code.toByte(), 'o'.code.toByte(), 'm'.code.toByte(), 'e'.code.toByte()), finish) },
        EdgeCase("A12", "Corrupted binary plist") { finish ->
            // [EN] "bplist00", a one-entry dictionary, and an offset table that points past the end. [CN] "bplist00"、一个条目的字典，以及越界的偏移表。
            val data = text("bplist00") + byteArrayOf(0xD1.toByte(), 0x01, 0x02, 0x51, 'a'.code.toByte(), 0xA1.toByte(), 0x03, 0x10, 0x01, 0x08, 0x0B, 0xFF.toByte(), 0x0F) +
                ByteArray(6) + byteArrayOf(0x01, 0x01) + ByteArray(7) + byteArrayOf(0x04) + ByteArray(7) + ByteArray(1) + ByteArray(7) + byteArrayOf(0x11)
            fromFile("corrupted.plist", data, finish)
        },
        EdgeCase("A14", "XML external entity") { finish ->
            fromFile("xxe.xml", text("<?xml version=\"1.0\"?>\n<!DOCTYPE r [<!ENTITY xxe SYSTEM \"file:///etc/passwd\">]>\n<r><CYLTabBarControllerContext>&xxe;</CYLTabBarControllerContext><CYLTabBarControllerTabBarItemsAttributes><item CYLTabBarItemTitle=\"Home\" CYLTabBarItemIdentifier=\"home\" CYLTabBarItemImage=\"system:house\"/></CYLTabBarControllerTabBarItemsAttributes></r>"), finish)
        },
        EdgeCase("A2", "Missing file") { finish ->
            try { finish(CYLTabBarController.tabBarControllerWithConfigurationFile(requireActivity(), "no_such_configuration.yaml"), null) } catch (error: Exception) { finish(null, error) }
        },
        EdgeCase("E1", "Created on a background thread") { finish ->
            val activity: FragmentActivity = requireActivity()
            val file = File(requireContext().cacheDir, "background.json").apply { writeText(JSON) }
            Thread {
                // [EN] Parsing off the main thread; the controller (views) is made on the main thread, as Android requires. [CN] 在非主线程解析；控制器（视图）按 Android 要求在主线程创建。
                val configuration = runCatching { CYLTabBarController.configurationWithContentsOfFile(activity, file.absolutePath) }
                main.post {
                    configuration.fold({ finish(CYLTabBarController(activity, it), null) }, { finish(null, it as? Exception) })
                }
            }.start()
        },
        EdgeCase("C6", "Non-pages and duplicates (code)") { finish ->
            val page = TextPageFragment.newInstance("page")
            fromCode(mapOf(CYLConstants.CYLTabBarControllerViewControllers to listOf("not a page", page, page),
                CYLConstants.CYLTabBarControllerTabBarItemsAttributes to tabs("home", "me")), finish)
        },
        EdgeCase("B18", "Configuration is not a dictionary (code)") { finish ->
            // [EN] Kotlin's types refuse a list at compile time; the closest is a map whose keys are not strings. [CN] Kotlin 的类型在编译期拒绝列表；最接近的是键不是字符串的 map。
            @Suppress("UNCHECKED_CAST")
            fromCode(mapOf(1 to 2) as Map<String, Any?>, finish)
        },
        EdgeCase("C9", "Empty page list (code)") { finish ->
            fromCode(mapOf(CYLConstants.CYLTabBarControllerViewControllers to emptyList<Fragment>(), CYLConstants.CYLTabBarControllerTabBarItemsAttributes to tabs("home", "me")), finish)
        },
        EdgeCase("D3", "HTTP 404") { finish -> fromURL("https://raw.githubusercontent.com/ChenYilong/CYLTabBarController/master/no_such_configuration.json", 15.0, finish) },
        EdgeCase("D4", "Unknown host") { finish -> fromURL("https://configuration.cyltabbarcontroller.invalid/tabbar.json", 15.0, finish) },
        // [EN] 10.255.255.1 is not routed, so the request can only time out (the same address as the iOS case). [CN] 10.255.255.1 不可路由，请求只会超时（与 iOS 用例相同的地址）。
        EdgeCase("D5", "Server timeout (3 s)") { finish -> fromURL("https://10.255.255.1/tabbar.json", 3.0, finish) }, // NOSONAR kotlin:S1313: a deliberately unreachable address
        EdgeCase("D10", "Request cancelled") { finish ->
            // [EN] Android's loader returns no task to cancel: the caller drops the result, which is what a cancelled request gives. [CN] Android 的加载方法不返回可取消的任务：调用方丢弃结果，与取消请求的效果相同。
            var cancelled = false
            fromURL(SAMPLE_URL, 15.0) { _, _ -> if (!cancelled) finish(null, IllegalStateException("not cancelled")) }
            cancelled = true
            finish(null, java.util.concurrent.CancellationException("The request was cancelled; its result is ignored"))
        },
        EdgeCase("C10", "Request without a URL") { finish -> fromURL("", 15.0, finish) },
        EdgeCase("D7", "An HTML page (network)") { finish -> fromURL("https://example.com/", 15.0, finish) },
    )

    /** [EN] The number of simulated failures (the same as iOS). [CN] 模拟意外情况的数量（与 iOS 相同）。 */
    val edgeCaseCount: Int get() = edgeCases.size
}
