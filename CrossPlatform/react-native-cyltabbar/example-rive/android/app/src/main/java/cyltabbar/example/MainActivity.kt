package cyltabbar.example

import android.os.Bundle
import com.cyl.tabbar.demo.DemoAssets
import com.facebook.react.ReactActivity
import com.facebook.react.ReactActivityDelegate
import com.facebook.react.defaults.DefaultReactActivityDelegate

class MainActivity : ReactActivity() {

  /**
   * Returns the name of the main component registered from JavaScript. This is used to schedule
   * rendering of the component.
   */
  override fun getMainComponentName(): String = "CyltabbarExample"

  override fun onCreate(savedInstanceState: Bundle?) {
    // [EN] Image names of the configuration ("Home", "tabbar_database") come from the iOS asset catalog in the assets.
    // [CN] 配置中的图片名（"Home"、"tabbar_database"）来自 assets 中的 iOS 资源目录。
    DemoAssets.install()
    super.onCreate(null)
  }

  /**
   * Returns the instance of the [ReactActivityDelegate]. We use [DefaultReactActivityDelegate]
   * which allows you to enable New Architecture with a the New Architecture always on
   */
  override fun createReactActivityDelegate(): ReactActivityDelegate =
      DefaultReactActivityDelegate(this, mainComponentName)
}
