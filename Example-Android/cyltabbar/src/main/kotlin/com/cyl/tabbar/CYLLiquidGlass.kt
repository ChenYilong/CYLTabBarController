/*
   Liquid Glass for the Android tab bar. The AGSL shaders, the effect order (vibrancy, blur, lens), the highlight and the
   values of the tab bar are ported from Kyant's Backdrop (https://github.com/Kyant0/AndroidLiquidGlass, `backdrop/` and
   `LiquidBottomTabs.kt`), from Compose to Android views, and renamed to this library's conventions.

   Copyright 2025 Kyant

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

   Changes: Compose modifiers replaced by RenderNode drawing in a View; only the rounded rectangle shapes the tab bar uses.
 */

package com.cyl.tabbar

import android.graphics.BlendMode
import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.RenderEffect
import android.graphics.RenderNode
import android.graphics.RuntimeShader
import android.graphics.Shader
import android.os.Build
import android.view.View
import androidx.annotation.RequiresApi
import kotlin.math.PI
import kotlin.math.sqrt

/**
 * [EN] What a device can draw: the full glass (refraction, Android 13+), a blur only (Android 12) or a translucent
 *      color (older versions and software canvases).
 * [CN] 设备能绘制的效果：完整的玻璃（折射，Android 13+）、只有模糊（Android 12），或半透明颜色（更早的版本与软件绘制）。
 */
internal object CYLLiquidGlassSupport {
    @get:androidx.annotation.ChecksSdkIntAtLeast(api = Build.VERSION_CODES.S)
    val rendersBlur: Boolean get() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
    @get:androidx.annotation.ChecksSdkIntAtLeast(api = Build.VERSION_CODES.TIRAMISU)
    val rendersRefraction: Boolean get() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU
}

/** [EN] The AGSL shaders, from Backdrop's `internal/Shaders.kt`. [CN] AGSL 着色器，来自 Backdrop 的 `internal/Shaders.kt`。 */
internal object CYLLiquidGlassShaders {
    private const val ROUNDED_RECT_SDF = """
float radiusAt(float2 coord, float4 radii) {
    if (coord.x >= 0.0) {
        if (coord.y <= 0.0) return radii.y;
        else return radii.z;
    } else {
        if (coord.y <= 0.0) return radii.x;
        else return radii.w;
    }
}

float sdRoundedRect(float2 coord, float2 halfSize, float radius) {
    float2 cornerCoord = abs(coord) - (halfSize - float2(radius));
    float outside = length(max(cornerCoord, 0.0)) - radius;
    float inside = min(max(cornerCoord.x, cornerCoord.y), 0.0);
    return outside + inside;
}

float2 gradSdRoundedRect(float2 coord, float2 halfSize, float radius) {
    float2 cornerCoord = abs(coord) - (halfSize - float2(radius));
    if (cornerCoord.x >= 0.0 || cornerCoord.y >= 0.0) {
        return sign(coord) * normalize(max(cornerCoord, 0.0));
    } else {
        float gradX = step(cornerCoord.y, cornerCoord.x);
        return sign(coord) * float2(gradX, 1.0 - gradX);
    }
}"""

    /** [EN] The lens: the content bends near the edge, like the rim of a glass. [CN] 透镜：内容在边缘附近弯折，如同玻璃的边缘。 */
    const val REFRACTION = """
uniform shader content;
uniform float2 size;
uniform float2 offset;
uniform float4 cornerRadii;
uniform float refractionHeight;
uniform float refractionAmount;
uniform float depthEffect;
$ROUNDED_RECT_SDF

float circleMap(float x) {
    return 1.0 - sqrt(1.0 - x * x);
}

half4 main(float2 coord) {
    float2 halfSize = size * 0.5;
    float2 centeredCoord = (coord + offset) - halfSize;
    float radius = radiusAt(coord, cornerRadii);
    float sd = sdRoundedRect(centeredCoord, halfSize, radius);
    if (-sd >= refractionHeight) {
        return content.eval(coord);
    }
    sd = min(sd, 0.0);
    float d = circleMap(1.0 - -sd / refractionHeight) * refractionAmount;
    float gradRadius = min(radius * 1.5, min(halfSize.x, halfSize.y));
    float2 grad = normalize(gradSdRoundedRect(centeredCoord, halfSize, gradRadius) + depthEffect * normalize(centeredCoord));
    float2 refractedCoord = coord + d * grad;
    return content.eval(refractedCoord);
}"""

