package com.cyl.tabbar

import android.widget.AbsListView
import android.widget.ListView
import com.chenyilong.cyldeallocblockexecutor.LifecycleCenter
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [EN] A ListView reports its scroll states to the global observers: touch scroll pauses, idle (after a fling) resumes, once each.
 * [CN] ListView 把滚动状态报告给全局观察者：触摸滚动时暂停，甩动后空闲时恢复，各一次。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLScrollReportingTest : CYLRobolectricTestCase() {

    @After fun reset() = LifecycleCenter.reset()

    @Test
    fun aDragWithAFlingPausesOnceAndResumesWhenIdle() = withActivity { activity ->
        val list = ListView(activity)
        val log = ArrayList<String>()
        LifecycleCenter.whileUserScrolls(pause = { log += "pause" }, resume = { log += "resume" })
        CYLScrollReporting.listViewScrollStateChanged(list, AbsListView.OnScrollListener.SCROLL_STATE_TOUCH_SCROLL)
        CYLScrollReporting.listViewScrollStateChanged(list, AbsListView.OnScrollListener.SCROLL_STATE_FLING)
        CYLScrollReporting.listViewScrollStateChanged(list, AbsListView.OnScrollListener.SCROLL_STATE_IDLE)
        assertEquals(listOf("pause", "resume"), log)
        CYLScrollReporting.listViewScrollStateChanged(list, AbsListView.OnScrollListener.SCROLL_STATE_TOUCH_SCROLL)
        CYLScrollReporting.listViewScrollStateChanged(list, AbsListView.OnScrollListener.SCROLL_STATE_IDLE)
        assertEquals(listOf("pause", "resume", "pause", "resume"), log)
    }
}
