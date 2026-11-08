package com.cyl.tabbar

import android.content.Context
import android.graphics.drawable.Drawable
import androidx.fragment.app.Fragment

/**
 * [EN] The plus button of `CYLTabBarControllerPlusButton`, so a configuration alone (a file, a URL, React Native or Flutter)
 *      can show one, as on iOS. The map takes `CYLTabBarItemTitle`, `CYLTabBarItemImage` (a name, "system:<name>", a file
 *      path or a Drawable), and optionally `CYLTabBarItemSelectedTitle` and `CYLTabBarItemSelectedTitleColor` ("#RRGGBB" or
 *      a color Int). It is registered for the configuration's `CYLTabBarControllerContext` before the tabs are set: give the
 *      configuration its own context. `CYLTabBarControllerPlusButtonAction` (code only, `(CYLPlusButton) -> Unit`) runs on
 *      each tap. Without an image, nothing is registered.
 * [CN] `CYLTabBarControllerPlusButton` 的 PlusButton，只用配置（文件、URL、React Native 或 Flutter）也能显示，与 iOS 相同。map 包含
 *      `CYLTabBarItemTitle`、`CYLTabBarItemImage`（名称、"system:<name>"、文件路径或 Drawable），可选 `CYLTabBarItemSelectedTitle` 与
 *      `CYLTabBarItemSelectedTitleColor`（"#RRGGBB" 或颜色 Int）。在设置 Tab 之前为配置的 `CYLTabBarControllerContext` 注册：请为配置设置独立的
 *      context。`CYLTabBarControllerPlusButtonAction`（仅代码，`(CYLPlusButton) -> Unit`）在每次点击时执行。没有图片时不注册。
 */
class CYLConfigurationPlusButton(context: Context, private val action: ((CYLPlusButton) -> Unit)?) : CYLPlusButton(context) {

    /** [EN] The constructor layout tools use: no tap action. [CN] 布局工具使用的构造方法：没有点击操作。 */
    constructor(context: Context) : this(context, null)

    /**
     * [EN] `CYLTabBarItemTitleColor` of the configuration. The tab bar tints the plus button's title on every selection
     *      change, but a configured color wins, as on iOS (white on Example-PAG's "Menu"): it is part of the title text,
     *      a `ForegroundColorSpan` that `titleSpans` adds to every title the button sets, and a span is drawn over the
     *      TextView's color. Selected, `cyl_selectedTitleColor` wins over it.
     * [CN] 配置的 `CYLTabBarItemTitleColor`。TabBar 每次选中变化时为 PlusButton 标题着色，但配置的颜色优先，与 iOS 相同（Example-PAG「菜单」为白色）：
     *      它是标题文本的一部分，即 `titleSpans` 为按钮设置的每个标题添加的 `ForegroundColorSpan`，span 的颜色绘制在 TextView 颜色之上。选中时
     *      `cyl_selectedTitleColor` 优先。
     */
    internal var cyl_configurationTitleColor: Int? = null
        set(value) {
            field = value
            titleLabel.setSpannableFactory(titleSpans)
            titleLabel.setText(titleLabel.text?.toString() ?: "", android.widget.TextView.BufferType.SPANNABLE)
        }

    /** [EN] The color the title is drawn in now, or null for the tab bar's tint. [CN] 当前标题的绘制颜色；null 时使用 TabBar 的着色。 */
    internal val cyl_titleDrawColor: Int?
        get() = if (isSelected) cyl_selectedTitleColor ?: cyl_configurationTitleColor else cyl_configurationTitleColor

    private val titleSpans = object : android.text.Spannable.Factory() {
        override fun newSpannable(source: CharSequence): android.text.Spannable {
            val text = android.text.SpannableString(source.toString())
            cyl_titleDrawColor?.let {
                text.setSpan(android.text.style.ForegroundColorSpan(it), 0, text.length, android.text.Spanned.SPAN_INCLUSIVE_INCLUSIVE)
            }
            return text
        }
    }

