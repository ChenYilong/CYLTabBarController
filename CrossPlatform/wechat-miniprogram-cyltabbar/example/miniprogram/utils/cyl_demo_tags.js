/**
 * [EN] The home page's sectioned lists are CollectionViewClassifyMenu tag lists (docs/instructions/examples.md): one tag per row (its
 *      title; the subtitle is the long-press callout), a titled header per section, tags as wide as their title, titles that wrap up
 *      to 3 lines, a More / Less control after 3 rows of tags. A tap does what tapping the old row did. A section keeps its rows when
 *      one of them has something a tag cannot hold: a slider, a switch, the arrows, a color swatch.
 * [CN] 首页带分组的列表使用 CollectionViewClassifyMenu 的 TagList（docs/instructions/examples.md）：每行一个 Tag（标题；副标题为长按浮层），
 *      每个分组有标题，Tag 宽度随标题自适应，标题最多换行 3 行，超过 3 行 Tag 后出现 More / Less 控件。点击 Tag 与点击原行效果相同。
 *      分组中只要有一行含 Tag 放不下的内容（滑块、开关、箭头、色块），整个分组仍显示为行。
 */
const CYL_TAG_TITLE_MAX_LINES = 3
const CYL_TAG_VISIBLE_ROWS = 3

/** [EN] A row a tag can stand for. [CN] Tag 可以代表的行。 */
function cylRowIsTag(row) {
  const accessory = row.accessory || 'none'
  const hasSlider = row.slider !== null && row.slider !== undefined
  return !hasSlider && !(row.preview && row.preview.swatch) && (accessory === 'none' || accessory === 'chevron' || accessory === 'check')
}

/** [EN] A section is shown as tags when it has rows and every row is a tag. [CN] 分组有行且每一行都是 Tag 时显示为 Tag。 */
function cylSectionIsTags(section) {
  return Array.isArray(section.rows) && section.rows.length > 0 && section.rows.every(cylRowIsTag)
}

/** [EN] The `configuration` of the `cyl-tag-list` of one section. [CN] 一个分组的 `cyl-tag-list` 的 `configuration`。 */
function cylTagConfiguration(section) {
  return {
    // `none`: a tap selects nothing but still reports the tag, so the page runs the row's action. `none`：点击不选中，仍回调 Tag，由页面执行该行的动作。
    selectionMode: 'none',
    longPressAction: 'callout',
    defaultVisibleRows: CYL_TAG_VISIBLE_ROWS,
    foldControl: { position: 'headerTrailing', content: 'iconAndTitle' },
    style: { titleMaxLines: CYL_TAG_TITLE_MAX_LINES },
    sections: [{
      title: section.title,
      items: section.rows.map((row) => {
        const item = { id: row.id, title: row.title }
        if (row.subtitle) item.subtitle = row.subtitle
        return item
      }),
    }],
  }
}

module.exports = { cylRowIsTag, cylSectionIsTags, cylTagConfiguration, CYL_TAG_TITLE_MAX_LINES, CYL_TAG_VISIBLE_ROWS }
