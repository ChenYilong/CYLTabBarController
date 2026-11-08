package com.cyl.tabbar.flutter_cyltabbar_example_pag

import android.os.Bundle
import com.cyl.tabbar.demo.DemoAssets
import io.flutter.embedding.android.FlutterFragmentActivity

// [EN] CYLTabBar's Android tab bar controller needs a FragmentActivity. [CN] CYLTabBar 的 Android TabBarController 需要 FragmentActivity。
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // [EN] Image names of the configuration come from the iOS asset catalog in the assets. [CN] 配置中的图片名来自 assets 中的 iOS 资源目录。
        DemoAssets.install()
        super.onCreate(savedInstanceState)
    }
}