    /** [EN] The lens with chromatic dispersion, for the pressed selection bubble. [CN] 带色散的透镜，用于按下时的选中气泡。 */
    const val REFRACTION_WITH_DISPERSION = """
uniform shader content;
uniform float2 size;
uniform float2 offset;
uniform float4 cornerRadii;
uniform float refractionHeight;
uniform float refractionAmount;
uniform float depthEffect;
uniform float chromaticAberration;
$ROUNDED_RECT_SDF

float circleMap(float x) {
    return 1.0 - sqrt(1.0 - x * x);
}

half4 main(float2 coord) {
    float2 halfSize = size * 0.5;
    float2 centeredCoord = (coord + offset) - halfSize;
    float radius = radiusAt(coord, cornerRadii);
    float sd = sdRoundedRect(centeredCoord, halfSize, radius);
    if (-sd >= refractionHeight) {
        return content.eval(coord);
    }
    sd = min(sd, 0.0);
    float d = circleMap(1.0 - -sd / refractionHeight) * refractionAmount;
    float gradRadius = min(radius * 1.5, min(halfSize.x, halfSize.y));
    float2 grad = normalize(gradSdRoundedRect(centeredCoord, halfSize, gradRadius) + depthEffect * normalize(centeredCoord));
    float2 refractedCoord = coord + d * grad;
    float dispersionIntensity = chromaticAberration * ((centeredCoord.x * centeredCoord.y) / (halfSize.x * halfSize.y));
    float2 dispersedCoord = d * grad * dispersionIntensity;
    half4 color = half4(0.0);
    half4 red = content.eval(refractedCoord + dispersedCoord);
    color.r += red.r / 3.5;
    color.a += red.a / 7.0;
    half4 orange = content.eval(refractedCoord + dispersedCoord * (2.0 / 3.0));
    color.r += orange.r / 3.5;
    color.g += orange.g / 7.0;
    color.a += orange.a / 7.0;
    half4 yellow = content.eval(refractedCoord + dispersedCoord * (1.0 / 3.0));
    color.r += yellow.r / 3.5;
    color.g += yellow.g / 3.5;
    color.a += yellow.a / 7.0;
    half4 green = content.eval(refractedCoord);
    color.g += green.g / 3.5;
    color.a += green.a / 7.0;
    half4 cyan = content.eval(refractedCoord - dispersedCoord * (1.0 / 3.0));
    color.g += cyan.g / 3.5;
    color.b += cyan.b / 3.0;
    color.a += cyan.a / 7.0;
    half4 blue = content.eval(refractedCoord - dispersedCoord * (2.0 / 3.0));
    color.b += blue.b / 3.0;
    color.a += blue.a / 7.0;
    half4 purple = content.eval(refractedCoord - dispersedCoord);
    color.r += purple.r / 7.0;
    color.b += purple.b / 3.0;
    color.a += purple.a / 7.0;
    return color;
}"""

