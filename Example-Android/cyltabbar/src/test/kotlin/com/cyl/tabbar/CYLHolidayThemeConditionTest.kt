package com.cyl.tabbar

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.time.Instant

/**
 * [EN] A holiday theme is a conditional value of the theme key, not a new version of the whole configuration (docs/Configuration-File.md,
 *      "Versions and routes", Q5): the manifest names `themes.default`, and a condition with Remote Config's `dateTime` expression overrides it
 *      during the holiday. Remote Config compares dateTime with the time of the last fetch on the server; the manifest is on the device, so
 *      here the device clock decides when the manifest is read.
 * [CN] 节假日主题是主题键的条件值，不是整份配置的新版本（docs/Configuration-File.md，“Versions and routes”，Q5）：清单给出 `themes.default`，
 *      带 Remote Config `dateTime` 表达式的条件在节假日期间覆盖它。Remote Config 在服务端把 dateTime 与最后一次拉取的时间比较；清单已经在设备上，
 *      因此这里由读取清单时的设备时钟决定。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLHolidayThemeConditionTest {
    private val context: Context = ApplicationProvider.getApplicationContext()

    @After
    fun resetClock() {
        CYLManifestConditions.clock = { System.currentTimeMillis() }
    }

    private fun millis(iso: String) = Instant.parse(iso).toEpochMilli()

    private fun manifest(vararg windows: Pair<String, String>): CYLTabBarManifest {
        val conditions = windows.map { (name, expression) -> mapOf("name" to name, "expression" to expression) }
        val overrides = windows.map { (name, _) -> mapOf("condition" to name, "themes" to mapOf("default" to name)) }
        return CYLTabBarManifest.manifestWithDictionary(context, mapOf(
            "schemaVersion" to 1, "id" to "holiday", "version" to "2.1.0",
            "themes" to mapOf("default" to "light", "list" to mapOf("light" to mapOf("tabColor" to "#8E8E93"))),
            "tabBar" to mapOf("list" to emptyList<Any?>()),
            "conditions" to conditions, "overrides" to overrides), null)
    }

    private fun defaultTheme(manifest: CYLTabBarManifest) = (manifest.dictionary["themes"] as Map<*, *>)["default"]

    private val christmas = "christmas" to "dateTime >= dateTime('2026-12-20T00:00:00', 'Pacific/Auckland') && dateTime < dateTime('2027-01-02T00:00:00', 'Pacific/Auckland')"

    @Test
    fun theThemeKeyChangesOnlyInsideTheWindow() {
        val start = millis("2026-12-19T11:00:00Z")   // 2026-12-20 00:00 in Auckland (UTC+13, summer time)
        val end = millis("2027-01-01T11:00:00Z")     // 2027-01-02 00:00 in Auckland
        fun themeAt(time: Long): Any? {
            CYLManifestConditions.clock = { time }
            return defaultTheme(manifest(christmas))
        }
        assertEquals("a millisecond before the start", "light", themeAt(start - 1))
        assertEquals("at the start", "christmas", themeAt(start))
        assertEquals("inside", "christmas", themeAt(millis("2026-12-25T00:00:00Z")))
        assertEquals("a millisecond before the end", "christmas", themeAt(end - 1))
        assertEquals("the end is not inside", "light", themeAt(end))
    }

    @Test
    fun aTimeWithAnOffsetIsExactAndAnUnknownZoneNeverHolds() {
        CYLManifestConditions.clock = { millis("2026-12-24T12:00:00Z") }
        assertEquals("christmas", defaultTheme(manifest("christmas" to "dateTime > dateTime('2026-12-24T00:00:00Z') && dateTime <= dateTime('2026-12-25T00:00:00+00:00')")))
        assertEquals("light", defaultTheme(manifest("christmas" to "dateTime > dateTime('2026-12-24T12:00:00Z')")))
        assertEquals("a zone that does not exist", "light", defaultTheme(manifest("christmas" to "dateTime > dateTime('2026-01-01T00:00:00', 'Mars/Olympus')")))
        assertEquals("a time that does not parse", "light", defaultTheme(manifest("christmas" to "dateTime > dateTime('next christmas')")))
        assertEquals("not a calendar day", "light", defaultTheme(manifest("christmas" to "dateTime > dateTime('2026-02-30T00:00:00', 'UTC')")))
    }

    @Test
    fun theWindowAndOtherConditionsCombine() {
        CYLManifestConditions.clock = { millis("2026-12-24T12:00:00Z") }
        assertEquals("christmas", defaultTheme(manifest("christmas" to "device.os == 'android' && dateTime >= dateTime('2026-12-01T00:00:00Z')")))
        assertEquals("light", defaultTheme(manifest("christmas" to "device.os == 'ios' && dateTime >= dateTime('2026-12-01T00:00:00Z')")))
    }

    @Test
    fun laterConditionsWinWhenSeveralHold() {
        CYLManifestConditions.clock = { millis("2027-01-01T00:00:00Z") }
        val theme = defaultTheme(manifest(
            "christmas" to "dateTime >= dateTime('2026-12-20T00:00:00Z')",
            "newyear" to "dateTime >= dateTime('2026-12-31T00:00:00Z')"))
        assertEquals("the later one in the list wins, as the manifest has always merged them", "newyear", theme)
    }
}
