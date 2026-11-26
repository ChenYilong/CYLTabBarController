# 暗黑模式适配 / Dark mode adaptation

> 状态 / Status: **仅记录，今天不实现 / recorded only, NOT implemented today** (2026-11-26). 负责人的回答 / The owner's answer: the tab bar background must follow dark mode, it has to be done, but not today.

## 暗黑模式适配 → tabbar 背景色随暗黑模式适配 / Tab bar background follows dark mode

### 问题 / The question

> 需要你决定的：深色模式下，示例的标签栏要不要跟着变深？现在是两个选择：1. 示例里加 `CYLTabBarBackgroundColor` 和深色主题色，标签栏跟随深色。2. 保持浅色。这个问题我之前在 Flutter 示例上也问过你一次，你没回答过。你定了，我就一起处理。

**决定 / Decision (2026-11-26, owner):** 标签栏背景必须跟随暗黑模式，一定要做，但今天不做。 / The tab bar background must follow dark mode; it will be done, not today.

### 当前状态 / Current state (2026-11-26, CYLTabBarController `d19e138e`)

| 平台 / Platform | 现象 / Observation |
| --- | --- |
| Android (Search 示例 / example) | 页面变深，标签栏保持浅色（249,249,249）；示例配置没有 `CYLTabBarBackgroundColor`，也没有深色主题色。 / The page goes dark, the bar stays light (249,249,249); the example config has no `CYLTabBarBackgroundColor` and no dark theme colours. |
| HarmonyOS (Search 示例 / example) | 扁平栏在深色下是中灰（约 `#949494`），不是深色背景，未选中的标题和未着色的图标几乎看不见（按应用强制 `setColorMode(DARK)`；系统级切换未测试）。 / The flat bar is a mid grey (about `#949494`) in dark mode instead of a dark background; unselected titles and untinted icons are nearly invisible (dark forced per app with `setColorMode(DARK)`; the system-level switch is untested). |
| Flutter 示例 / example | 栏在深色下保持 `#FAFAFA`（示例配置没有 `CYLTabBarBackgroundColor`；`identifierForTrait` 主题对可以改变它）。 / The bar stays `#FAFAFA` in dark mode by example config (no `CYLTabBarBackgroundColor`; an `identifierForTrait` theme pair could change it). |

Android 演示本身（`Example-Shared/Configurations/cyl_tabbar_configuration.json`，主题提供 `CYLTabBarBackgroundColor`）在深色下栏为 `#1C1C1E`，所以演示是对的，缺的是其他示例的配置。 / The Android demo with the shared theme configuration shows `#1C1C1E` in dark mode, so the demo is right; what is missing is the configuration of the other examples.

截图（在 CYLSearchViewController 仓库）/ Screenshots (in the CYLSearchViewController repository): `docs/assets/android-emulator-api37-20261126-tabbar-template-*-at-b4993123.png`, `docs/assets/android-emulator-api37-20261126-tabbar-tint-*-at-d19e138e.png`, `docs/assets/harmonyos-emulator-20261126-tabbar-tint-*-at-114ef3f.png`.

### 待决的点 / Open points

1. 当栏背景未设置时，核心是否给出合理的深色默认值，还是每个示例/配置必须设置带深色主题对的 `CYLTabBarBackgroundColor`？按平台回答：Android、HarmonyOS、Flutter、iOS、小程序。 / When the bar background is unset, should the core provide a sensible dark default, or must every example/configuration set `CYLTabBarBackgroundColor` with a dark theme pair? Answer per platform: Android, HarmonyOS, Flutter, iOS, mini program.
2. HarmonyOS：系统级深浅色切换下的行为需要测试（目前只测了按应用强制深色）。 / HarmonyOS: the behaviour under the system-level dark/light switch has to be tested (only per-app forced dark was tested).

### 同一批待办的着色项 / Tint items of the same batch

- Android 核心「更多」（溢出）图标选中和未选中都是 `0,0,0`：在 `d19e138e` 之后已修复（「更多」的自带图标改为模板图标，使用 TabBar 的选中/未选中着色）。 / The Android core "More" (overflow) icon stayed `0,0,0` selected and unselected: fixed after `d19e138e` (its own glyph is now a template icon and takes the bar's selected/unselected tint).
- HarmonyOS 基于填充（fill）的 SVG 图标不着色：修复进行中。 / HarmonyOS fill-based SVG icons were not tinted: fix in progress.
- 静态图标默认是否着色（未设置渲染模式时）：负责人尚未决定，当前规则是需要配置才着色（#787）。 / Whether static icons tint by default (no rendering mode set): not decided by the owner; the current rule is opt-in (#787).
