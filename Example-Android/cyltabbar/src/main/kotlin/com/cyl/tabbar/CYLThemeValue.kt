/*
 * [EN] Adapted from QMUI_Android's skin system (QMUISkinValueBuilder, QMUISkinManager dispatch, IQMUISkinRuleHandler and its
 *      handlers, QMUISkinLayoutInflaterFactory, IQMUISkinHandlerSpan, IQMUISkinHandlerDecoration,
 *      IQMUISkinDispatchInterceptor; https://github.com/Tencent/QMUI_Android), under the MIT License:
 * [CN] 改编自 QMUI_Android 的换肤体系（QMUISkinValueBuilder、QMUISkinManager 的分发、IQMUISkinRuleHandler 及其实现、
 *      QMUISkinLayoutInflaterFactory、IQMUISkinHandlerSpan、IQMUISkinHandlerDecoration、IQMUISkinDispatchInterceptor；
 *      https://github.com/Tencent/QMUI_Android），遵循 MIT 许可证：
 *
 * Tencent is pleased to support the open source community by making QMUI_Android available.
 * Copyright (C) 2017-2018 THL A29 Limited, a Tencent company. All rights reserved.
 * Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at http://opensource.org/licenses/MIT
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
 * an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 */
// [EN] The method names use the library's `cyl_` prefix, see docs/Android-API-Map.md. [CN] 方法名使用库的 `cyl_` 前缀，见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100", "kotlin:S117")

package com.cyl.tabbar

import android.app.Activity
import android.app.Dialog
import android.content.Context
import android.content.res.ColorStateList
import android.content.res.Resources
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.Drawable
import android.graphics.drawable.GradientDrawable
import android.text.Spanned
import android.text.TextPaint
import android.text.style.CharacterStyle
import android.text.style.UpdateAppearance
import android.util.AttributeSet
import android.util.TypedValue
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.Window
import android.widget.CompoundButton
import android.widget.ImageView
import android.widget.PopupWindow
import android.widget.ProgressBar
import android.widget.TextView
import androidx.annotation.ColorInt
import androidx.annotation.StyleRes
import androidx.fragment.app.Fragment
import java.lang.ref.WeakReference
import java.lang.reflect.Constructor
import java.lang.reflect.Method
import java.util.concurrent.ConcurrentHashMap

/*
 * [EN] Android only (no iOS counterpart): theme values. A view names, per rule ("background", "textColor", …), a value of the
 *      current theme; every theme change applies the rules again. The value names are looked up in the theme of
 *      `CYLThemeManagerCenter.defaultThemeManager` (or `View.cyl_themeValueManager`):
 *      - a `CYLThemeStyle(R.style.X)`: the theme attribute of that name (`?attr/name`), as QMUI skins are styles;
 *      - a `Map` (e.g. from a configuration file): its entry (a color Int, "#RRGGBB", a ColorStateList, a Drawable, a
 *        number, a `CYLThemeColor` or `CYLThemeImage`);
 *      - a `CYLThemeValueProviding`: its answer;
 *      - no theme: the attribute of the view's own context theme.
 *      Views get rules in code (`cyl_themeValue`, `CYLThemeValueBuilder`) or in layouts (`app:cyl_themeTextColor="title"`,
 *      read by the factory of `CYLThemeValues.installLayoutInflaterFactory`).
 * [CN] 仅 Android（iOS 无对应 API）：主题值。视图按规则（"background"、"textColor" 等）指定当前主题中的一个值；每次主题变化都重新应用这些规则。
 *      值名称在 `CYLThemeManagerCenter.defaultThemeManager`（或 `View.cyl_themeValueManager`）的当前主题中查找：
 *      - `CYLThemeStyle(R.style.X)`：同名主题属性（`?attr/name`），与 QMUI 皮肤即 style 一致；
 *      - `Map`（例如来自配置文件）：对应条目（颜色整数、"#RRGGBB"、ColorStateList、Drawable、数字、`CYLThemeColor` 或 `CYLThemeImage`）；
 *      - `CYLThemeValueProviding`：其返回值；
 *      - 没有主题：视图自身 context 主题中的属性。
 *      视图在代码中（`cyl_themeValue`、`CYLThemeValueBuilder`）或布局中（`app:cyl_themeTextColor="title"`，由
 *      `CYLThemeValues.installLayoutInflaterFactory` 的 factory 读取）设置规则。
 */

/** [EN] Android only: a theme that is an Android style; value names are its theme attributes. [CN] 仅 Android：以 Android style 表示的主题；值名称为其主题属性。 */
data class CYLThemeStyle(@param:StyleRes val styleRes: Int)

