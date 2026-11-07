package com.cyl.tabbar.example.pag

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.os.CountDownTimer
import android.view.Gravity
import android.widget.FrameLayout
import android.widget.HorizontalScrollView
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.cyl.tabbar.demo.DemoAssets

/**
 * [EN] iOS `GuideViewController`: shown on first launch, three guide images to swipe, and a "5 Skip" button counting down;
 *      the tab bar comes after the countdown, a tap on Skip, or a swipe past the last image.
 * [CN] iOS `GuideViewController`：首次启动时显示，三张可滑动的引导图，以及倒计时的 "5 跳过" 按钮；倒计时结束、点击跳过或滑过最后一张图后进入 TabBar。
 */
class GuideActivity : AppCompatActivity() {
    private var timer: CountDownTimer? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        supportActionBar?.hide()
        val width = resources.displayMetrics.widthPixels
        val pages = LinearLayout(this).apply {
            // [EN] The iOS guide images, `guideImage_<n>_750x1334` (`numOfPages = 3`). [CN] iOS 的引导图 `guideImage_<n>_750x1334`（`numOfPages = 3`）。
            for (page in 1..3) {
                addView(ImageView(context).apply { setImageDrawable(DemoAssets.drawable(context, "guideImage_${page}_750x1334")); scaleType = ImageView.ScaleType.CENTER_CROP }, LinearLayout.LayoutParams(width, -1))
            }
        }
        val scroll = object : HorizontalScrollView(this) {
            override fun onScrollChanged(l: Int, t: Int, oldl: Int, oldt: Int) {
                super.onScrollChanged(l, t, oldl, oldt)
                if (l > width * 2 - width / 4 && oldl < l) finishGuide()
            }
        }.apply { isHorizontalScrollBarEnabled = false; addView(pages) }
        val skip = TextView(this).apply {
            setTextColor(Color.BLUE)
            gravity = Gravity.CENTER
            background = GradientDrawable().apply { cornerRadius = 8 * resources.displayMetrics.density; setColor(Color.rgb(230, 230, 230)) }
            setPadding(24, 12, 24, 12)
            setOnClickListener { finishGuide() }
        }
        setContentView(FrameLayout(this).apply {
            addView(scroll, FrameLayout.LayoutParams(-1, -1))
            addView(skip, FrameLayout.LayoutParams(-2, -2, Gravity.TOP or Gravity.END).apply { setMargins(0, 96, 48, 0) })
        })
        timer = object : CountDownTimer(5000, 1000) {
            override fun onTick(millisUntilFinished: Long) { skip.text = getString(R.string.skip, ((millisUntilFinished + 999) / 1000).toInt()) }
            override fun onFinish() = finishGuide()
        }.start()
    }

    private fun finishGuide() {
        timer?.cancel()
        getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).edit().putBoolean(SHOWN, true).apply()
        if (!isFinishing) finish()
    }

    override fun onDestroy() {
        timer?.cancel()
        super.onDestroy()
    }

    companion object {
        private const val PREFERENCES = "CYLTabBarPAGGuide"
        private const val SHOWN = "shown"
        fun isFirstLaunch(context: Context) = !context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).getBoolean(SHOWN, false)
        fun show(activity: Activity) = activity.startActivity(Intent(activity, GuideActivity::class.java))
    }
}
