package com.cyl.tabbar

import android.content.Context
import java.io.File

/**
 * [EN] Resource routes, as `CYLResourceRoute` on iOS (docs/Resource-Routes.md): one string that says where a resource is
 *      (a configuration file, a folder of string tables…), built into the app or in its sandbox (e.g. downloaded at run
 *      time). The prefix decides, in this order: "bundle:<path>" the assets, "sandbox:Documents/<path>" `filesDir`,
 *      "sandbox:Caches/<path>" and "sandbox:tmp/<path>" `cacheDir`, "sandbox:<path>" the app's data folder, "file:" URL,
 *      "/…" absolute, "~/…" the app's data folder, anything else relative to `baseDirectory` (a configuration file's
 *      folder: a path, or "asset:<folder>"), else the assets.
 *      A query picks one file in that folder: `name`, and optionally `theme`, `version` and `format`, for files named
 *      `{name}[-{theme}][@{version}].{format}`. Without `version` the highest one wins; without `format` any format the
 *      configuration parser reads, preferring JSON, YAML, plist, XML, TOML, then the others.
 *      The library never ships these resources: string tables and configuration files belong to the app.
 * [CN] 资源路由，与 iOS 的 `CYLResourceRoute` 相同（docs/Resource-Routes.md）：用一个字符串说明资源（配置文件、字符串表所在目录等）的位置，
 *      可以是 App 内置资源，也可以在沙盒中（例如运行时下载）。按以下顺序由前缀判断："bundle:<路径>" assets，"sandbox:Documents/<路径>"
 *      `filesDir`，"sandbox:Caches/<路径>" 与 "sandbox:tmp/<路径>" `cacheDir`，"sandbox:<路径>" App 数据目录，"file:" URL，"/…" 绝对路径，
 *      "~/…" App 数据目录，其余相对于 `baseDirectory`（配置文件所在目录：路径或 "asset:<目录>"），否则相对于 assets。
 *      查询参数在该目录中选出唯一的文件：`name`，以及可选的 `theme`、`version`、`format`，对应文件名 `{name}[-{theme}][@{version}].{format}`。
 *      不写 `version` 时取最高版本；不写 `format` 时为配置解析器支持的任意格式，依次优先 JSON、YAML、plist、XML、TOML，再到其他格式。
 *      本库从不内置这些资源：字符串表与配置文件属于 App。
 */
object CYLResourceRoute {
    /**
     * [EN] The prefix of a folder in the assets, for `baseDirectory`. [CN] `baseDirectory` 中表示 assets 目录的前缀。
     */
    const val ASSET_PREFIX = "asset:"

    /**
     * [EN] Where a route leads: a path in the assets, or a file on disk. [CN] 路由指向的位置：assets 中的路径，或磁盘上的文件。
     */
    class Location(val assetPath: String?, val file: File?) {
        /**
         * [EN] A path `configurationWithContentsOfFile` reads (a file path or an asset name). [CN] `configurationWithContentsOfFile` 可读取的路径（文件路径或 asset 名称）。
         */
        val path: String get() = file?.path ?: assetPath.orEmpty()
    }

    /**
     * [EN] The extensions in the order a route without `format` prefers them; the same as iOS. [CN] 不写 `format` 时的扩展名优先顺序，与 iOS 相同。
     */
    internal val formats = listOf(
        "json", "json5", "jsonc", "yaml", "yml", "plist", "xml", "toml", "ini", "cfg", "conf", "properties",
        "env", "textproto", "txtpb", "pbtxt", "prototxt", "binpb", "pb", "protobuf", "strings",
    )

    private val formatGroups = listOf(
        listOf("yaml", "yml"), listOf("json5", "jsonc"), listOf("ini", "cfg", "conf"), listOf("properties", "env"),
        listOf("textproto", "txtpb", "pbtxt", "prototxt"), listOf("binpb", "pb", "protobuf"),
    )

    /**
     * [EN] The local path of `route` (see `Location.path`), or null when it is empty or its query matches no file. [CN] `route` 的本地路径；为空或查询参数没有匹配的文件时为 null。
     */
    @JvmStatic
    @JvmOverloads
    fun pathForRoute(context: Context, route: String, baseDirectory: String? = null): String? = locationForRoute(context, route, baseDirectory)?.path

    /**
     * [EN] Where `route` leads; without a query whether it exists or not. [CN] `route` 指向的位置；没有查询参数时无论是否存在都返回。
     */
    @JvmStatic
    @JvmOverloads
    fun locationForRoute(context: Context, route: String, baseDirectory: String? = null): Location? {
        val trimmed = route.trim()
        if (trimmed.isEmpty()) return null
        val location = locationOf(context, trimmed.substringBefore('?'), baseDirectory)
        if ('?' !in trimmed) return location
        val query = queryItems(trimmed.substringAfter('?'))
        val name = query["name"]?.takeIf { it.isNotEmpty() } ?: return null
        val names = location.file?.list()?.toList()
            ?: try { context.assets.list(location.assetPath.orEmpty())?.toList() } catch (error: java.io.IOException) { null }
            ?: return null
        val file = pickFile(names, name, query["theme"], query["version"], query["format"]) ?: return null
        return location.file?.let { Location(null, File(it, file)) } ?: Location(join(location.assetPath.orEmpty(), file), null)
    }

