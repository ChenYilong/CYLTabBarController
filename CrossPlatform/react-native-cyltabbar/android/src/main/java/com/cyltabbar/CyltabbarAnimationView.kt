package com.cyltabbar

import android.content.Context
import android.widget.FrameLayout
import com.cyl.animateditem.CYLAnimatedItemAnimationEndListener
import com.cyl.animateditem.CYLAnimatedItemBackgroundStyle
import com.cyl.animateditem.CYLAnimatedItemView
import com.cyl.animateditem.CYLSize

/**
 * An animation played by CYLTabBarController's engine through a `CYLAnimatedItemView` (the cross-platform engine API:
 * `docs/Animated-Item.md`, "Engine API across platforms"). Props `source`, `playing`, `selected`, `animationSpeed`,
 * `animationLoops`, `animationRestartToken`, `drivesAnimationPlayback` (default true), `showsImageWhenAnimationEnds`, `image`, `iconSize`, `tintColor`, `animationTint`, `animationDarkTint`, `animationRenderingMode`, `itemBackgroundStyle`,
 * `itemBackgroundColor`, `itemCornerRadius`, `itemBorderWidth`, `itemBorderColor`; commands
 * `play`, `stopAtProgress`, `restart`; events `onAnimationLoaded`, `onAnimationFailed`, `onAnimationEnd`, `onResourceMissing`. No engine logic here.
 * 由 CYLTabBarController 引擎通过 `CYLAnimatedItemView` 播放的动画（跨端引擎 API，见 `docs/Animated-Item.md`）。
 */
class CyltabbarAnimationView(context: Context) : FrameLayout(context) {
  private val density = resources.displayMetrics.density
  private var iconSize: Float? = null
  private var imageRequest = 0

  /** Called with the event name ("loaded", "failed", "end"); the manager turns it into a React Native event. */
  var onEvent: ((String) -> Unit)? = null

  /** Called with the file as configured and the reason (`onResourceMissing`); the manager turns it into a React Native event. */
  var onResourceMissing: ((resource: String, reason: String) -> Unit)? = null

  val item = CYLAnimatedItemView(context).apply {
    // Icon only: the view React Native lays out is the icon's frame. 只有图标：React Native 布局的视图就是图标的范围。
    drivesAnimationPlayback = true
    animationEndListener = CYLAnimatedItemAnimationEndListener { onEvent?.invoke("end") }
    onAnimationLoaded = { onEvent?.invoke("loaded") }
    onAnimationFailed = { onEvent?.invoke("failed") }
    onResourceMissing = { resource, reason -> this@CyltabbarAnimationView.onResourceMissing?.invoke(resource, reason) }
  }

  init {
    addView(item, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
  }

  override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
    super.onSizeChanged(w, h, oldw, oldh)
    fitIcon()
  }

  /** The icon fills the view, or is `iconSize` (dp) when given. 图标铺满视图，给了 `iconSize`（dp）时为该尺寸。 */
  private fun fitIcon() {
    val side = iconSize
    val size = when {
      side != null -> CYLSize(side, side)
      width > 0 -> CYLSize(width / density, height / density)
      else -> return
    }
    if (item.iconSizeDp != size) item.iconSizeDp = size
  }

  fun applySource(value: String?) { item.animationURL = value?.takeIf { it.isNotBlank() } }

  fun applyPlaying(value: Boolean) { if (value) item.playAnimation() else item.stopAnimation() }

  fun applySelected(value: Boolean) { item.isSelected = value }

  fun applyAnimationSpeed(value: Float) { item.animationSpeed = value }

  fun applyAnimationLoops(value: Boolean) { item.animationLoops = value }

  fun applyAnimationRestartToken(value: Int) { item.animationRestartToken = value }

  fun applyDrivesAnimationPlayback(value: Boolean) { item.drivesAnimationPlayback = value }

  fun applyShowsImageWhenAnimationEnds(value: Boolean) { item.showsImageWhenAnimationEnds = value }

  /**
   * The still image `showsImageWhenAnimationEnds` shows, loaded like `source`; it is the item's own `image` (not the
   * placeholder), which `CYLAnimatedItemView` shows selected or not. null or blank clears it.
   */
  fun applyImage(value: String?) {
    val request = ++imageRequest
    val name = value?.takeIf { it.isNotBlank() } ?: run { item.image = null; return }
    CyltabbarStillImage.loadAsync(context, name) { drawable -> if (request == imageRequest) item.image = drawable }
  }