/** [EN] Android only: a theme object that answers value names itself. [CN] 仅 Android：自行返回值名称对应值的主题对象。 */
fun interface CYLThemeValueProviding {
    fun cyl_themeValueForName(name: String, context: Context): Any?
}

/**
 * [EN] Android only, QMUI `QMUISkinValueBuilder`: builds the "rule:name|rule:name" string of `View.cyl_themeValue`.
 * [CN] 仅 Android，QMUI 的 `QMUISkinValueBuilder`：构建 `View.cyl_themeValue` 的 "rule:name|rule:name" 字符串。
 */
class CYLThemeValueBuilder {
    private val values = LinkedHashMap<String, String>()

    fun background(name: String) = custom(BACKGROUND, name)
    fun bgTintColor(name: String) = custom(BG_TINT_COLOR, name)
    fun textColor(name: String) = custom(TEXT_COLOR, name)
    fun hintColor(name: String) = custom(HINT_COLOR, name)
    fun linkColor(name: String) = custom(LINK_COLOR, name)
    fun src(name: String) = custom(SRC, name)
    fun tintColor(name: String) = custom(TINT_COLOR, name)
    fun alpha(name: String) = custom(ALPHA, name)
    fun border(name: String) = custom(BORDER, name)
    fun progressColor(name: String) = custom(PROGRESS_COLOR, name)
    fun textCompoundTintColor(name: String) = custom(TEXT_COMPOUND_TINT_COLOR, name)
    fun textCompoundLeftSrc(name: String) = custom(TEXT_COMPOUND_LEFT_SRC, name)
    fun textCompoundTopSrc(name: String) = custom(TEXT_COMPOUND_TOP_SRC, name)
    fun textCompoundRightSrc(name: String) = custom(TEXT_COMPOUND_RIGHT_SRC, name)
    fun textCompoundBottomSrc(name: String) = custom(TEXT_COMPOUND_BOTTOM_SRC, name)

    /** [EN] A rule of `CYLThemeValues.setRuleHandler`, or a built-in one. [CN] `CYLThemeValues.setRuleHandler` 注册的规则，或内置规则。 */
    fun custom(rule: String, name: String): CYLThemeValueBuilder = apply {
        val key = rule.trim()
        val value = name.trim().removePrefix("?attr/").removePrefix("?")
        if (key.isNotEmpty() && value.isNotEmpty()) values[key] = value
    }

    /** [EN] `convertFrom`: adds the rules of a "rule:name|rule:name" string. [CN] 添加 "rule:name|rule:name" 字符串中的规则。 */
    fun convertFrom(value: String?): CYLThemeValueBuilder = apply {
        value?.split('|')?.forEach { item ->
            val parts = item.split(':')
            if (parts.size == 2) custom(parts[0], parts[1])
        }
    }

    fun isEmpty(): Boolean = values.isEmpty()
    fun clear() = values.clear()
    /** [EN] The rules, in the order they were added. [CN] 按添加顺序的规则。 */
    fun rules(): Map<String, String> = LinkedHashMap(values)
    fun build(): String = values.entries.joinToString("|") { "${it.key}:${it.value}" }

    companion object {
        const val BACKGROUND = "background"
        const val BG_TINT_COLOR = "bgTintColor"
        const val TEXT_COLOR = "textColor"
        const val HINT_COLOR = "hintColor"
        const val LINK_COLOR = "linkColor"
        const val SRC = "src"
        const val TINT_COLOR = "tintColor"
        const val ALPHA = "alpha"
        const val BORDER = "border"
        const val PROGRESS_COLOR = "progressColor"
        const val TEXT_COMPOUND_TINT_COLOR = "tcTintColor"
        const val TEXT_COMPOUND_LEFT_SRC = "tclSrc"
        const val TEXT_COMPOUND_TOP_SRC = "tctSrc"
        const val TEXT_COMPOUND_RIGHT_SRC = "tcrSrc"
        const val TEXT_COMPOUND_BOTTOM_SRC = "tcbSrc"
    }
}

/**
 * [EN] Android only: a value of the current theme, read as the type a rule needs (null when it cannot be).
 * [CN] 仅 Android：当前主题中的一个值，按规则需要的类型读取（无法转换时为 null）。
 */
class CYLThemeValue internal constructor(val name: String, val raw: Any?, private val context: Context, private val theme: Resources.Theme?) {
    @get:ColorInt
    val color: Int? get() = when (val raw = raw) {
        is CYLThemeColor -> raw.cyl_rawColor
        is Int -> raw
        is Long -> raw.toInt()
        is String -> runCatching { Color.parseColor(raw) }.getOrNull()
        is ColorStateList -> raw.defaultColor
        is ColorDrawable -> raw.color
        is TypedValue -> typedColor(raw)
        else -> null
    }

