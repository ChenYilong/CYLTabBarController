package com.cyl.tabbar

import android.os.Bundle
import android.os.Looper
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import org.robolectric.Shadows.shadowOf
import java.time.Duration

/** [EN] A page with a view, so swipes and pagers have something to show. [CN] 带视图的页面，滑动与翻页控件有内容可显示。 */
class CYLTestPage : Fragment() {
    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View = FrameLayout(inflater.context)
}

/**
 * [EN] What the Robolectric tests of the tab bar controller share besides CYLTestSupport.kt: the main looper run for a while, and a controller on screen.
 * [CN] 除 CYLTestSupport.kt 外，TabBarController 的 Robolectric 测试共用的部分：运行一段时间的主线程 looper，以及显示在屏幕上的控制器。
 */
abstract class CYLRobolectricTestCase {
    /** [EN] Runs the main looper for `seconds`, so animators end (`withActivity` and `attributes` come from CYLTestSupport.kt). [CN] 让主线程 Looper 运行 `seconds` 秒，使动画结束（`withActivity` 与 `attributes` 来自 CYLTestSupport.kt）。 */
    protected fun idle(seconds: Long = 1) {
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(seconds))
    }

    /** [EN] A controller with one `CYLTestPage` per title, shown in the activity. [CN] 每个标题一个 `CYLTestPage` 的控制器，显示在 Activity 中。 */
    protected fun controllerWith(activity: FragmentActivity, vararg titles: String): CYLTabBarController {
        val controller = CYLTabBarController(activity, titles.map { CYLTestPage() }, attributes(*titles))
        activity.setContentView(controller.view)
        idle()
        return controller
    }
}
