package com.cyl.animateditem

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.io.File

/**
 * [EN] Every case of `CrossPlatform/animated-item-fixtures/source-options.json` (shared by all platforms' parsers) against
 *      `CYLAnimatedItemSource.parse`.
 * [CN] `CrossPlatform/animated-item-fixtures/source-options.json`（各平台解析器共用）的每个用例对照 `CYLAnimatedItemSource.parse`。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLAnimatedItemSourceFixtureTest {

    private val fixture = File("../../CrossPlatform/animated-item-fixtures/source-options.json")

    @Test
    fun everyVectorOfTheSharedFixtureParsesAsExpected() {
        assertTrue("the fixture is at ${fixture.absolutePath}", fixture.isFile)
        val cases: JSONArray = JSONObject(fixture.readText()).getJSONArray("cases")
        assertTrue("the fixture has cases", cases.length() >= 7)
        for (index in 0 until cases.length()) {
            val case = cases.getJSONObject(index)
            val input = case.getString("input")
            val parsed = CYLAnimatedItemSource.parse(input)
            if (case.has("file")) assertEquals("file of: $input", case.getString("file"), parsed.file)
            if (case.has("type")) assertEquals("type of: $input", case.getString("type"), parsed.type)
            if (case.has("inlineJSON")) assertEquals("inline JSON of: $input", case.getString("inlineJSON"), parsed.inlineJSON)
            val expected = case.getJSONObject("options")
            val names = expected.keys().asSequence().toList()
            assertEquals("option names of: $input", names, parsed.options.keys.toList())
            for (name in names) assertEquals("option $name of: $input", expected.getString(name), parsed.options[name])
        }
    }

    @Test
    fun anUndecodableTextIsKeptAndANamelessPairIsDropped() {
        val parsed = CYLAnimatedItemSource.parse("a.riv#x=%ZZ&=5&lonely&y=%E4%B8%AD")
        assertEquals(mapOf("x" to "%ZZ", "y" to "中"), parsed.options)
        assertEquals("Rive", parsed.type)
    }
}