    val colorStateList: ColorStateList? get() = when (val raw = raw) {
        is ColorStateList -> raw
        is TypedValue -> if (raw.resourceId != 0) runCatching { context.resources.getColorStateList(raw.resourceId, theme) }.getOrNull() ?: color?.let { ColorStateList.valueOf(it) }
                         else color?.let { ColorStateList.valueOf(it) }
        else -> color?.let { ColorStateList.valueOf(it) }
    }

    val drawable: Drawable? get() = when (val raw = raw) {
        is CYLThemeImage -> raw as? Drawable
        is Drawable -> raw.constantState?.newDrawable(context.resources)?.mutate() ?: raw
        is TypedValue -> if (raw.type in TypedValue.TYPE_FIRST_COLOR_INT..TypedValue.TYPE_LAST_COLOR_INT) ColorDrawable(raw.data)
                         else if (raw.resourceId != 0) runCatching { androidx.core.content.res.ResourcesCompat.getDrawable(context.resources, raw.resourceId, theme) }.getOrNull() else null
        else -> color?.let { ColorDrawable(it) }
    }

    val float: Float? get() = when (val raw = raw) {
        is Number -> raw.toFloat()
        is String -> raw.toFloatOrNull()
        is TypedValue -> when (raw.type) {
            TypedValue.TYPE_FLOAT -> raw.float
            TypedValue.TYPE_DIMENSION -> TypedValue.complexToDimension(raw.data, context.resources.displayMetrics)
            TypedValue.TYPE_FRACTION -> raw.getFraction(1f, 1f)
            in TypedValue.TYPE_FIRST_INT..TypedValue.TYPE_LAST_INT -> raw.data.toFloat()
            else -> null
        }
        else -> null
    }

    private fun typedColor(value: TypedValue): Int? = when {
        value.type in TypedValue.TYPE_FIRST_COLOR_INT..TypedValue.TYPE_LAST_COLOR_INT -> value.data
        value.resourceId != 0 -> runCatching { context.resources.getColor(value.resourceId, theme) }.getOrNull()
        else -> null
    }
}

/** [EN] Android only, QMUI `IQMUISkinRuleHandler`: applies one rule's value to a view. [CN] 仅 Android，QMUI 的 `IQMUISkinRuleHandler`：把一条规则的值应用到视图。 */
fun interface CYLThemeRuleHandler {
    fun cyl_applyThemeValue(view: View, rule: String, value: CYLThemeValue)
}

/** [EN] Android only, QMUI `IQMUISkinDispatchInterceptor`: a view that returns true keeps a theme change from itself and its subviews. [CN] 仅 Android：返回 true 的视图让主题变化不再分发到自身及子视图。 */
fun interface CYLThemeDispatchInterceptor {
    fun cyl_interceptThemeDispatch(manager: CYLThemeManager, identifier: Any?, theme: Any?): Boolean
}

/** [EN] Android only, QMUI `IQMUISkinHandlerSpan`: a span of a `TextView`'s text told about theme changes. [CN] 仅 Android：`TextView` 文本中会收到主题变化通知的 span。 */
fun interface CYLThemeSpan {
    fun cyl_themeDidChange(view: TextView, manager: CYLThemeManager?)
}

/**
 * [EN] Android only, QMUI `IQMUISkinHandlerDecoration`: implement it on a `RecyclerView.ItemDecoration`; a theme change
 *      tells it (the RecyclerView is found by reflection, so the library does not depend on it) and redraws the list.
 * [CN] 仅 Android：在 `RecyclerView.ItemDecoration` 上实现它；主题变化时通知它并重绘列表（通过反射找到 RecyclerView，库不依赖它）。
 */
fun interface CYLThemeItemDecoration {
    fun cyl_themeDidChange(recyclerView: ViewGroup, manager: CYLThemeManager?)
}

/** [EN] Android only: a text color span that follows the theme value `name` (QMUI's skin spans). [CN] 仅 Android：跟随主题值 `name` 的文字颜色 span（QMUI 的换肤 span）。 */
class CYLThemeColorSpan(val name: String, @param:ColorInt private var color: Int = Color.BLACK) : CharacterStyle(), UpdateAppearance, CYLThemeSpan {
    override fun updateDrawState(paint: TextPaint) { paint.color = color }

    override fun cyl_themeDidChange(view: TextView, manager: CYLThemeManager?) {
        CYLThemeValues.value(view.context, name, manager ?: view.cyl_themeValueManager)?.color?.let { color = it }
    }
}

// MARK: - View properties 视图属性

