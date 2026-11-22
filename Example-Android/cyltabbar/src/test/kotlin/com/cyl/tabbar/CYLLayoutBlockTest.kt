package com.cyl.tabbar

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [EN] The layout block, run through CYLDeallocBlockExecutor (the keyed callback `cyl.core.layoutBlock`): one-time, every
 *      time, and re-armed by a new set of tabs (a theme switch, a reload), as on iOS.
 * [CN] 通过 CYLDeallocBlockExecutor 执行的布局 block（带 key 的回调 `cyl.core.layoutBlock`）：只执行一次、每次执行，以及重新设置 Tab（换肤、重新加载）后重新启用，与 iOS 相同。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLLayoutBlockTest : CYLRobolectricTestCase() {

    private fun CYLTabBarController.resetTabs() {
        setViewControllers(listOf(CYLTestPage(), CYLTestPage()), attributes("One", "Two"))
        idle()
    }

    @Test
    fun theOneTimeBlockRunsAfterTheNextSetOfTabsAndIsRearmedByTheNext() = withActivity { activity ->
        val controller = controllerWith(activity, "One", "Two")
        var runs = 0
        controller.setViewDidLayoutSubViewsBlockInvokeOnce(true) { runs++ }
        assertEquals("setting the block runs nothing", 0, runs)
        controller.resetTabs()
        assertEquals(1, runs)
        // [EN] Behavior change on Android: the block is kept after its run (it was cleared before), so a new set of tabs runs it again. [CN] Android 上的行为变化：block 在执行后保留（之前会被清除），因此重新设置 Tab 会再次执行。
        assertNotNull(controller.viewDidLayoutSubviewsBlock)
        controller.resetTabs()
        assertEquals(2, runs)
    }

    @Test
    fun aThemeSwitchRearmsTheOneTimeBlock() = withActivity { activity ->
        val controller = controllerWith(activity, "One", "Two")
        var runs = 0
        controller.setViewDidLayoutSubViewsBlockInvokeOnce(true) { runs++ }
        controller.resetTabs()
        assertEquals(1, runs)
        controller.cyl_applyTabBarTheme(null)
        idle()
        assertEquals(2, runs)
    }

    @Test
    fun theEveryTimeBlockRunsAtEverySetOfTabs() = withActivity { activity ->
        val controller = controllerWith(activity, "One", "Two")
        var runs = 0
        controller.setViewDidLayoutSubViewsBlock { runs++ }
        controller.resetTabs()
        controller.resetTabs()
        assertEquals(2, runs)
    }

    @Test
    fun theBlockPropertyIsReadWhenItRuns() = withActivity { activity ->
        val controller = controllerWith(activity, "One", "Two")
        val log = mutableListOf<String>()
        controller.setViewDidLayoutSubViewsBlock { log.add("first") }
        controller.viewDidLayoutSubviewsBlock = { log.add("second") }
        controller.resetTabs()
        assertEquals(listOf("second"), log)
        controller.viewDidLayoutSubviewsBlock = null
        controller.resetTabs()
        assertEquals(listOf("second"), log)
    }

    @Test
    fun anOneTimeBlockSetAfterAnEveryTimeBlockReplacesIt() = withActivity { activity ->
        val controller = controllerWith(activity, "One", "Two")
        val log = mutableListOf<String>()
        controller.setViewDidLayoutSubViewsBlock { log.add("every") }
        controller.setViewDidLayoutSubViewsBlockInvokeOnce(true) { log.add("once") }
        controller.resetTabs()
        assertEquals(listOf("once"), log)
    }
}