    /** [EN] `CYLPlusButtonSize` in pixels, or null for the size of the image and the title. [CN] 以像素表示的 `CYLPlusButtonSize`；null 时为图片与标题的尺寸。 */
    internal var cyl_configurationSize: android.util.Size? = null

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        cyl_configurationSize?.let { setMeasuredDimension(it.width, it.height) }
    }

    override fun plusChildViewControllerButtonClicked() {
        super.plusChildViewControllerButtonClicked()
        action?.invoke(this)
    }

    private class Provider(
        private val image: Drawable?,
        private val selectedImage: Drawable?,
        private val size: CYLSize?,
        private val imageSize: CYLSize?,
        private val backgroundImage: Drawable?,
        private val title: String?,
        private val selectedTitle: String?,
        private val titleColor: Int?,
        private val selectedTitleColor: Int?,
        private val titleSize: Float?,
        private val action: ((CYLPlusButton) -> Unit)?,
        private val context: String,
        private val index: Int?,
        private val centerYMultiplier: Float?,
        private val centerYOffset: Float?,
        private val alignsTitle: Boolean,
        private val keepsTitleVisible: Boolean,
        private val identifier: String?,
        private val page: Fragment?,
    ) : CYLPlusButtonSubclassing {
        override fun plusButton(context: Context): CYLPlusButton = CYLConfigurationPlusButton(context, action).apply {
            if (backgroundImage != null) {
                // [EN] A title drawn on a background image, the button the size of the image (Example-PAG's "Menu").
                // [CN] 画在背景图上的标题，按钮与图片同样大小（Example-PAG 的「菜单」）。
                background = backgroundImage.constantState?.newDrawable()?.mutate() ?: backgroundImage
                minimumWidth = backgroundImage.intrinsicWidth
                minimumHeight = backgroundImage.intrinsicHeight
                // [EN] The badge sits on the image's visible top-right corner, not on its transparent margin, as on iOS.
                // [CN] 角标位于图片可见部分的右上角，而不是透明边距上，与 iOS 相同。
                opaqueBounds(backgroundImage)?.let { visible ->
                    val density = resources.displayMetrics.density
                    cyl_badgeCenterOffset = CYLOffset(-(backgroundImage.intrinsicWidth - visible.right) / density, visible.top / density)
                }
            } else if (image != null) {
                setImageDrawable(fitted(image.constantState?.newDrawable()?.mutate() ?: image))
                selectedImage?.let { setSelectedImageDrawable(fitted(it.constantState?.newDrawable()?.mutate() ?: it)) }
            }
            size?.let {
                val density = resources.displayMetrics.density
                cyl_configurationSize = android.util.Size((it.width * density).toInt(), (it.height * density).toInt())
            }
            setTitle(title, selectedTitle, selectedTitleColor)
            titleColor?.let {
                titleLabel.setTextColor(it)
                cyl_configurationTitleColor = it
            }
            titleSize?.let { titleLabel.textSize = it }
            if (keepsTitleVisible || backgroundImage != null) titleLabel.visibility = android.view.View.VISIBLE
        }
        /**
         * [EN] `CYLPlusButtonImageSize`: the image drawn aspect fit in that size (dp), e.g. a 512 px network image, as iOS.
         * [CN] `CYLPlusButtonImageSize`：图片按该尺寸（dp）等比绘制，例如 512px 的网络图片，与 iOS 相同。
         */
        private fun CYLPlusButton.fitted(drawable: Drawable): Drawable {
            val target = imageSize ?: return drawable
            val width = drawable.intrinsicWidth
            val height = drawable.intrinsicHeight
            if (width <= 0 || height <= 0) return drawable
            val density = resources.displayMetrics.density
            val scale = minOf(target.width * density / width, target.height * density / height)
            val fittedWidth = (width * scale).toInt().coerceAtLeast(1)
            val fittedHeight = (height * scale).toInt().coerceAtLeast(1)
            val bitmap = android.graphics.Bitmap.createBitmap(fittedWidth, fittedHeight, android.graphics.Bitmap.Config.ARGB_8888)
            val bounds = android.graphics.Rect(drawable.bounds)
            drawable.setBounds(0, 0, fittedWidth, fittedHeight)
            drawable.draw(android.graphics.Canvas(bitmap))
            drawable.bounds = bounds
            return android.graphics.drawable.BitmapDrawable(resources, bitmap)
        }

        override fun indexOfPlusButtonInTabBar(): Int = index ?: CYLPlusButton.INDEX_NOT_SET
        override fun multiplierOfTabBarHeight(tabBarHeight: Float): Float = centerYMultiplier ?: CYLPlusButton.NOT_IMPLEMENTED
        override fun constantOfPlusButtonCenterYOffsetForTabBarHeight(tabBarHeight: Float): Float = centerYOffset ?: CYLPlusButton.NOT_IMPLEMENTED
        override fun plusChildViewController(): Fragment? = page
        override fun alignsTitleWithTabBarItemTitles(): Boolean = alignsTitle
        override fun tabBarItemIdentifier(): String? = identifier
        override fun tabBarContext(): String = context
    }

    companion object {
        /**
         * [EN] The part of `drawable` that is not transparent, in pixels at its intrinsic size; null when it has no size or
         *      nothing is visible.
         * [CN] `drawable` 中不透明的部分（按其固有尺寸的像素）；没有尺寸或完全透明时为 null。
         */
        internal fun opaqueBounds(drawable: Drawable): android.graphics.Rect? {
            val width = drawable.intrinsicWidth
            val height = drawable.intrinsicHeight
            if (width <= 0 || height <= 0) return null
            val bitmap = android.graphics.Bitmap.createBitmap(width, height, android.graphics.Bitmap.Config.ARGB_8888)
            val copy = drawable.constantState?.newDrawable()?.mutate() ?: drawable
            copy.setBounds(0, 0, width, height)
            copy.draw(android.graphics.Canvas(bitmap))
            val pixels = IntArray(width * height)
            bitmap.getPixels(pixels, 0, width, 0, 0, width, height)
            bitmap.recycle()
            var left = width; var top = height; var right = -1; var bottom = -1
            for (y in 0 until height) for (x in 0 until width) {
                if (pixels[y * width + x] ushr 24 > VISIBLE_ALPHA) {
                    if (x < left) left = x
                    if (x > right) right = x
                    if (y < top) top = y
                    if (y > bottom) bottom = y
                }
            }
            return if (right < 0) null else android.graphics.Rect(left, top, right + 1, bottom + 1)
        }

        /** [EN] The alpha above which a pixel counts as visible. [CN] 高于此值的像素视为可见。 */
        private const val VISIBLE_ALPHA = 0x20

        /**
         * [EN] Registers the plus button of `configuration` (normalized) for `tabBarContext`. `page` finds the page of a
         *      `CYLTabBarItemPageIdentifier`; `tabCount` places a plus button with a page in the middle by default.
         * [CN] 为 `tabBarContext` 注册配置中的 PlusButton。`page` 查找 `CYLTabBarItemPageIdentifier` 的页面；`tabCount` 让有页面的 PlusButton 默认居中。
         */
        internal fun registerIfNeeded(
            viewContext: Context,
            configuration: Map<String, Any?>,
            tabBarContext: String?,
            tabCount: Int = 0,
            page: ((String) -> Fragment?)? = null,
        ) {
            val attributes = (configuration[CYLConstants.CYLTabBarControllerPlusButton] as? Map<*, *>)?.toMutableMap() ?: return
            (attributes[CYLConstants.CYLTabBarItemPageIdentifier] as? String)?.takeIf { it.isNotEmpty() }?.let { identifier ->
                page?.invoke(identifier)?.let { fragment ->
                    attributes[PAGE_KEY] = fragment
                    if (attributes[CYLConstants.CYLPlusButtonIndexInTabBar] == null) attributes[CYLConstants.CYLPlusButtonIndexInTabBar] = tabCount / 2
                }
            }
            @Suppress("UNCHECKED_CAST")
            val action = configuration[CYLConstants.CYLTabBarControllerPlusButtonAction] as? (CYLPlusButton) -> Unit
            CYLPlusButton.cyl_registerPlusButtonWithAttributes(viewContext, attributes, action, tabBarContext)
        }

        /** [EN] Internal: the plus button's page, passed with its attributes. [CN] 内部使用：随属性传递的 PlusButton 页面。 */
        internal const val PAGE_KEY = "CYLConfigurationPlusButtonPage"

        private fun drawable(viewContext: Context, value: Any?): Drawable? = when (value) {
            is Drawable -> value
            is String -> CYLTabBarConfiguration.imageResolver.drawable(viewContext, value)
            else -> null
        }

        private fun number(value: Any?): Float? = when (value) {
            is Number -> value.toFloat()
            is String -> value.trim().toFloatOrNull()
            else -> null
        }?.takeIf { it.isFinite() }

        private fun flag(value: Any?): Boolean? = CYLTabBarConfiguration.boolValue(value)

        internal fun register(viewContext: Context, attributes: Map<*, *>, action: ((CYLPlusButton) -> Unit)?, tabBarContext: String?) {
            val image = drawable(viewContext, attributes[CYLConstants.CYLTabBarItemImage])
            val backgroundImage = drawable(viewContext, attributes[CYLConstants.CYLPlusButtonBackgroundImage])
            if (image == null && backgroundImage == null) return
            fun color(key: String): Int? = when (val color = attributes[key]) {
                is Int -> color
                else -> CYLTabBarConfiguration.colorValue(color)
            }
            val title = attributes[CYLConstants.CYLTabBarItemTitle]?.toString()
            val font = CYLFont.fromConfigurationValue(attributes[CYLConstants.CYLTabBarItemTitleFont])
            CYLPlusButton.registerPlusButton(Provider(
                image = image,
                selectedImage = drawable(viewContext, attributes[CYLConstants.CYLTabBarItemSelectedImage]),
                size = CYLTabBarConfiguration.sizeValue(attributes[CYLConstants.CYLPlusButtonSize])?.takeIf { it.width > 0 && it.height > 0 },
                imageSize = CYLTabBarConfiguration.sizeValue(attributes[CYLConstants.CYLPlusButtonImageSize])?.takeIf { it.width > 0 && it.height > 0 },
                backgroundImage = backgroundImage,
                title = title,
                selectedTitle = attributes[CYLConstants.CYLTabBarItemSelectedTitle]?.toString(),
                titleColor = color(CYLConstants.CYLTabBarItemTitleColor),
                selectedTitleColor = color(CYLConstants.CYLTabBarItemSelectedTitleColor),
                titleSize = font?.size,
                action = action,
                context = tabBarContext ?: CYLPlusButton.DEFAULT_TAB_BAR_CONTEXT,
                index = number(attributes[CYLConstants.CYLPlusButtonIndexInTabBar])?.toInt()?.takeIf { it >= 0 },
                centerYMultiplier = number(attributes[CYLConstants.CYLPlusButtonCenterYMultiplier]),
                centerYOffset = number(attributes[CYLConstants.CYLPlusButtonCenterYOffset]),
                alignsTitle = flag(attributes[CYLConstants.CYLPlusButtonAlignsTitle]) ?: (!title.isNullOrEmpty() && backgroundImage == null),
                keepsTitleVisible = flag(attributes[CYLConstants.CYLPlusButtonKeepsTitleVisible]) ?: false,
                identifier = (attributes[CYLConstants.CYLTabBarItemIdentifier] as? String)?.takeIf { it.isNotEmpty() },
                page = attributes[PAGE_KEY] as? Fragment,
            ))
        }
    }
}

/**
 * [EN] `+[CYLPlusButton cyl_registerPlusButtonWithAttributes:action:context:]`: registers a plus button described by the
 *      attributes of `CYLTabBarControllerPlusButton` (see [CYLConfigurationPlusButton]) for `tabBarContext`, with `action`
 *      run on each tap. Without an image, nothing is registered.
 * [CN] 用 `CYLTabBarControllerPlusButton` 的属性（见 [CYLConfigurationPlusButton]）为 `tabBarContext` 注册 PlusButton，每次点击执行
 *      `action`。没有图片时不注册。
 */
fun CYLPlusButton.Companion.cyl_registerPlusButtonWithAttributes(
    context: Context,
    attributes: Map<*, *>,
    action: ((CYLPlusButton) -> Unit)? = null,
    tabBarContext: String? = null,
) = CYLConfigurationPlusButton.register(context, attributes, action, tabBarContext)