/**
 * [EN] Android only: the theme rules of the view, "rule:name|rule:name" (e.g. "background:surface|textColor:title"), applied
 *      now and on every theme change. null removes them.
 * [CN] 仅 Android：视图的主题规则 "rule:name|rule:name"（例如 "background:surface|textColor:title"），立即应用，并在每次主题变化时应用。null 移除。
 */
var View.cyl_themeValue: String?
    get() = getTag(R.id.cyl_theme_value) as? String
    set(value) {
        setTag(R.id.cyl_theme_value, value?.takeIf { it.isNotBlank() })
        setTag(R.id.cyl_theme_value_applied, null)
        if (value.isNullOrBlank()) return
        CYLThemeValues.watchAttach(this)
        CYLThemeValues.applyThemeValues(this, force = true)
    }

/** [EN] Android only: sets `cyl_themeValue` from a builder. [CN] 仅 Android：用构建器设置 `cyl_themeValue`。 */
fun View.cyl_setThemeValue(builder: CYLThemeValueBuilder) { cyl_themeValue = builder.build() }

/** [EN] Android only: the manager whose theme the view's values follow (default: `CYLThemeManagerCenter.defaultThemeManager`). [CN] 仅 Android：视图主题值跟随的管理器（默认 `CYLThemeManagerCenter.defaultThemeManager`）。 */
var View.cyl_themeValueManager: CYLThemeManager
    get() = (getTag(R.id.cyl_theme_attach_listener) as? CYLThemeValues.AttachState)?.manager ?: CYLThemeManagerCenter.defaultThemeManager
    set(value) {
        CYLThemeValues.watchAttach(this).manager = value
        CYLThemeValues.applyThemeValues(this, force = true)
    }

/** [EN] Android only, QMUI `setInterceptSkinDispatch`: true keeps theme changes from this view and its subviews. [CN] 仅 Android：true 时主题变化不再分发到本视图及子视图。 */
var View.cyl_interceptsThemeDispatch: Boolean
    get() = getTag(R.id.cyl_theme_intercept_dispatch) == true
    set(value) = setTag(R.id.cyl_theme_intercept_dispatch, value.takeIf { it })

/** [EN] Android only, QMUI `setIgnoreSkinApply`: true skips this view itself, still reaching its subviews. [CN] 仅 Android：true 时跳过本视图自身，仍分发到子视图。 */
var View.cyl_ignoresThemeApply: Boolean
    get() = getTag(R.id.cyl_theme_ignore_apply) == true
    set(value) = setTag(R.id.cyl_theme_ignore_apply, value.takeIf { it })

/**
 * [EN] Android only: theme values, rule handlers, the layout inflater factory and the registered roots (QMUI `register`).
 * [CN] 仅 Android：主题值、规则处理器、布局 inflater factory 与登记的根对象（QMUI 的 `register`）。
 */
object CYLThemeValues {
    private val ruleHandlers = ConcurrentHashMap<String, CYLThemeRuleHandler>()
    private val styleThemes = HashMap<Pair<Resources, Int>, Resources.Theme>()
    private val attributeIds = ConcurrentHashMap<String, Int>()

    internal class AttachState(var manager: CYLThemeManager) : View.OnAttachStateChangeListener {
        override fun onViewAttachedToWindow(v: View) = applyThemeValues(v, force = false)
        override fun onViewDetachedFromWindow(v: View) = Unit
    }

    /** [EN] A newly attached view (a list cell, a dialog) catches up with the current theme. [CN] 新附加到窗口的视图（列表 cell、对话框）跟上当前主题。 */
    internal fun watchAttach(view: View): AttachState {
        (view.getTag(R.id.cyl_theme_attach_listener) as? AttachState)?.let { return it }
        return AttachState(CYLThemeManagerCenter.defaultThemeManager).also { state ->
            view.setTag(R.id.cyl_theme_attach_listener, state)
            view.addOnAttachStateChangeListener(state)
        }
    }

    /** [EN] `setRuleHandler`: a handler for `rule` (a new rule, or replacing a built-in one); null restores the built-in one. [CN] 为 `rule` 设置处理器（新规则或替换内置规则）；null 恢复内置处理器。 */
    @JvmStatic
    fun setRuleHandler(rule: String, handler: CYLThemeRuleHandler?) {
        if (handler == null) ruleHandlers.remove(rule) else ruleHandlers[rule] = handler
    }

    /** [EN] The value `name` of `manager`'s current theme, seen from `context`, or null. [CN] `manager` 当前主题中名为 `name` 的值（以 `context` 读取），没有时为 null。 */
    @JvmStatic
    @JvmOverloads
    fun value(context: Context, name: String, manager: CYLThemeManager = CYLThemeManagerCenter.defaultThemeManager): CYLThemeValue? {
        val theme = manager.currentTheme
        val raw: Any? = when (theme) {
            is CYLThemeValueProviding -> theme.cyl_themeValueForName(name, context)
            is Map<*, *> -> theme[name]
            is CYLThemeStyle -> return attribute(context, styleTheme(context.resources, theme.styleRes), name)
            else -> null
        }
        if (raw != null) return CYLThemeValue(name, raw, context, context.theme)
        return attribute(context, context.theme, name)
    }

