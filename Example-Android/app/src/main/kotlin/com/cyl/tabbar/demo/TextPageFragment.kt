package com.cyl.tabbar.demo

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.os.bundleOf
import androidx.fragment.app.Fragment

/**
 * [EN] A demo page: a text, and optionally a button (open a URL, or the two-tab-bar demo).
 * [CN] 演示页面：一段文字，以及可选的按钮（打开 URL，或打开两个 TabBar 的演示）。
 */
class TextPageFragment : Fragment() {

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        val context = requireContext()
        val layout = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(48, 48, 48, 48)
        }
        val arguments = requireArguments()
        layout.addView(TextView(context).apply {
            text = arguments.getString(TEXT)
            gravity = Gravity.CENTER
            textSize = 16f
        })
        arguments.getString(URL)?.let { url ->
            layout.addView(Button(context).apply {
                setText(R.string.open_in_browser)
                setOnClickListener { startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url))) }
            })
        }
        if (arguments.getBoolean(OPENS_TWO_TAB_BARS)) {
            layout.addView(Button(context).apply {
                setText(R.string.open_two_tab_bars)
                setOnClickListener { startActivity(Intent(context, TwoTabBarsActivity::class.java)) }
            })
        }
        arguments.getInt(BACKGROUND, 0).takeIf { it != 0 }?.let(layout::setBackgroundColor)
        return layout
    }

    companion object {
        private const val TEXT = "text"
        private const val URL = "url"
        private const val OPENS_TWO_TAB_BARS = "opensTwoTabBars"
        private const val BACKGROUND = "background"

        fun newInstance(text: String, url: String? = null, opensTwoTabBars: Boolean = false, background: Int = 0) =
            TextPageFragment().apply {
                arguments = bundleOf(TEXT to text, URL to url, OPENS_TWO_TAB_BARS to opensTwoTabBars, BACKGROUND to background)
            }
    }
}
