package com.cyltabbar

import com.cyl.tabbar.CYLEnums
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.CyltabbarViewManagerInterface
import com.facebook.react.viewmanagers.CyltabbarViewManagerDelegate

@ReactModule(name = CyltabbarViewManager.NAME)
class CyltabbarViewManager : SimpleViewManager<CyltabbarView>(),
  CyltabbarViewManagerInterface<CyltabbarView> {
  private val mDelegate: ViewManagerDelegate<CyltabbarView>

  init {
    mDelegate = CyltabbarViewManagerDelegate(this)
  }

  override fun getDelegate(): ViewManagerDelegate<CyltabbarView>? {
    return mDelegate
  }

  override fun getName(): String {
    return NAME
  }

  public override fun createViewInstance(context: ThemedReactContext): CyltabbarView {
    return CyltabbarView(context)
  }

  @ReactProp(name = "configuration")
  override fun setConfiguration(view: CyltabbarView?, value: String?) {
    view?.applyConfigurationJSON(value)
  }

  @ReactProp(name = "selectedIndex", defaultInt = -1)
  override fun setSelectedIndex(view: CyltabbarView?, value: Int) {
    view?.selectedIndex = value
  }

  @ReactProp(name = "badgeValues")
  override fun setBadgeValues(view: CyltabbarView?, value: ReadableArray?) {
    view?.badgeValues = (0 until (value?.size() ?: 0)).map { value?.getString(it).orEmpty() }
  }

  @ReactProp(name = "plusButtonBadgeValue")
  override fun setPlusButtonBadgeValue(view: CyltabbarView?, value: String?) {
    view?.plusButtonBadgeValue = value
  }

  @ReactProp(name = "badgeAnimation", defaultInt = 0)
  override fun setBadgeAnimation(view: CyltabbarView?, value: Int) {
    view?.badgeAnimationType = CYLEnums.CYLBadgeAnimationType.values().firstOrNull { it.rawValue == value } ?: CYLEnums.CYLBadgeAnimationType.None
  }

  override fun getExportedCustomDirectEventTypeConstants(): MutableMap<String, Any> = mutableMapOf(
    "topTabSelect" to mapOf("registrationName" to "onTabSelect"),
    "topPlusButtonPress" to mapOf("registrationName" to "onPlusButtonPress"),
    "topTabBarLayout" to mapOf("registrationName" to "onTabBarLayout"),
    "topTabLongPress" to mapOf("registrationName" to "onTabLongPress"),
  )

  companion object {
    const val NAME = "CyltabbarView"
  }
}