    /** [EN] The rim light: brighter where the edge faces `angle`. [CN] 边缘高光：边缘朝向 `angle` 的位置更亮。 */
    const val HIGHLIGHT = """
uniform float2 size;
uniform float4 cornerRadii;
layout(color) uniform half4 color;
uniform float angle;
uniform float falloff;
$ROUNDED_RECT_SDF

half4 main(float2 coord) {
    float2 halfSize = size * 0.5;
    float2 centeredCoord = coord - halfSize;
    float radius = radiusAt(coord, cornerRadii);
    float gradRadius = min(radius * 1.5, min(halfSize.x, halfSize.y));
    float2 grad = gradSdRoundedRect(centeredCoord, halfSize, gradRadius);
    float2 normal = float2(cos(angle), sin(angle));
    float d = dot(grad, normal);
    float intensity = pow(abs(d), falloff);
    return color * intensity;
}"""

    /** [EN] Backdrop's `vibrancy()`: saturation 1.5. [CN] Backdrop 的 `vibrancy()`：饱和度 1.5。 */
    fun vibrancyColorFilter(saturation: Float = 1.5f): ColorMatrixColorFilter {
        val inverse = 1f - saturation
        val r = 0.213f * inverse
        val g = 0.715f * inverse
        val b = 0.072f * inverse
        return ColorMatrixColorFilter(ColorMatrix(floatArrayOf(
            r + saturation, g, b, 0f, 0f,
            r, g + saturation, b, 0f, 0f,
            r, g, b + saturation, 0f, 0f,
            0f, 0f, 0f, 1f, 0f,
        )))
    }
}

/**
 * [EN] A damped spring, as Compose's `spring(dampingRatio, stiffness)` that Backdrop's tab bar animates with: `target`
 *      moves `value`, stepped from frame times.
 * [CN] 阻尼弹簧，对应 Backdrop 的 TabBar 所用的 Compose `spring(dampingRatio, stiffness)`：`target` 驱动 `value`，按帧时间步进。
 */
internal class CYLSpring(var value: Float, private val dampingRatio: Float, private val stiffness: Float, private val threshold: Float) {
    var target: Float = value
    var velocity: Float = 0f
        private set
    val isAtRest: Boolean get() = kotlin.math.abs(target - value) < threshold && kotlin.math.abs(velocity) < threshold * 10f

    fun snap(to: Float) {
        value = to
        target = to
        velocity = 0f
    }

    /** [EN] Moves by `seconds`; true while it is still moving. [CN] 前进 `seconds` 秒；仍在运动时返回 true。 */
    fun step(seconds: Float): Boolean {
        val omega = sqrt(stiffness)
        var remaining = seconds.coerceAtMost(0.064f)
        while (remaining > 0f) {
            val dt = remaining.coerceAtMost(0.004f)
            val acceleration = -stiffness * (value - target) - 2f * dampingRatio * omega * velocity
            velocity += acceleration * dt
            value += velocity * dt
            remaining -= dt
        }
        if (isAtRest) snap(target)
        return !isAtRest
    }
}

/**
 * [EN] Draws what is behind the tab bar (the pages) inside a rounded rectangle, through Backdrop's effects: the pages are
 *      recorded into a `RenderNode`, the part under the shape is copied into a second node that carries the effect chain,
 *      and that node is drawn clipped to the shape. Android 12+ with a hardware canvas; `draw` returns false otherwise so
 *      the caller draws a translucent color instead.
 * [CN] 在圆角矩形中绘制 TabBar 后面的内容（页面），并应用 Backdrop 的效果：页面录制到一个 `RenderNode`，形状下方的部分复制到带效果链的
 *      第二个节点，再按形状裁剪后绘制。需要 Android 12+ 与硬件加速画布；否则 `draw` 返回 false，由调用方改为绘制半透明颜色。
 */
internal class CYLTabBarBackdrop {
    private var sourceNode: Any? = null
    private var shapeNode: Any? = null
    private val clipPath = Path()
    private var refraction: Any? = null
    private var dispersion: Any? = null

