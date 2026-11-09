package com.cyltabbar

import androidx.fragment.app.FragmentActivity
import com.cyl.tabbar.CYLTabBarHostView
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.PointerEvents
import com.facebook.react.uimanager.ReactPointerEventsView
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.Event

/**
 * The Fabric view of `react-native-cyltabbar` on Android: a [CYLTabBarHostView] (a CYLTabBarController made from a
 * configuration, showing only its tab bar) with React Native events.
 */
class CyltabbarView(private val reactContext: ThemedReactContext) : CYLTabBarHostView(reactContext), ReactPointerEventsView {

  // [EN] "box-none": React Native's hit test looks only at what the view holds. The host leaves the strip above the bar empty
  //      except for the plus button and its badge, so a touch elsewhere in it reaches the React views below.
  // [CN] "box-none"：React Native 的命中测试只查看视图中的内容。宿主让 TabBar 上方的区域只有 PlusButton 与其角标，因此落在其他位置的
  //      触摸会交给下方的 React 视图。
  override val pointerEvents: PointerEvents = PointerEvents.BOX_NONE

  init {
    activityProvider = { reactContext.currentActivity as? FragmentActivity }
    // [EN] Android delivers a touch only to a view that contains it: the component also holds what rises above the bar (the
    //      plus button, the badges), or the plus button could not be tapped there.
    // [CN] Android 只把触摸分发给包含触摸点的视图：组件高度同时包含高出 TabBar 的部分（PlusButton、角标），否则那里的 PlusButton 无法点击。
    heightIncludesOverflow = true
    didSelectTab = { index, identifier -> dispatch(TabSelectEvent(surfaceId(), id, index, identifier)) }
    didTapPlusButton = { dispatch(PlusButtonPressEvent(surfaceId(), id, tabBarController?.context.orEmpty())) }
    preferredHeightDidChange = { height -> dispatch(TabBarLayoutEvent(surfaceId(), id, height.toDouble())) }
    didLongPressTab = { index, identifier, title -> dispatch(TabLongPressEvent(surfaceId(), id, index, identifier, title)) }
    didRequestLogin = { index, identifier, title -> dispatch(TabLongPressEvent(surfaceId(), id, index, identifier, title, "topLoginRequest")) }
    loginStateDidChange = { loggedIn -> dispatch(LoginStateEvent(surfaceId(), id, loggedIn)) }
  }

  private var configurationJSON: String? = null

  /** [EN] The last memory warning request handled; a higher one simulates a memory warning once. [CN] 最近处理的内存警告请求；更大的值模拟一次内存警告。 */
  var memoryWarningRequest = 0
    set(value) {
      if (value > field) dispatch(MemoryWarningEvent(surfaceId(), id, simulateMemoryWarning()))
      field = value
    }

  fun applyConfigurationJSON(json: String?) {
    if (json == configurationJSON) return
    configurationJSON = json
    if (!setConfigurationJSON(json)) configuration = null
  }

  // React Native does not lay out views it did not create: measure and lay out the tab bar controller here.
  private val measureAndLayout = Runnable {
    measure(MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY), MeasureSpec.makeMeasureSpec(height, MeasureSpec.EXACTLY))
    layout(left, top, right, bottom)
  }

  override fun requestLayout() {
    super.requestLayout()
    post(measureAndLayout)
  }

  private fun surfaceId() = UIManagerHelper.getSurfaceId(this)

  private fun dispatch(event: Event<*>) {
    UIManagerHelper.getEventDispatcher(reactContext)?.dispatchEvent(event)
  }
}

class TabSelectEvent(surfaceId: Int, viewId: Int, private val index: Int, private val identifier: String) :
  Event<TabSelectEvent>(surfaceId, viewId) {
  override fun getEventName() = "topTabSelect"
  override fun getEventData(): WritableMap = Arguments.createMap().apply {
    putInt("index", index)
    putString("identifier", identifier)
  }
}

/** [EN] A tab with its title: a long press, or a login request (`topLoginRequest`). [CN] 带标题的 Tab 事件：长按或登录请求。 */
class TabLongPressEvent(
  surfaceId: Int,
  viewId: Int,
  private val index: Int,
  private val identifier: String,
  private val title: String,
  private val name: String = "topTabLongPress",
) : Event<TabLongPressEvent>(surfaceId, viewId) {
  override fun getEventName() = name
  override fun getEventData(): WritableMap = Arguments.createMap().apply {
    putInt("index", index)
    putString("identifier", identifier)
    putString("title", title)
  }
}

class MemoryWarningEvent(surfaceId: Int, viewId: Int, private val report: String) : Event<MemoryWarningEvent>(surfaceId, viewId) {
  override fun getEventName() = "topMemoryWarning"
  override fun getEventData(): WritableMap = Arguments.createMap().apply { putString("report", report) }
}

class LoginStateEvent(surfaceId: Int, viewId: Int, private val loggedIn: Boolean) : Event<LoginStateEvent>(surfaceId, viewId) {
  override fun getEventName() = "topLoginStateChange"
  override fun getEventData(): WritableMap = Arguments.createMap().apply { putBoolean("loggedIn", loggedIn) }
}

class PlusButtonPressEvent(surfaceId: Int, viewId: Int, private val context: String) : Event<PlusButtonPressEvent>(surfaceId, viewId) {
  override fun getEventName() = "topPlusButtonPress"
  override fun getEventData(): WritableMap = Arguments.createMap().apply { putString("context", context) }
}

class TabBarLayoutEvent(surfaceId: Int, viewId: Int, private val height: Double) : Event<TabBarLayoutEvent>(surfaceId, viewId) {
  override fun getEventName() = "topTabBarLayout"
  override fun getEventData(): WritableMap = Arguments.createMap().apply { putDouble("height", height) }
}
