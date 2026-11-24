package com.cyl.tabbar.demo

import android.graphics.Typeface
import android.os.Bundle
import android.view.Gravity
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

/**
 * [EN] What the task shows after the tab bar controller was released (iOS `CYLDemoReleasedViewController`): the dealloc callbacks that ran,
 *      refreshed until they all ran, because the old host activity is destroyed a moment after this one starts.
 * [CN] TabBarController 被释放后任务显示的内容（对应 iOS 的 `CYLDemoReleasedViewController`）：已执行的 dealloc 回调，
 *      直到全部执行完为止持续刷新，因为旧的宿主 Activity 在本 Activity 启动之后才被销毁。
 */
class DemoReleasedActivity : AppCompatActivity() {
    private lateinit var label: TextView
    private val listener: () -> Unit = { refresh() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        DemoText.attach(this)
        label = TextView(this).apply {
            textSize = 17f
            typeface = Typeface.MONOSPACE
            gravity = Gravity.CENTER
            setPadding(48, 48, 48, 48)
            contentDescription = null
        }
        setContentView(label)
        refresh()
    }

    override fun onStart() {
        super.onStart()
        DemoTeardown.addListener(listener)
        refresh()
    }

    override fun onStop() {
        DemoTeardown.removeListener(listener)
        super.onStop()
    }

    private fun refresh() {
        label.text = cylDemoText("Tab bar controller released") + "\n\n" + DemoTeardown.summary()
    }
}
