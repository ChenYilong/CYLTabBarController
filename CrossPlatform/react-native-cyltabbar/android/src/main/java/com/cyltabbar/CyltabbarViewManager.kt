package com.cyltabbar

import com.cyl.tabbar.CYLEnums
import com.cyl.tabbar.CYLTabBarHostView
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

  @ReactProp(name = "badgeStyles")
  override fun setBadgeStyles(view: CyltabbarView?, value: String?) {
    val list = value?.takeIf { it.isNotEmpty() }?.let { runCatching { org.json.JSONArray(it) }.getOrNull() }
    view?.badgeAttributes = list?.let { array -> (0 until array.length()).map { (array.opt(it) as? org.json.JSONObject)?.let(CYLTabBarHostView::toMap) } }.orEmpty()
  }

  @ReactProp(name = "plusButtonBadgeStyle")
  override fun setPlusButtonBadgeStyle(view: CyltabbarView?, value: String?) {
    view?.plusButtonBadgeAttributes = value?.takeIf { it.isNotEmpty() }?.let { runCatching { CYLTabBarHostView.toMap(org.json.JSONObject(it)) }.getOrNull() }
  }

  /** [EN] 1 logged in, 0 logged out, -1 not set: the host uses the cached state. [CN] 1 已登录，0 未登录，-1 未设置：宿主使用缓存的状态。 */
  @ReactProp(name = "loginState", defaultInt = -1)
  override fun setLoginState(view: CyltabbarView?, value: Int) {
    if (value >= 0) view?.loggedIn = value == 1 else view?.resetLoggedIn()
  }

  /** [EN] The language of the library's texts and layout direction; "" for the device language. [CN] 库文字与布局方向使用的语言；"" 表示设备语言。 */
  @ReactProp(name = "language")
  override fun setLanguage(view: CyltabbarView?, value: String?) {
    view?.language = value?.takeIf { it.isNotEmpty() }
  }

  /** [EN] Hides the tab bar, animated; a hidden tab bar takes no touches. [CN] 隐藏 TabBar（带动画）；隐藏的 TabBar 不接收触摸。 */
  @ReactProp(name = "tabBarHidden")
  override fun setTabBarHidden(view: CyltabbarView?, value: Boolean) {
    view?.tabBarHidden = value
  }

  /** [EN] Each increase simulates a memory warning once (onMemoryWarning). [CN] 每次增大模拟一次内存警告（onMemoryWarning）。 */
  @ReactProp(name = "memoryWarningRequest", defaultInt = 0)
  override fun setMemoryWarningRequest(view: CyltabbarView?, value: Int) {
    view?.memoryWarningRequest = value
  }

  /** [EN] The playback speed of every tab icon animation; 0 or less: the library's default. [CN] 所有 Tab 图标动画的播放速度；0 或更小表示库的默认值。 */
  @ReactProp(name = "playbackSpeed", defaultFloat = 0f)
  override fun setPlaybackSpeed(view: CyltabbarView?, value: Float) {
    view?.animationSpeed = value
  }

  /** [EN] Whether the tab icon animations repeat until this is false. [CN] Tab 图标动画是否重复播放直到设为 false。 */
  @ReactProp(name = "playbackLoops")
  override fun setPlaybackLoops(view: CyltabbarView?, value: Boolean) {
    view?.animationLoops = value
  }

  /** [EN] Each increase plays every tab icon animation again from progress 0 ("Play all"). [CN] 每次增大让所有 Tab 图标动画从进度 0 重新播放（「全部播放」）。 */
  @ReactProp(name = "playAllRequest", defaultInt = 0)
  override fun setPlayAllRequest(view: CyltabbarView?, value: Int) {
    view?.playAllRequest = value
  }

  /** [EN] [horizontal, vertical], set at runtime; empty keeps the configuration's. [CN] [水平, 垂直]，运行时设置；为空时使用配置中的值。 */
  @ReactProp(name = "titlePositionAdjustment")
  override fun setTitlePositionAdjustment(view: CyltabbarView?, value: ReadableArray?) {
    view?.titlePositionAdjustment = value?.takeIf { it.size() >= 2 }?.let { com.cyl.tabbar.CYLOffset(it.getDouble(0).toFloat(), it.getDouble(1).toFloat()) }
  }

  @ReactProp(name = "tabCoverImages")
  override fun setTabCoverImages(view: CyltabbarView?, value: ReadableArray?) {
    view?.tabCoverImages = (0 until (value?.size() ?: 0)).map { value?.getString(it)?.takeIf { image -> image.isNotEmpty() } }
  }

  override fun getExportedCustomDirectEventTypeConstants(): MutableMap<String, Any> = mutableMapOf(
    "topTabSelect" to mapOf("registrationName" to "onTabSelect"),
    "topPlusButtonPress" to mapOf("registrationName" to "onPlusButtonPress"),
    "topTabBarLayout" to mapOf("registrationName" to "onTabBarLayout"),
    "topTabLongPress" to mapOf("registrationName" to "onTabLongPress"),
    "topLoginRequest" to mapOf("registrationName" to "onLoginRequest"),
    "topLoginStateChange" to mapOf("registrationName" to "onLoginStateChange"),
    "topMemoryWarning" to mapOf("registrationName" to "onMemoryWarning"),
  )

  companion object {
    const val NAME = "CyltabbarView"
  }
}