  /** `iconSize` in dp; 0 or less fills the view. */
  fun applyIconSize(value: Float) { iconSize = value.takeIf { it > 0f }; fitIcon() }

  /** `tintColor` as an ARGB int; null (unset) resets the item to its built-in default color, nothing is forced. */
  fun applyTintColor(value: Int?) { item.iconColor = value }

  /** `animationTint` ("title", "#RRGGBB", "#RRGGBBAA"); null or empty is not set (null). */
  fun applyAnimationTint(value: String?) { item.animationTint = value?.takeIf { it.isNotEmpty() } }

  /** `animationDarkTint`; null or empty is not set (null). */
  fun applyAnimationDarkTint(value: String?) { item.animationDarkTint = value?.takeIf { it.isNotEmpty() } }

  /** `animationRenderingMode` raw value: "automatic", "alwaysTemplate" or "alwaysOriginal"; null is "automatic". */
  fun applyAnimationRenderingMode(value: String?) { item.animationRenderingMode = com.cyl.animateditem.CYLAnimationRenderingMode.parse(value) ?: com.cyl.animateditem.CYLAnimationRenderingMode.Automatic }

  /** `itemBackgroundStyle`: "liquidGlass" or anything else (null, "flat") for flat. */
  fun applyItemBackgroundStyle(value: String?) {
    item.itemBackgroundStyle = if (value == "liquidGlass") CYLAnimatedItemBackgroundStyle.LiquidGlass else CYLAnimatedItemBackgroundStyle.Flat
  }

  /** `itemBackgroundColor` as an ARGB int; null clears it. */
  fun applyItemBackgroundColor(value: Int?) { item.itemBackgroundColor = value }

  /** `itemCornerRadius` in dp (the core limits it to half the height); a negative number is not set (null). */
  fun applyItemCornerRadius(value: Float) { item.itemCornerRadius = value.takeIf { it >= 0f } }

  /** `itemContentHorizontalInset` in dp, left and right; a negative number is not set (null): the glass default or 0 for flat. */
  fun applyItemContentHorizontalInset(value: Float) { item.itemContentHorizontalInset = value.takeIf { it >= 0f } }

  /** `itemBorderWidth` in dp. */
  fun applyItemBorderWidth(value: Float) { item.itemBorderWidth = value }

  /** `itemBorderColor` as an ARGB int; null clears it. */
  fun applyItemBorderColor(value: Int?) { item.itemBorderColor = value }

  private var badgeHidden = true
  private var badgeValue = ""
  private var badgeAttributesJSON = ""

  /**
   * The badge (docs/Animated-Item-Badge-CrossPlatform.md, phase 2): the item draws it, nothing here does. `badgeHidden` (the default) is no badge,
   * `badgeValue` "" a dot; the style keys arrive as JSON. The item is touched only when the result changes, so the animation does not replay.
   * Written statically, not compiled yet.
   */
  private fun applyBadge() {
    val value = if (badgeHidden) null else badgeValue
    if (item.badgeValue != value) item.badgeValue = value
    val attributes = badgeAttributesJSON.takeIf { it.isNotEmpty() }?.let { runCatching { org.json.JSONObject(it) }.getOrNull() }
      ?.let { json -> json.keys().asSequence().associateWith { key -> json.opt(key).takeIf { it !== org.json.JSONObject.NULL } } }
    if (item.badgeAttributes != attributes) item.badgeAttributes = attributes
  }

  fun applyBadgeValue(value: String?) { badgeValue = value ?: ""; applyBadge() }
  fun applyBadgeHidden(value: Boolean) { badgeHidden = value; applyBadge() }
  fun applyBadgeAttributesJSON(value: String?) { badgeAttributesJSON = value ?: ""; applyBadge() }
  fun applyReservesBadgeSpace(value: Boolean) { item.reservesBadgeSpace = value }

  fun play() = item.animatedItemPlayer.play()

  fun stopAtProgress(progress: Float) = item.animatedItemPlayer.stopAtProgress(progress)

  fun restart() = item.restartAnimation()

  // React Native does not lay out views it did not create. React Native 不布局它没有创建的视图。
  private val measureAndLayout = Runnable {
    measure(MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY), MeasureSpec.makeMeasureSpec(height, MeasureSpec.EXACTLY))
    layout(left, top, right, bottom)
  }

  override fun requestLayout() {
    super.requestLayout()
    post(measureAndLayout)
  }
}
