package com.cyl.tabbar

import com.chenyilong.cyldeallocblockexecutor.BadgeEvents
import com.chenyilong.cyldeallocblockexecutor.LifecycleCenter
import com.chenyilong.cyldeallocblockexecutor.LifecycleRegistry
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [EN] The badge posts its moments through CYLDeallocBlockExecutor: on the view the app called, on the tab's item through the forward, and to every global observer once.
 * [CN] 角标通过 CYLDeallocBlockExecutor 发出时机事件：在 App 调用的视图上、经转发在该 Tab 的 item 上，以及对每个全局观察者发出一次。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLBadgeEventsTest : CYLRobolectricTestCase() {

    @After fun reset() = LifecycleCenter.reset()

    @Test
    fun theViewAndItsItemHearShowAndClearAndTheGlobalObserverHearsThemOnce() = withActivity { activity ->
        val controller = CYLTabBarController(activity, listOf(CYLTestPage(), CYLTestPage()), attributes("Home", "Me"))
        activity.setContentView(controller.view)
        idle()
        val item = controller.tabBarItems[1]
        val button = controller.tabBar.tabBarButtonArray[1]
        val heard = ArrayList<String>()
        LifecycleRegistry.of(item).addCustomCallback<Any>(BadgeEvents.didShow) { _, _, info -> heard += "item show ${info.userInfo?.get("value")}" }
        LifecycleRegistry.of(item).addCustomCallback<Any>(BadgeEvents.didClear) { _, _, _ -> heard += "item clear" }
        LifecycleRegistry.of(button).addCustomCallback<Any>(BadgeEvents.didShow) { _, _, _ -> heard += "button show" }
        LifecycleCenter.addCustomCallback<Any>(BadgeEvents.didShow) { owner, _, _ -> heard += "global show ${owner === button}" }
        item.cyl_showBadgeValue("3", CYLEnums.CYLBadgeAnimationType.None)
        item.cyl_clearBadge()
        assertEquals(listOf("button show", "item show 3", "global show true", "item clear"), heard)
    }

    @Test
    fun aRepeatingBadgeAnimationReportsStartAndTheCancelOnClear() = withActivity { activity ->
        val controller = CYLTabBarController(activity, listOf(CYLTestPage(), CYLTestPage()), attributes("Home", "Me"))
        activity.setContentView(controller.view)
        idle()
        val button = controller.tabBar.tabBarButtonArray[1]
        val heard = ArrayList<String>()
        LifecycleRegistry.of(button).addCustomCallback<Any>(BadgeEvents.animationDidStart) { _, _, info -> heard += "start ${info.userInfo?.get("animationType")}" }
        LifecycleRegistry.of(button).addCustomCallback<Any>(BadgeEvents.animationDidStop) { _, _, info -> heard += "stop finished=${info.userInfo?.get("finished")}" }
        button.cyl_showBadgeValue("1", CYLEnums.CYLBadgeAnimationType.Shake)
        button.cyl_clearBadge()
        assertEquals(listOf("start Shake", "stop finished=false"), heard)
    }
}