    /**
     * [EN] `source` is drawn so that its point (`sourceX`, `sourceY`) lands on `rect.left`, `rect.top`.
     * [CN] 绘制 `source` 时，其坐标（`sourceX`, `sourceY`）对齐 `rect.left`、`rect.top`。
     */
    fun draw(canvas: Canvas, source: View, sourceX: Float, sourceY: Float, rect: RectF, radius: Float, effects: CYLGlassEffects): Boolean {
        if (!CYLLiquidGlassSupport.rendersBlur || !canvas.isHardwareAccelerated || source.width <= 0 || rect.width() <= 0f) return false
        drawEffects(canvas, source, sourceX, sourceY, rect, radius, effects)
        return true
    }

    @RequiresApi(Build.VERSION_CODES.S)
    private fun drawEffects(canvas: Canvas, source: View, sourceX: Float, sourceY: Float, rect: RectF, radius: Float, effects: CYLGlassEffects) {
        val pages = (sourceNode as? RenderNode) ?: RenderNode("CYLTabBarBackdropPages").also { sourceNode = it }
        pages.setPosition(0, 0, source.width, source.height)
        val recording = pages.beginRecording(source.width, source.height)
        // [EN] The window's background first: pages are usually transparent where they have no content (the white is the
        //      window's), so without it the glass would be clear there and the sharp page would show through it.
        // [CN] 先绘制窗口背景：页面在没有内容的地方通常是透明的（白色来自窗口），没有它，玻璃在这些地方是透明的，清晰的页面会透出来。
        recording.drawColor(windowBackgroundColor(source))
        source.draw(recording)
        pages.endRecording()

        val width = kotlin.math.ceil(rect.width()).toInt()
        val height = kotlin.math.ceil(rect.height()).toInt()
        val shape = (shapeNode as? RenderNode) ?: RenderNode("CYLTabBarBackdropShape").also { shapeNode = it }
        shape.setPosition(0, 0, width, height)
        val shapeCanvas = shape.beginRecording(width, height)
        shapeCanvas.translate(-sourceX, -sourceY)
        shapeCanvas.drawRenderNode(pages)
        shape.endRecording()
        shape.setRenderEffect(effectChain(width.toFloat(), height.toFloat(), radius, effects))

        clipPath.rewind()
        clipPath.addRoundRect(rect, radius, radius, Path.Direction.CW)
        canvas.save()
        canvas.clipPath(clipPath)
        canvas.translate(rect.left, rect.top)
        canvas.drawRenderNode(shape)
        canvas.restore()
    }

    /** [EN] The color behind the pages: the window's background color, else the theme's `colorBackground`. [CN] 页面后面的颜色：窗口背景色，否则为主题的 `colorBackground`。 */
    private fun windowBackgroundColor(source: View): Int {
        (source.rootView.background as? android.graphics.drawable.ColorDrawable)?.let { return it.color or 0xFF000000.toInt() }
        val value = android.util.TypedValue()
        return if (source.context.theme.resolveAttribute(android.R.attr.colorBackground, value, true) && value.type >= android.util.TypedValue.TYPE_FIRST_COLOR_INT && value.type <= android.util.TypedValue.TYPE_LAST_COLOR_INT) value.data or 0xFF000000.toInt()
               else android.graphics.Color.WHITE
    }