    private fun styleTheme(resources: Resources, styleRes: Int): Resources.Theme = synchronized(styleThemes) {
        styleThemes.getOrPut(resources to styleRes) { resources.newTheme().apply { applyStyle(styleRes, true) } }
    }

    // [EN] Theme values name attributes by string (from layouts, code or a configuration file), as QMUI does; ids are cached. [CN] 与 QMUI 一样，主题值用字符串指定属性（来自布局、代码或配置文件）；id 会被缓存。
    @android.annotation.SuppressLint("DiscouragedApi")
    private fun attribute(context: Context, theme: Resources.Theme, name: String): CYLThemeValue? {
        val key = context.packageName + ":" + name
        // [EN] The app's attribute first, then the platform's (e.g. "colorAccent", "textColorPrimary"). [CN] 先找 App 的属性，再找系统属性（例如 "colorAccent"、"textColorPrimary"）。
        val id = attributeIds.getOrPut(key) {
            context.resources.getIdentifier(name, "attr", context.packageName).takeIf { it != 0 } ?: context.resources.getIdentifier(name, "attr", "android")
        }
        if (id == 0) return null
        val typed = TypedValue()
        if (!theme.resolveAttribute(id, typed, true)) return null
        return CYLThemeValue(name, typed, context, theme)
    }

    /**
     * [EN] Applies the view's rules for the current theme. Without `force`, a view already brought to this theme is skipped
     *      (QMUI's per-view skin index), so a view reached twice in one change does the work once.
     * [CN] 按当前主题应用视图的规则。不 `force` 时跳过已应用当前主题的视图（QMUI 的视图皮肤索引），同一次变化中被访问两次的视图只执行一次。
     */
    internal fun applyThemeValues(view: View, force: Boolean) {
        val value = view.cyl_themeValue ?: return
        val manager = view.cyl_themeValueManager
        val stamp = manager.name + "#" + manager.themeVersion
        if (!force && view.getTag(R.id.cyl_theme_value_applied) == stamp) return
        view.setTag(R.id.cyl_theme_value_applied, stamp)
        if (view.cyl_ignoresThemeApply) return
        for ((rule, name) in CYLThemeValueBuilder().convertFrom(value).rules()) {
            val resolved = value(view.context, name, manager) ?: continue
            val handler = ruleHandlers[rule] ?: builtInHandlers[rule] ?: continue
            // [EN] One bad value must not stop the other rules. [CN] 一个错误的值不能中断其他规则。
            try { handler.cyl_applyThemeValue(view, rule, resolved) } catch (error: RuntimeException) { android.util.Log.w("CYLThemeValues", "rule $rule: ${error.message}") }
        }
    }

    /** [EN] Tells the `CYLThemeSpan`s of a text view and the `CYLThemeItemDecoration`s of a RecyclerView. [CN] 通知文本视图中的 `CYLThemeSpan` 与 RecyclerView 的 `CYLThemeItemDecoration`。 */
    internal fun dispatchSpansAndDecorations(view: View, manager: CYLThemeManager?) {
        if (view is TextView) {
            val text = view.text
            if (text is Spanned) {
                val spans = text.getSpans(0, text.length, CYLThemeSpan::class.java)
                for (span in spans) span.cyl_themeDidChange(view, manager)
                if (spans.isNotEmpty()) view.invalidate()
            }
        }
        if (view is ViewGroup && RecyclerViews.isRecyclerView(view)) {
            val decorations = RecyclerViews.decorations(view).filterIsInstance<CYLThemeItemDecoration>()
            for (decoration in decorations) decoration.cyl_themeDidChange(view, manager)
            if (decorations.isNotEmpty()) RecyclerViews.invalidateItemDecorations(view)
        }
    }

    /** [EN] `RecyclerView` by reflection, with the methods looked up once. [CN] 通过反射访问 `RecyclerView`，方法只查找一次。 */
    private object RecyclerViews {
        private const val CLASS_NAME = "androidx.recyclerview.widget.RecyclerView"
        private val recyclerClass: Class<*>? by lazy { CYLReflection.type(CLASS_NAME) }
        private val countMethod: Method? by lazy { recyclerClass?.let { runCatching { it.getMethod("getItemDecorationCount") }.getOrNull() } }
        private val itemMethod: Method? by lazy { recyclerClass?.let { runCatching { it.getMethod("getItemDecorationAt", Int::class.javaPrimitiveType) }.getOrNull() } }
        private val invalidateMethod: Method? by lazy { recyclerClass?.let { runCatching { it.getMethod("invalidateItemDecorations") }.getOrNull() } }