    /**
     * [EN] The location of a route without its query. [CN] 不含查询参数的路由对应的位置。
     */
    private fun locationOf(context: Context, location: String, baseDirectory: String?): Location {
        val dataFolder = context.filesDir.parentFile ?: context.filesDir
        return when {
            location.startsWith("bundle:") -> Location(location.removePrefix("bundle:").trim('/'), null)
            location.startsWith("sandbox:") -> {
                val rest = location.removePrefix("sandbox:").trimStart('/')
                val remainder = if ('/' in rest) rest.substringAfter('/') else ""
                when (rest.substringBefore('/')) {
                    "Documents" -> Location(null, File(context.filesDir, remainder))
                    "Caches", "tmp" -> Location(null, File(context.cacheDir, remainder))
                    else -> Location(null, File(dataFolder, rest))
                }
            }
            location.startsWith("file:") -> Location(null, File(runCatching { java.net.URI(location).path }.getOrNull() ?: location.removePrefix("file:")))
            location.startsWith("~/") -> Location(null, File(dataFolder, location.removePrefix("~/")))
            location.startsWith("/") -> Location(null, File(location))
            baseDirectory != null && baseDirectory.startsWith(ASSET_PREFIX) -> Location(join(baseDirectory.removePrefix(ASSET_PREFIX), location), null)
            !baseDirectory.isNullOrEmpty() -> Location(null, File(baseDirectory, location))
            else -> Location(location.trim('/'), null)
        }
    }

    private fun queryItems(query: String): Map<String, String> = query.split('&').mapNotNull { pair ->
        val key = pair.substringBefore('=').trim().lowercase()
        val value = java.net.URLDecoder.decode(pair.substringAfter('=', ""), "UTF-8")
        if (key.isEmpty() || value.isEmpty()) null else key to value
    }.toMap()

    /**
     * [EN] `folder/path` with "." and ".." resolved (assets have no "..", so "Manifests/../Skins" is "Skins"). [CN] 解析 "." 与 ".." 后的 `folder/path`（assets 不支持 ".."）。
     */
    private fun join(folder: String, path: String): String {
        val parts = ArrayList<String>()
        for (part in "$folder/$path".split('/')) {
            when (part) {
                "", "." -> Unit
                ".." -> if (parts.isNotEmpty()) parts.removeAt(parts.size - 1)
                else -> parts.add(part)
            }
        }
        return parts.joinToString("/")
    }

    /**
     * [EN] "1.10" > "1.9": numeric parts compare as numbers. [CN] "1.10" > "1.9"：数字部分按数值比较。
     */
    internal fun compareVersions(first: String, second: String): Int {
        val a = first.split('.')
        val b = second.split('.')
        for (index in 0 until maxOf(a.size, b.size)) {
            val x = a.getOrNull(index) ?: return -1
            val y = b.getOrNull(index) ?: return 1
            val order = when {
                x.toLongOrNull() != null && y.toLongOrNull() != null -> x.toLong().compareTo(y.toLong())
                else -> x.compareTo(y)
            }
            if (order != 0) return order
        }
        return 0
    }

    /**
     * [EN] A file name split as {name}[-{theme}][@{version}].{extension}. [CN] 按 {name}[-{theme}][@{version}].{extension} 拆分的文件名。
     */
    private class CYLRouteCandidate(val file: String, val theme: String?, val version: String?, val extension: String)

    /**
     * [EN] `file` split after `name`; null when it is not one of `name`'s files. [CN] 以 `name` 拆分 `file`；不属于 `name` 时为 null。
     */
    private fun candidate(file: String, name: String): CYLRouteCandidate? {
        if (file.startsWith(".") || '.' !in file) return null
        // [EN] {name}[-{theme}][@{version}]: the version after the last "@", the theme after "-". [CN] 版本位于最后一个 "@" 之后，主题位于 "-" 之后。
        val stem = file.substringBeforeLast('.')
        if (!stem.startsWith(name)) return null
        var rest = stem.removePrefix(name)
        val version = if ('@' in rest) rest.substringAfterLast('@') else null
        if (version != null) rest = rest.substringBeforeLast('@')
        val theme = when {
            rest.isEmpty() -> null
            rest.startsWith("-") -> rest.substring(1)
            else -> return null
        }
        return CYLRouteCandidate(file, theme, version, file.substringAfterLast('.').lowercase())
    }

    /**
     * [EN] The candidate has the theme and version the query asks for. [CN] 候选文件符合查询要求的主题与版本。
     */
    private fun matches(candidate: CYLRouteCandidate, theme: String?, version: String?): Boolean {
        val themeMatches = if (theme.isNullOrEmpty()) candidate.theme.isNullOrEmpty() else candidate.theme == theme
        val versionMatches = version.isNullOrEmpty() || (candidate.version != null && compareVersions(candidate.version, version) == 0)
        return themeMatches && versionMatches
    }

    /**
     * [EN] `candidate` beats `best`: the newer version, then the preferred format. [CN] `candidate` 优于 `best`：版本更新，其次格式更优先。
     */
    private fun isBetter(candidate: CYLRouteCandidate, best: CYLRouteCandidate?): Boolean {
        if (best == null) return true
        val order = when {
            best.version != null && candidate.version != null -> compareVersions(candidate.version, best.version)
            candidate.version != null -> 1
            best.version != null -> -1
            else -> 0
        }
        return order > 0 || (order == 0 && formats.indexOf(candidate.extension) < formats.indexOf(best.extension))
    }

    /**
     * [EN] The file of `names` that matches, as the route query. [CN] `names` 中与查询参数匹配的文件。
     */
    @JvmStatic
    fun pickFile(names: List<String>, name: String, theme: String?, version: String?, format: String?): String? {
        val extensions = format?.takeIf { it.isNotEmpty() }?.lowercase()?.let { wanted -> formatGroups.firstOrNull { wanted in it } ?: listOf(wanted) } ?: formats
        var best: CYLRouteCandidate? = null
        for (file in names) {
            val candidate = candidate(file, name) ?: continue
            if (candidate.extension in extensions && matches(candidate, theme, version) && isBetter(candidate, best)) best = candidate
        }
        return best?.file
    }
}