    /** [EN] Backdrop's order: vibrancy, then blur, then the lens on top. [CN] Backdrop 的顺序：先鲜艳度，再模糊，最后透镜。 */
    @RequiresApi(Build.VERSION_CODES.S)
    private fun effectChain(width: Float, height: Float, radius: Float, effects: CYLGlassEffects): RenderEffect? {
        var effect: RenderEffect? = if (effects.saturation != 1f) RenderEffect.createColorFilterEffect(CYLLiquidGlassShaders.vibrancyColorFilter(effects.saturation)) else null
        if (effects.blurRadius > 0f) {
            val blur = effect?.let { RenderEffect.createBlurEffect(effects.blurRadius, effects.blurRadius, it, Shader.TileMode.CLAMP) }
                ?: RenderEffect.createBlurEffect(effects.blurRadius, effects.blurRadius, Shader.TileMode.CLAMP)
            effect = blur
        }
        if (CYLLiquidGlassSupport.rendersRefraction && effects.refractionHeight > 0f && effects.refractionAmount > 0f) {
            val lens = lensEffect(width, height, radius, effects)
            effect = effect?.let { RenderEffect.createChainEffect(lens, it) } ?: lens
        }
        return effect
    }

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    private fun lensEffect(width: Float, height: Float, radius: Float, effects: CYLGlassEffects): RenderEffect {
        val shader = if (effects.chromaticAberration) {
            (dispersion as? RuntimeShader) ?: RuntimeShader(CYLLiquidGlassShaders.REFRACTION_WITH_DISPERSION).also { dispersion = it }
        } else {
            (refraction as? RuntimeShader) ?: RuntimeShader(CYLLiquidGlassShaders.REFRACTION).also { refraction = it }
        }
        val corner = radius.coerceAtMost(minOf(width, height) / 2f)
        shader.setFloatUniform("size", width, height)
        shader.setFloatUniform("offset", 0f, 0f)
        shader.setFloatUniform("cornerRadii", corner, corner, corner, corner)
        shader.setFloatUniform("refractionHeight", effects.refractionHeight)
        shader.setFloatUniform("refractionAmount", -effects.refractionAmount)
        shader.setFloatUniform("depthEffect", 0f)
        if (effects.chromaticAberration) shader.setFloatUniform("chromaticAberration", 1f)
        return RenderEffect.createRuntimeShaderEffect(shader, "content")
    }
}

/** [EN] The effects of one glass shape, in px. [CN] 一个玻璃形状的效果（像素）。 */
internal data class CYLGlassEffects(
    val saturation: Float = 1.5f,
    val blurRadius: Float = 0f,
    val refractionHeight: Float = 0f,
    val refractionAmount: Float = 0f,
    val chromaticAberration: Boolean = false,
)

/**
 * [EN] Backdrop's `Highlight.Default`: a thin rim, brighter at 45°, added (PLUS) over the glass. Android 13+; nothing
 *      before.
 * [CN] Backdrop 的 `Highlight.Default`：细边缘，45° 方向更亮，以 PLUS 叠加在玻璃上。需要 Android 13+，更早的版本不绘制。
 */
internal class CYLGlassHighlight {
    private var shader: Any? = null
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE }
    private val path = Path()

    fun draw(canvas: Canvas, rect: RectF, radius: Float, density: Float, alpha: Float) {
        if (!CYLLiquidGlassSupport.rendersRefraction || alpha <= 0f || rect.width() <= 0f) return
        drawRim(canvas, rect, radius, density, alpha)
    }

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    private fun drawRim(canvas: Canvas, rect: RectF, radius: Float, density: Float, alpha: Float) {
        val rim = (shader as? RuntimeShader) ?: RuntimeShader(CYLLiquidGlassShaders.HIGHLIGHT).also { shader = it }
        val corner = radius.coerceAtMost(minOf(rect.width(), rect.height()) / 2f)
        rim.setFloatUniform("size", rect.width(), rect.height())
        rim.setFloatUniform("cornerRadii", corner, corner, corner, corner)
        rim.setColorUniform("color", android.graphics.Color.WHITE)
        rim.setFloatUniform("angle", (45f * PI / 180f).toFloat())
        rim.setFloatUniform("falloff", 1f)
        paint.shader = rim
        paint.alpha = (alpha * 0.5f * 255).toInt().coerceIn(0, 255)
        paint.strokeWidth = 0.5f * density * 2f
        paint.blendMode = BlendMode.PLUS
        path.rewind()
        path.addRoundRect(rect, radius, radius, Path.Direction.CW)
        canvas.save()
        canvas.clipPath(path)
        canvas.translate(rect.left, rect.top)
        canvas.drawRoundRect(0f, 0f, rect.width(), rect.height(), radius, radius, paint)
        canvas.restore()
    }
}