        fun isRecyclerView(view: View): Boolean = recyclerClass?.isInstance(view) == true

        fun decorations(view: View): List<Any> {
            val count = runCatching { countMethod?.invoke(view) as? Int }.getOrNull() ?: return emptyList()
            return (0 until count).mapNotNull { index -> runCatching { itemMethod?.invoke(view, index) }.getOrNull() }
        }

        fun invalidateItemDecorations(view: View) { runCatching { invalidateMethod?.invoke(view) } }
    }

    // MARK: - Built-in rules (QMUI's handlers) 内置规则（QMUI 的处理器）

    private val builtInHandlers: Map<String, CYLThemeRuleHandler> = mapOf(
        CYLThemeValueBuilder.BACKGROUND to CYLThemeRuleHandler { view, _, value ->
            val gradient = view.background as? GradientDrawable
            val color = when (val raw = value.raw) {
                is Int -> raw
                is CYLThemeColor -> raw.cyl_rawColor
                else -> null
            }
            if (gradient != null && color != null) gradient.setColor(color) else setBackgroundKeepingPadding(view, value.drawable)
        },
        CYLThemeValueBuilder.BG_TINT_COLOR to CYLThemeRuleHandler { view, _, value -> view.backgroundTintList = value.colorStateList },
        CYLThemeValueBuilder.TEXT_COLOR to CYLThemeRuleHandler { view, _, value -> value.colorStateList?.let { (view as? TextView)?.setTextColor(it) } },
        CYLThemeValueBuilder.HINT_COLOR to CYLThemeRuleHandler { view, _, value -> value.colorStateList?.let { (view as? TextView)?.setHintTextColor(it) } },
        CYLThemeValueBuilder.LINK_COLOR to CYLThemeRuleHandler { view, _, value -> value.colorStateList?.let { (view as? TextView)?.setLinkTextColor(it) } },
        CYLThemeValueBuilder.SRC to CYLThemeRuleHandler { view, _, value -> (view as? ImageView)?.setImageDrawable(value.drawable) },
        CYLThemeValueBuilder.TINT_COLOR to CYLThemeRuleHandler { view, _, value ->
            val tint = value.colorStateList
            when (view) {
                is ImageView -> view.imageTintList = tint
                is CompoundButton -> view.buttonTintList = tint
                is ProgressBar -> view.indeterminateTintList = tint
                is TextView -> androidx.core.widget.TextViewCompat.setCompoundDrawableTintList(view, tint)
                else -> view.foregroundTintList = tint
            }
        },
        CYLThemeValueBuilder.ALPHA to CYLThemeRuleHandler { view, _, value -> value.float?.let { view.alpha = it.coerceIn(0f, 1f) } },
        CYLThemeValueBuilder.BORDER to CYLThemeRuleHandler { view, _, value -> view.cyl_applyThemeBorder(value.color) },
        CYLThemeValueBuilder.PROGRESS_COLOR to CYLThemeRuleHandler { view, _, value -> (view as? ProgressBar)?.progressTintList = value.colorStateList },
        CYLThemeValueBuilder.TEXT_COMPOUND_TINT_COLOR to CYLThemeRuleHandler { view, _, value -> (view as? TextView)?.let { androidx.core.widget.TextViewCompat.setCompoundDrawableTintList(it, value.colorStateList) } },
        CYLThemeValueBuilder.TEXT_COMPOUND_LEFT_SRC to compoundHandler(0),
        CYLThemeValueBuilder.TEXT_COMPOUND_TOP_SRC to compoundHandler(1),
        CYLThemeValueBuilder.TEXT_COMPOUND_RIGHT_SRC to compoundHandler(2),
        CYLThemeValueBuilder.TEXT_COMPOUND_BOTTOM_SRC to compoundHandler(3),
    )

    /** [EN] The compound drawable at `position` (left, top, right, bottom), at its intrinsic size; the others are kept. [CN] 位于 `position`（左、上、右、下）的 compound drawable，使用其固有尺寸；其他保持不变。 */
    private fun compoundHandler(position: Int) = CYLThemeRuleHandler { view, _, value ->
        val text = view as? TextView ?: return@CYLThemeRuleHandler
        val drawables = text.compoundDrawables.copyOf()
        drawables[position] = value.drawable?.apply { setBounds(0, 0, intrinsicWidth, intrinsicHeight) }
        text.setCompoundDrawables(drawables[0], drawables[1], drawables[2], drawables[3])
    }

