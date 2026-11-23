/**
 * [EN] The playback controls of the example (Play all, Restart, speed, loop) go through the engine API of every tab icon,
 *      `cyl_player()` of its cyl-animated-item (docs/Animated-Item.md, "Engine API across platforms"), the mini program
 *      counterpart of the HarmonyOS `CYLAnimatedItemPlayer`: no control reaches into an engine component. A player that
 *      cannot do something (`supportsSpeed`, `supportsLoops`) ignores the call, so GIF icons keep their own speed.
 * [CN] 示例的播放控件（全部播放、重新播放、速度、循环）都通过每个 Tab 图标的引擎 API，即其 cyl-animated-item 的 `cyl_player()`
 *      （docs/Animated-Item.md「Engine API across platforms」），对应鸿蒙的 `CYLAnimatedItemPlayer`：任何控件都不直接操作引擎组件。
 *      做不到某件事的播放器会忽略该调用，因此 GIF 图标保持自己的速度。
 */

/**
 * [EN] The players of the tab bar's icons: [{ key, selected, player }], in tab order; an item without an animated icon is left out.
 * [CN] TabBar 各图标的播放器：[{ key, selected, player }]，按 Tab 顺序；没有动画图标的条目不计入。
 */
function cylItemPlayers(tabBar) {
  const slots = (tabBar && tabBar.data && tabBar.data.cylSlots) || [];
  const entries = [];
  slots.forEach((slot) => {
    const tabItem = slot.item ? tabBar.selectComponent(`#cyl-item-${slot.key}`) : null;
    const icon = tabItem && typeof tabItem.selectComponent === 'function' ? tabItem.selectComponent('#cyl-item-icon') : null;
    if (icon && typeof icon.cyl_player === 'function') {
      entries.push({ key: slot.key, selected: Boolean(icon.data && icon.data.selected), player: icon.cyl_player() });
    }
  });
  return entries;
}

/** [EN] Play all: every icon plays once from progress 0 (repeats while loop is on). [CN] 全部播放：每个图标从进度 0 播放一次（循环开启时重复）。 */
function cylPlayAll(tabBar) {
  const entries = cylItemPlayers(tabBar);
  entries.forEach(({ player }) => player.play());
  return entries.length;
}

/** [EN] Restart: the selected tab's icon plays again from the start. [CN] 重新播放：选中 Tab 的图标从头再次播放。 */
function cylRestartSelected(tabBar) {
  const entries = cylItemPlayers(tabBar).filter((entry) => entry.selected);
  entries.forEach(({ player }) => player.play());
  return entries.length;
}

/** [EN] The speed of every icon whose engine takes one; returns how many took it. [CN] 为每个支持速度的图标设置速度；返回生效的个数。 */
function cylSetSpeed(tabBar, speed) {
  const entries = cylItemPlayers(tabBar).filter(({ player }) => player.supportsSpeed);
  entries.forEach(({ player }) => { player.speed = speed; });
  return entries.length;
}

/** [EN] Loop on or off for every icon that can loop; returns how many took it. [CN] 为每个能循环的图标开关循环；返回生效的个数。 */
function cylSetLoops(tabBar, loops) {
  const entries = cylItemPlayers(tabBar).filter(({ player }) => player.supportsLoops);
  entries.forEach(({ player }) => { player.loops = Boolean(loops); });
  return entries.length;
}

module.exports = { cylItemPlayers, cylPlayAll, cylRestartSelected, cylSetSpeed, cylSetLoops };
