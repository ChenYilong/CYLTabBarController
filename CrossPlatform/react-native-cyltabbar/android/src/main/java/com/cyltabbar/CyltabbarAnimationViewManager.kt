package com.cyltabbar

import com.facebook.react.bridge.Arguments
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.uimanager.events.Event
import com.facebook.react.viewmanagers.CyltabbarAnimationViewManagerDelegate
import com.facebook.react.viewmanagers.CyltabbarAnimationViewManagerInterface

@ReactModule(name = CyltabbarAnimationViewManager.NAME)
class CyltabbarAnimationViewManager : SimpleViewManager<CyltabbarAnimationView>(), CyltabbarAnimationViewManagerInterface<CyltabbarAnimationView> {
  private val delegate: ViewManagerDelegate<CyltabbarAnimationView> = CyltabbarAnimationViewManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<CyltabbarAnimationView> = delegate

  override fun getName(): String = NAME

  override fun createViewInstance(context: ThemedReactContext): CyltabbarAnimationView = CyltabbarAnimationView(context).also { view ->
    view.onEvent = { name ->
      UIManagerHelper.getEventDispatcher(context)?.dispatchEvent(AnimationEvent(UIManagerHelper.getSurfaceId(view), view.id, name))
    }
    view.onResourceMissing = { resource, reason ->
      UIManagerHelper.getEventDispatcher(context)?.dispatchEvent(ResourceMissingEvent(UIManagerHelper.getSurfaceId(view), view.id, resource, reason))
    }
  }

  @ReactProp(name = "source")
  override fun setSource(view: CyltabbarAnimationView?, value: String?) {
    view?.applySource(value)
  }

  @ReactProp(name = "playing")
  override fun setPlaying(view: CyltabbarAnimationView?, value: Boolean) {
    view?.applyPlaying(value)
  }

  @ReactProp(name = "selected")
  override fun setSelected(view: CyltabbarAnimationView?, value: Boolean) {
    view?.applySelected(value)
  }

  @ReactProp(name = "animationSpeed", defaultFloat = 1f)
  override fun setAnimationSpeed(view: CyltabbarAnimationView?, value: Float) {
    view?.applyAnimationSpeed(value)
  }

  @ReactProp(name = "animationLoops")
  override fun setAnimationLoops(view: CyltabbarAnimationView?, value: Boolean) {
    view?.applyAnimationLoops(value)
  }

  @ReactProp(name = "animationRestartToken")
  override fun setAnimationRestartToken(view: CyltabbarAnimationView?, value: Int) {
    view?.applyAnimationRestartToken(value)
  }

  @ReactProp(name = "drivesAnimationPlayback", defaultBoolean = true)
  override fun setDrivesAnimationPlayback(view: CyltabbarAnimationView?, value: Boolean) {
    view?.applyDrivesAnimationPlayback(value)
  }

  @ReactProp(name = "showsImageWhenAnimationEnds")
  override fun setShowsImageWhenAnimationEnds(view: CyltabbarAnimationView?, value: Boolean) {
    view?.applyShowsImageWhenAnimationEnds(value)
  }

  @ReactProp(name = "image")
  override fun setImage(view: CyltabbarAnimationView?, value: String?) {
    view?.applyImage(value)
  }

  @ReactProp(name = "iconSize")
  override fun setIconSize(view: CyltabbarAnimationView?, value: Float) {
    view?.applyIconSize(value)
  }

  @ReactProp(name = "tintColor", customType = "Color")
  override fun setTintColor(view: CyltabbarAnimationView?, value: Int?) {
    view?.applyTintColor(value)
  }

  @ReactProp(name = "animationTint")
  override fun setAnimationTint(view: CyltabbarAnimationView?, value: String?) {
    view?.applyAnimationTint(value)
  }

  @ReactProp(name = "animationDarkTint")
  override fun setAnimationDarkTint(view: CyltabbarAnimationView?, value: String?) {
    view?.applyAnimationDarkTint(value)
  }

  @ReactProp(name = "animationRenderingMode")
  override fun setAnimationRenderingMode(view: CyltabbarAnimationView?, value: String?) {
    view?.applyAnimationRenderingMode(value)
  }

  @ReactProp(name = "itemBackgroundStyle")
  override fun setItemBackgroundStyle(view: CyltabbarAnimationView?, value: String?) {
    view?.applyItemBackgroundStyle(value)
  }

  @ReactProp(name = "itemBackgroundColor", customType = "Color")
  override fun setItemBackgroundColor(view: CyltabbarAnimationView?, value: Int?) {
    view?.applyItemBackgroundColor(value)
  }

  @ReactProp(name = "itemCornerRadius", defaultFloat = -1f)
  override fun setItemCornerRadius(view: CyltabbarAnimationView?, value: Float) {
    view?.applyItemCornerRadius(value)
  }

  @ReactProp(name = "itemContentHorizontalInset", defaultFloat = -1f)
  override fun setItemContentHorizontalInset(view: CyltabbarAnimationView?, value: Float) {
    view?.applyItemContentHorizontalInset(value)
  }

  @ReactProp(name = "itemBorderWidth")
  override fun setItemBorderWidth(view: CyltabbarAnimationView?, value: Float) {
    view?.applyItemBorderWidth(value)
  }

  @ReactProp(name = "itemBorderColor", customType = "Color")
  override fun setItemBorderColor(view: CyltabbarAnimationView?, value: Int?) {
    view?.applyItemBorderColor(value)
  }

  override fun play(view: CyltabbarAnimationView?) {
    view?.play()
  }

  override fun stopAtProgress(view: CyltabbarAnimationView?, progress: Float) {
    view?.stopAtProgress(progress)
  }

  override fun restart(view: CyltabbarAnimationView?) {
    view?.restart()
  }

  override fun getExportedCustomDirectEventTypeConstants(): MutableMap<String, Any> = mutableMapOf(
    "topAnimationLoaded" to mapOf("registrationName" to "onAnimationLoaded"),
    "topAnimationFailed" to mapOf("registrationName" to "onAnimationFailed"),
    "topAnimationEnd" to mapOf("registrationName" to "onAnimationEnd"),
    "topResourceMissing" to mapOf("registrationName" to "onResourceMissing"),
  )

  /** `loaded`, `failed` or `end`, sent as `topAnimationLoaded`, `topAnimationFailed` or `topAnimationEnd`. */
  private class AnimationEvent(surfaceId: Int, viewId: Int, private val name: String) : Event<AnimationEvent>(surfaceId, viewId) {
    override fun getEventName(): String = "topAnimation" + name.replaceFirstChar { it.uppercase() }

    override fun getEventData() = Arguments.createMap()
  }

  /** `onResourceMissing`: the file as configured and the reason, unchanged from `CYLAnimatedItemView.onResourceMissing`. */
  private class ResourceMissingEvent(surfaceId: Int, viewId: Int, private val resource: String, private val reason: String) : Event<ResourceMissingEvent>(surfaceId, viewId) {
    override fun getEventName(): String = "topResourceMissing"

    override fun getEventData() = Arguments.createMap().apply {
      putString("resource", resource)
      putString("reason", reason)
    }
  }

  companion object {
    const val NAME = "CyltabbarAnimationView"
  }
}