    /** [EN] `QMUIViewHelper.setBackgroundKeepingPadding`. [CN] 设置背景并保留 padding。 */
    private fun setBackgroundKeepingPadding(view: View, drawable: Drawable?) {
        val padding = intArrayOf(view.paddingLeft, view.paddingTop, view.paddingRight, view.paddingBottom)
        view.background = drawable
        view.setPadding(padding[0], padding[1], padding[2], padding[3])
    }

    // MARK: - Layouts 布局

    /**
     * [EN] Reads the `app:cyl_theme…` attributes of a layout into the view's `cyl_themeValue` (for a custom view's
     *      constructor, or apps that keep their own inflater factory).
     * [CN] 把布局中的 `app:cyl_theme…` 属性读入视图的 `cyl_themeValue`（用于自定义视图的构造方法，或保留自己 inflater factory 的 App）。
     */
    @JvmStatic
    fun applyAttributes(view: View, attrs: AttributeSet?) {
        attrs ?: return
        val builder = CYLThemeValueBuilder()
        val array = view.context.obtainStyledAttributes(attrs, R.styleable.CYLThemeValue)
        try {
            for (position in 0 until array.indexCount) {
                val index = array.getIndex(position)
                val name = array.getString(index) ?: continue
                if (index == R.styleable.CYLThemeValue_cyl_themeValue) builder.convertFrom(name) else xmlRules[index]?.let { builder.custom(it, name) }
            }
        } finally {
            array.recycle()
        }
        if (!builder.isEmpty()) view.cyl_themeValue = CYLThemeValueBuilder().convertFrom(view.cyl_themeValue).convertFrom(builder.build()).build()
    }

    private val xmlRules: Map<Int, String> by lazy {
        mapOf(
            R.styleable.CYLThemeValue_cyl_themeBackground to CYLThemeValueBuilder.BACKGROUND,
            R.styleable.CYLThemeValue_cyl_themeBgTintColor to CYLThemeValueBuilder.BG_TINT_COLOR,
            R.styleable.CYLThemeValue_cyl_themeTextColor to CYLThemeValueBuilder.TEXT_COLOR,
            R.styleable.CYLThemeValue_cyl_themeHintColor to CYLThemeValueBuilder.HINT_COLOR,
            R.styleable.CYLThemeValue_cyl_themeLinkColor to CYLThemeValueBuilder.LINK_COLOR,
            R.styleable.CYLThemeValue_cyl_themeSrc to CYLThemeValueBuilder.SRC,
            R.styleable.CYLThemeValue_cyl_themeTintColor to CYLThemeValueBuilder.TINT_COLOR,
            R.styleable.CYLThemeValue_cyl_themeAlpha to CYLThemeValueBuilder.ALPHA,
            R.styleable.CYLThemeValue_cyl_themeBorder to CYLThemeValueBuilder.BORDER,
            R.styleable.CYLThemeValue_cyl_themeProgressColor to CYLThemeValueBuilder.PROGRESS_COLOR,
            R.styleable.CYLThemeValue_cyl_themeTextCompoundTintColor to CYLThemeValueBuilder.TEXT_COMPOUND_TINT_COLOR,
            R.styleable.CYLThemeValue_cyl_themeTextCompoundLeftSrc to CYLThemeValueBuilder.TEXT_COMPOUND_LEFT_SRC,
            R.styleable.CYLThemeValue_cyl_themeTextCompoundTopSrc to CYLThemeValueBuilder.TEXT_COMPOUND_TOP_SRC,
            R.styleable.CYLThemeValue_cyl_themeTextCompoundRightSrc to CYLThemeValueBuilder.TEXT_COMPOUND_RIGHT_SRC,
            R.styleable.CYLThemeValue_cyl_themeTextCompoundBottomSrc to CYLThemeValueBuilder.TEXT_COMPOUND_BOTTOM_SRC,
        )
    }

    /**
     * [EN] QMUI `QMUISkinLayoutInflaterFactory`: installs a factory on the activity's layout inflater that reads the
     *      `app:cyl_theme…` attributes of every inflated view. Call it before `super.onCreate` (an `AppCompatActivity` keeps
     *      its own view replacement: the factory asks its delegate first). Returns false when the inflater already has a factory.
     * [CN] QMUI 的 `QMUISkinLayoutInflaterFactory`：为 Activity 的布局 inflater 安装 factory，读取每个加载视图的 `app:cyl_theme…` 属性。
     *      在 `super.onCreate` 之前调用（`AppCompatActivity` 保留自己的视图替换：factory 先询问其 delegate）。inflater 已有 factory 时返回 false。
     */
    @JvmStatic
    fun installLayoutInflaterFactory(activity: Activity): Boolean {
        val inflater = LayoutInflater.from(activity)
        if (inflater.factory2 != null || inflater.factory != null) return false
        inflater.factory2 = CYLThemeLayoutInflaterFactory(activity)
        return true
    }

