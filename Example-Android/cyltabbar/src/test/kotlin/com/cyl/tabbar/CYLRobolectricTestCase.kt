package com.cyl.tabbar

import android.os.Bundle
import android.os.Looper
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import org.robolectric.Robolectric
import org.robolectric.Shadows.shadowOf
import java.time.Duration

/** [EN] A page with a view, so swipes and pagers have something to show. [CN] 带视图的页面，滑动与翻页控件有内容可显示。 */
class CYLTestPage : Fragment() {
    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View = FrameLayout(inflater.context)
}

/**
 * [EN] What the Robolectric tests of the tab bar controller share: an activity, the main looper, and a controller on screen.
 * [CN] TabBarController 的 Robolectric 测试共用的部分：Activity、主线程 looper，以及显示在屏幕上的控制器。
 */
abstract class CYLRobolectricTestCase {
    protected fun attributes(vararg titles: String) = titles.map { mapOf(CYLConstants.CYLTabBarItemTitle to it, CYLConstants.CYLTabBarItemIdentifier to it.lowercase()) }

    protected fun <T> withActivity(block: (FragmentActivity) -> T): T {
        val controller = Robolectric.buildActivity(FragmentActivity::class.java).setup()
        try {
            return block(controller.get())
        } finally {
            controller.pause().stop().destroy()
        }
    }

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
