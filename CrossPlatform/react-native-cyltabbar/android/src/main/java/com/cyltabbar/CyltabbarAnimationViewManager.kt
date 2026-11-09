package com.cyltabbar

import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.CyltabbarAnimationViewManagerDelegate
import com.facebook.react.viewmanagers.CyltabbarAnimationViewManagerInterface

@ReactModule(name = CyltabbarAnimationViewManager.NAME)
class CyltabbarAnimationViewManager : SimpleViewManager<CyltabbarAnimationView>(), CyltabbarAnimationViewManagerInterface<CyltabbarAnimationView> {
  private val delegate: ViewManagerDelegate<CyltabbarAnimationView> = CyltabbarAnimationViewManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<CyltabbarAnimationView> = delegate

  override fun getName(): String = NAME

  override fun createViewInstance(context: ThemedReactContext): CyltabbarAnimationView = CyltabbarAnimationView(context)

  @ReactProp(name = "source")
  override fun setSource(view: CyltabbarAnimationView?, value: String?) {
    view?.applySource(value)
  }

  @ReactProp(name = "playing")
  override fun setPlaying(view: CyltabbarAnimationView?, value: Boolean) {
    view?.applyPlaying(value)
  }

  companion object {
    const val NAME = "CyltabbarAnimationView"
  }
}