    // MARK: - Registered roots (QMUI register) 登记的根对象

    private val roots = ArrayList<Pair<WeakReference<Any>, CYLThemeManager>>()

    /**
     * [EN] QMUI `register`: an activity, fragment, view, dialog, window or popup window that follows `manager`'s theme
     *      changes even outside a tab bar controller (a dialog, a second activity). It is brought to the current theme now.
     * [CN] QMUI 的 `register`：让 Activity、Fragment、View、Dialog、Window 或 PopupWindow 在 TabBarController 之外（对话框、第二个 Activity）
     *      也跟随 `manager` 的主题变化，并立即应用当前主题。
     */
    @JvmStatic
    @JvmOverloads
    fun register(target: Any, manager: CYLThemeManager = CYLThemeManagerCenter.defaultThemeManager) {
        synchronized(roots) {
            roots.removeAll { it.first.get() == null || (it.first.get() === target && it.second === manager) }
            roots += WeakReference(target) to manager
        }
        rootView(target)?.cyl_themeDidChangeByManager(manager, manager.currentThemeIdentifier, manager.currentTheme)
    }

    /** [EN] QMUI `unRegister`. [CN] 取消登记。 */
    @JvmStatic
    @JvmOverloads
    fun unregister(target: Any, manager: CYLThemeManager = CYLThemeManagerCenter.defaultThemeManager) {
        synchronized(roots) { roots.removeAll { it.first.get() == null || (it.first.get() === target && it.second === manager) } }
    }

    internal fun registeredRootViews(manager: CYLThemeManager): List<View> = synchronized(roots) {
        roots.removeAll { it.first.get() == null }
        roots.filter { it.second === manager }.mapNotNull { it.first.get()?.let(::rootView) }
    }

    private fun rootView(target: Any): View? = when (target) {
        is Activity -> target.window?.decorView
        is Fragment -> target.view
        is Dialog -> target.window?.decorView
        is PopupWindow -> target.contentView
        is Window -> target.decorView
        is View -> target
        else -> null
    }
}

/**
 * [EN] The factory of `CYLThemeValues.installLayoutInflaterFactory`: an `AppCompatActivity`'s delegate makes the view when it
 *      can, otherwise the view's (Context, AttributeSet) constructor, looked up once per class; then the theme attributes are read.
 * [CN] `CYLThemeValues.installLayoutInflaterFactory` 的 factory：能由 `AppCompatActivity` 的 delegate 创建时由它创建，否则调用视图的
 *      (Context, AttributeSet) 构造方法（每个类只查找一次）；然后读取主题属性。
 */
class CYLThemeLayoutInflaterFactory(activity: Activity) : LayoutInflater.Factory2 {
    private val activity = WeakReference(activity)

    override fun onCreateView(parent: View?, name: String, context: Context, attrs: AttributeSet): View? {
        // [EN] <fragment> and friends stay with the activity's own factory. [CN] <fragment> 等标签仍由 Activity 自己的 factory 处理。
        if (name == "fragment" || name == "include" || name == "merge" || name == "requestFocus" || name == "tag" || name == "blink") return null
        val view = (activity.get() as? androidx.appcompat.app.AppCompatActivity)?.delegate?.createView(parent, name, context, attrs) ?: create(name, context, attrs)
        view?.let { CYLThemeValues.applyAttributes(it, attrs) }
        return view
    }

    override fun onCreateView(name: String, context: Context, attrs: AttributeSet): View? = onCreateView(null, name, context, attrs)

    private fun create(name: String, context: Context, attrs: AttributeSet): View? {
        val candidates = if (name.contains('.')) listOf(name) else PREFIXES.map { it + name }
        for (className in candidates) {
            val constructor = constructor(className) ?: continue
            return try { constructor.newInstance(context, attrs) } catch (error: ReflectiveOperationException) { null } catch (error: RuntimeException) { null }
        }
        return null
    }

    private companion object {
        val PREFIXES = listOf("android.widget.", "android.webkit.", "android.app.", "android.view.")
        val constructors = ConcurrentHashMap<String, Any>()
        val MISSING = Any()

        @Suppress("UNCHECKED_CAST")
        fun constructor(className: String): Constructor<out View>? {
            val cached = constructors.getOrPut(className) {
                runCatching { Class.forName(className).asSubclass(View::class.java).getConstructor(Context::class.java, AttributeSet::class.java) }.getOrNull() ?: MISSING
            }
            return if (cached === MISSING) null else cached as Constructor<out View>
        }
    }
}
