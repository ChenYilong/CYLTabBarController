package com.cyl.tabbar

import android.content.Context
import androidx.annotation.RestrictTo
import java.util.concurrent.ConcurrentHashMap

/**
 * [EN] The module's resources found by name, never through a module `R` class: the React Native and Flutter components
 *      compile these sources into their own namespace (`com.cyl.tabbar`), where `com.cyl.animateditem.R` does not exist,
 *      while every build merges the resources into the app. Ids are cached for the process.
 * [CN] 按名称查找本模块的资源，而不是通过模块的 `R` 类：React Native 与 Flutter 组件把这些源码编译进自己的命名空间（`com.cyl.tabbar`），其中没有
 *      `com.cyl.animateditem.R`；而所有构建都会把资源合并进 App。id 在进程内缓存。
 */
@RestrictTo(RestrictTo.Scope.LIBRARY_GROUP)
object CYLAnimatedItemResources {
    private val ids = ConcurrentHashMap<String, Int>()

    /**
     * [EN] The resource id of `name` of `type`, 0 when the app has none. [CN] 类型为 `type`、名称为 `name` 的资源 id；App 中没有时为 0。
     */
    @JvmStatic
    // [EN] By name on purpose (see the class comment); cached, so it runs once per name. [CN] 有意按名称查找（见类注释）；已缓存，每个名称只查一次。
    @android.annotation.SuppressLint("DiscouragedApi")
    fun id(context: Context, name: String, type: String = "id"): Int =
        ids.getOrPut("$type/$name") { context.resources.getIdentifier(name, type, context.packageName) }
}

/**
 * [EN] `setTag` with a tag key found by name; a missing key (0) stores nothing. [CN] 以按名称查找的 key 调用 `setTag`；找不到 key（0）时不保存。
 */
internal fun android.view.View.cyl_setTag(name: String, value: Any?) {
    val key = CYLAnimatedItemResources.id(context, name)
    if (key != 0) setTag(key, value)
}

/**
 * [EN] `getTag` with a tag key found by name. [CN] 以按名称查找的 key 调用 `getTag`。
 */
internal fun android.view.View.cyl_getTag(name: String): Any? {
    val key = CYLAnimatedItemResources.id(context, name)
    return if (key != 0) getTag(key) else null
}
