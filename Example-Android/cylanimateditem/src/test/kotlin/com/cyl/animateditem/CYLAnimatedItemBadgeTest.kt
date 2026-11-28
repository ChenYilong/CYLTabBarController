package com.cyl.animateditem

import android.app.Activity
import android.graphics.Bitmap
import android.graphics.drawable.BitmapDrawable
import android.view.View
import android.view.ViewGroup
import com.cyl.tabbar.CYLBadgeAttributeKey
import com.cyl.tabbar.CYLBadgeHosting
import com.cyl.tabbar.CYLEnums
import com.cyl.tabbar.cylBadge
import com.cyl.tabbar.cylBadgeRadius
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [EN] The item badge API (docs/Animated-Item-Badge-CrossPlatform.md, Android phase 2): the anchor sits on the icon, the badge neither moves nor
 *      shrinks the icon, clearing restores everything, `reservesBadgeSpace` is the only thing that measures it, and the label carries the description.
 *      Written statically on Linux, not run: the owner runs it with the module's tests.
 * [CN] item 角标 API（docs/Animated-Item-Badge-CrossPlatform.md，Android 阶段 2）：锚点位于图标上，角标既不移动也不缩小图标，清除后一切复原，
 *      只有 `reservesBadgeSpace` 会让它参与测量，标签带有描述。在 Linux 上静态编写，尚未运行：由所有者随模块测试一起运行。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLAnimatedItemBadgeTest {

    private fun item(): CYLAnimatedItemView {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        val view = CYLAnimatedItemView(activity)
        view.title = "Title"
        view.iconView.setImageDrawable(BitmapDrawable(activity.resources, Bitmap.createBitmap(20, 20, Bitmap.Config.ARGB_8888)))
        val parent = android.widget.FrameLayout(activity)
        parent.addView(view, ViewGroup.LayoutParams(400, 200))
        view.measure(View.MeasureSpec.makeMeasureSpec(400, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(200, View.MeasureSpec.EXACTLY))
        view.layout(0, 0, 400, 200)
        return view
    }

    private fun relayout(view: CYLAnimatedItemView) {
        view.measure(View.MeasureSpec.makeMeasureSpec(400, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(200, View.MeasureSpec.EXACTLY))
        view.layout(0, 0, 400, 200)
    }

    @Test
    fun noBadgeByDefaultAndTheAnchorIsCreatedOnlyWhenNeeded() {
        val view = item()
        assertFalse(view.isShowingBadge)
        assertEquals(null, view.badgeValue)
        assertFalse((0 until view.childCount).any { view.getChildAt(it) is android.widget.FrameLayout && view.getChildAt(it) !== view.iconView })
    }

    @Test
    fun theAnchorSitsOnTheIconAboveItAndIsNotInteractive() {
        val view = item()
        view.badgeValue = "3"
        relayout(view)
        val anchor = view.badgeAnchorView
        assertEquals(view.iconView.left, anchor.left)
        assertEquals(view.iconView.top, anchor.top)
        assertEquals(view.iconView.width, anchor.width)
        assertEquals(view.iconView.height, anchor.height)
        assertSame(anchor, view.getChildAt(view.childCount - 1))
        assertFalse(anchor.isClickable)
        assertEquals(View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS, anchor.importantForAccessibility)
        assertSame(anchor, (view as CYLBadgeHosting).cylBadgeAnchorView)
    }

    @Test
    fun theBadgeDoesNotMoveOrShrinkTheIconAndClearingRestoresIt() {
        val view = item()
        val before = listOf(view.iconView.left, view.iconView.top, view.iconView.width, view.iconView.height)
        view.badgeValue = "3"
        relayout(view)
        assertTrue(view.isShowingBadge)
        assertEquals(before, listOf(view.iconView.left, view.iconView.top, view.iconView.width, view.iconView.height))
        view.badgeValue = null
        relayout(view)
        assertFalse(view.isShowingBadge)
        assertEquals(before, listOf(view.iconView.left, view.iconView.top, view.iconView.width, view.iconView.height))
    }

    @Test
    fun rightToLeftMirrorsTheIconAndPutsTheBadgeOnItsTopLeftCorner() {
        val view = item()
        view.badgeValue = "3"
        relayout(view)
        val badge = view.badgeAnchorView.cylBadge!!
        val iconLeft = view.iconView.left
        val titleLeft = view.titleView.left
        val overhang = (badge.left + badge.right) / 2 - view.iconView.right
        assertTrue(iconLeft < titleLeft)
        // [EN] The direction resolves only on an attached view; the manifest of a test app has no supportsRtl, so ask for it. [CN] 只有已挂载的视图才解析方向；测试应用清单没有 supportsRtl，需打开。
        val activity = view.context as Activity
        activity.applicationInfo.flags = activity.applicationInfo.flags or android.content.pm.ApplicationInfo.FLAG_SUPPORTS_RTL
        activity.setContentView(view.parent as View)
        view.layoutDirection = View.LAYOUT_DIRECTION_RTL
        relayout(view)
        assertTrue(view.iconView.left > view.titleView.left)
        assertEquals(view.iconView.left, view.badgeAnchorView.left)
        assertEquals(overhang.toDouble(), (view.iconView.left - (badge.left + badge.right) / 2).toDouble(), 1.0)
    }

    @Test
    fun aDotAndTheStyleKeys() {
        val view = item()
        view.badgeAttributes = mapOf(CYLBadgeAttributeKey.RADIUS to "5", CYLBadgeAttributeKey.COLOR to "#FF3B30")
        view.badgeValue = ""
        relayout(view)
        assertTrue(view.isShowingBadge)
        assertEquals(5f, view.badgeAnchorView.cylBadgeRadius, 0.01f)
        assertNotNull(view.badgeAnchorView.cylBadge)
    }

    @Test
    fun theAnimationNameIsReadInAnyLetterCase() {
        assertEquals(CYLEnums.CYLBadgeAnimationType.Scale, CYLBadgeAttributeKey.animationType(mapOf(CYLBadgeAttributeKey.ANIMATION to "SCALE")))
        assertEquals(CYLEnums.CYLBadgeAnimationType.ScaleOnce, CYLBadgeAttributeKey.animationType(mapOf(CYLBadgeAttributeKey.ANIMATION to 9)))
        assertEquals(CYLEnums.CYLBadgeAnimationType.None, CYLBadgeAttributeKey.animationType(mapOf(CYLBadgeAttributeKey.ANIMATION to "spin")))
        assertEquals(CYLEnums.CYLBadgeAnimationType.None, CYLBadgeAttributeKey.animationType(null))
    }

    @Test
    fun reservesBadgeSpaceIsTheOnlyThingThatMeasuresTheBadge() {
        val view = item()
        view.badgeValue = "3"
        view.measure(View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED), View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED))
        val plain = view.measuredWidth
        view.reservesBadgeSpace = true
        view.measure(View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED), View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED))
        assertTrue(view.measuredWidth > plain)
    }

    @Test
    fun theLabelCarriesTheBadgeDescriptionAndClearingRestoresIt() {
        val view = item()
        view.updateAccessibility()
        val own = view.contentDescription.toString()
        view.badgeValue = "3"
        assertTrue(view.contentDescription.toString().startsWith(own))
        assertTrue(view.contentDescription.toString().length > own.length)
        view.badgeValue = null
        assertEquals(own, view.contentDescription.toString())
    }
}
