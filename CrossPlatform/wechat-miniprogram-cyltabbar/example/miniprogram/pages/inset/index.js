/**
 * [EN] `itemContentHorizontalInset` left unset (docs/Animated-Item.md): the space between an item's content and the edge of its background.
 *      Unset it is the library's default for the style: a glass item gets the glass content inset, a flat item none. Four items, flat and
 *      Liquid Glass, normal and selected, each with an icon and a title, on a colorful backdrop so the glass shows. Open it with
 *      `wx.reLaunch({ url: '/pages/inset/index' })`.
 * [CN] 未设置 `itemContentHorizontalInset`（docs/Animated-Item.md）：条目内容与其背景边缘的间距。未设置时为该样式的库默认值：玻璃条目使用玻璃内容
 *      间距，扁平条目没有。四个条目：扁平与液态玻璃，常态与选中，各带图标与标题，放在彩色背景上以显示玻璃效果。用
 *      `wx.reLaunch({ url: '/pages/inset/index' })` 打开。
 */
Page({
  data: {
    image: '/shared/objc/fishpond_normal.png',
    flatBackground: '#E5E5EA',
  },
});
