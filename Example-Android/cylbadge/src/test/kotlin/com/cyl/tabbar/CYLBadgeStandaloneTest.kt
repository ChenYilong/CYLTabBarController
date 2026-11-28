package com.cyl.tabbar

import android.app.Activity
import android.graphics.Color
import android.view.View
import android.widget.FrameLayout
import com.chenyilong.cyldeallocblockexecutor.LifecycleRegistry
import com.cyl.animateditem.CYLOffset
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [EN] CYLBadge on its own, with neither the item nor the tab bar module on the class path (criterion P1-2): the value rules, clearing,
 *      the style keys and the badge events on a plain View.
 * [CN] 单独的 CYLBadge，类路径上既没有 item 模块也没有 TabBar 模块（验收项 P1-2）：普通 View 上的取值规则、清除、样式键与角标事件。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLBadgeStandaloneTest {

    private fun hostView(): View {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        val parent = FrameLayout(activity)
        val view = View(activity)
        parent.addView(view, FrameLayout.LayoutParams(100, 100))
        activity.setContentView(parent)
        return view
    }

    @Test
    fun theItemAndTabBarModulesAreNotOnTheClassPath() {
        for (name in listOf("com.cyl.animateditem.CYLAnimatedItemView", "com.cyl.tabbar.CYLTabBarController")) {
            assertTrue(name, runCatching { Class.forName(name) }.isFailure)
        }
    }

    @Test
    fun anEmptyValueIsADotAndAnyOtherTextIsShownAsIs() {
        val view = hostView()
        view.cylShowBadgeValue("")
        assertTrue(view.cylIsShowBadge())
        assertNull(view.cylBadge?.text)
        view.cylShowBadgeValue("hot")
        assertEquals("hot", view.cylBadge?.text)
    }

    @Test
    fun aNumberAboveTheMaximumIsCapped() {
        val view = hostView()
        view.cylShowBadgeValue("100")
        assertEquals("99+", view.cylBadge?.text)
        view.cylBadgeMaximumBadgeNumber = 9
        assertEquals("9+", view.cylBadge?.text)
    }

    @Test
    fun zeroAndNegativeNumbersAndClearRemoveTheBadge() {
        val view = hostView()
        for (value in listOf("0", "-1")) {
            view.cylShowBadgeValue("3")
            view.cylShowBadgeValue(value)
            assertFalse(value, view.cylIsShowBadge())
        }
        view.cylShowBadgeValue("3")
        view.cylClearBadge()
        assertNull(view.cylBadge)
    }

    @Test
    fun theStyleKeysAreAppliedAndUnknownValuesAreIgnored() {
        val view = hostView()
        view.cylApplyBadgeAttributes(
            mapOf(
                CYLBadgeAttributeKey.COLOR to "#00FF00",
                CYLBadgeAttributeKey.TEXT_COLOR to "#112233",
                CYLBadgeAttributeKey.RADIUS to 6,
                CYLBadgeAttributeKey.CENTER_OFFSET to "{2, -3}",
                CYLBadgeAttributeKey.BORDER_WIDTH to "1.5",
                CYLBadgeAttributeKey.MAXIMUM_NUMBER to Any(),
            )
        )
        assertEquals(Color.GREEN, view.cylBadgeBackgroundColor)
        assertEquals(0xFF112233.toInt(), view.cylBadgeTextColor)
        assertEquals(6f, view.cylBadgeRadius, 0.01f)
        assertEquals(CYLOffset(2f, -3f), view.cylBadgeCenterOffset)
        assertEquals(1.5f, view.cylBadgeBorderWidth, 0.01f)
        assertEquals(99, view.cylBadgeMaximumBadgeNumber)
    }

    @Test
    fun showAndClearPostTheBadgeEventsUnderTheCrossPlatformNames() {
        val view = hostView()
        val heard = ArrayList<String>()
        LifecycleRegistry.of(view).addCustomCallback<Any>("cyl.badge.didShow") { _, _, info -> heard += "show ${info.userInfo?.get("value")}" }
        LifecycleRegistry.of(view).addCustomCallback<Any>(BadgeEvents.didClear) { _, _, _ -> heard += "clear" }
        view.cylShowBadgeValue("3", CYLEnums.CYLBadgeAnimationType.None)
        view.cylClearBadge()
        view.cylClearBadge()
        assertEquals(listOf("show 3", "clear"), heard)
    }
}
