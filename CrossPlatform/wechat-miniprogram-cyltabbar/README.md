# cyl-tabbar-miniprogram

CYLTabBarController for WeChat Mini Program: `cyl-tab-bar`, a custom tab bar component configured with the same keys as
the iOS and Android libraries ([docs/Configuration-File.md](../../docs/Configuration-File.md)). It depends on no
animation library: animated tab icons come from four optional packages, one per library, so an app ships only the
runtime it uses (the main code package is limited to 2 MB). Full documentation, the scores (keys, API,
lottie-miniprogram issues) and the screenshots: [docs/WeChat-Mini-Program.md](../../docs/WeChat-Mini-Program.md).

## Run the example

1. `cd example && npm run setup` (Node 18+, no network): installs `cyl-tabbar-miniprogram` and **one** animation package
   into `example/miniprogram/miniprogram_npm`, and copies the shared configuration, localization tables, skin images and
   that package's icons into `example/miniprogram/shared`. Lottie by default; choose another with
   `npm run setup -- --animation=pag` (`lottie`, `pag`, `rive`, `gif`; remembered in `.cyl-animation`).
2. Import `example/` in [WeChat DevTools](https://developers.weixin.qq.com/miniprogram/dev/devtools/download.html)
   (AppID `wx5e29c9d33906f074`; use your own AppID for your app) and compile.

`npm run check` (in `example/`) fails when `miniprogram_npm` or `shared` is out of date. Tests of the configuration
reader: `npm test` here.

## Depend on it

```json
// package.json of your mini program
{ "dependencies": { "cyl-tabbar-miniprogram": "file:../path/to/wechat-miniprogram-cyltabbar" } }
```

Copy `example/scripts/cyl_install_components.js` into your project (or use DevTools' "Build npm" on a file system with
symbolic links) to install the relative-path dependencies.

**Animated tab icons: add the packages you need** and name their components through the abstract nodes of `cyl-tab-bar`
(`cyl-lottie-view`, `cyl-pag-view`, `cyl-rive-view`). A node you leave out shows an empty placeholder
(`cyl-animation-placeholder`), which emits `error`.

| Package | Folder | Component | Code package cost (example, measured) |
|:---|:---|:---|:---|
| `cyl-lottie-miniprogram` | `../lottie-miniprogram` | `cyl-lottie` | 0.45 MB in all |
| `cyl-pag-miniprogram` | `../pag-miniprogram` | `cyl-pag` (copy `libpag.wasm.br` to `/cyl-pag-miniprogram/`) | 1.20 MB in all |
| `cyl-rive-miniprogram` | `../rive-miniprogram` | `cyl-rive` (copy `rive.wasm.br` to `/cyl-rive-miniprogram/`) | 0.85 MB in all |
| `cyl-gif-miniprogram` | `../gif-miniprogram` | none: GIF plays in `<image>`, the package holds the icons | 0.33 MB in all |

Each package lists its sample icons in `cylExampleResources` of its `package.json`; the example copies only those of the
package it installed.

```json
// app.json
{ "tabBar": { "custom": true, "list": [{ "pagePath": "pages/home/index", "text": "Home" }] } }
// custom-tab-bar/index.json
{ "component": true, "usingComponents": {
  "cyl-tab-bar": "cyl-tabbar-miniprogram/cyl-tab-bar/index",
  "cyl-lottie": "cyl-lottie-miniprogram/cyl-lottie/index"
} }
```

```xml
<!-- custom-tab-bar/index.wxml -->
<cyl-tab-bar generic:cyl-lottie-view="cyl-lottie" configuration="{{configuration}}" selected-identifier="{{selected}}" animation-base-path="/assets/lottie" bind:select="onSelect" />
```

Properties: `tabBarHeight` (px; the default, 0, is 48 px, the WeChat native tab bar's height; not used by Liquid Glass), `itemStyle` (CYLTabBarItemStyle `flat` / `liquidGlass`), `glassLensStyle` (CYLGlassLensStyle `regular`, the default "liquid", / `skeuomorphic`, "skeuomorphic liquid"; Liquid Glass only), `animationSpeed`, `animationLoop`, `configuration`, `strings`, `symbolsByTheme`, `imageBasePath`, `animationBasePath`, `selectedIdentifier`,
`loggedIn`, `appVersion`. Events: `select`, `reselect`, `plustap`, `loginrequired` (detail: `index`, `identifier`,
`pageIdentifier`, `pageParameters`, `context`, `isPlusButton`). Methods: `cyl_selectIdentifier`, `cyl_showBadgeValue`,
`cyl_showBadgeDot`, `cyl_removeBadge`, `cyl_setThemeIdentifier`, `cyl_themeIdentifiers`, `cyl_playLottie`,
`cyl_selectAdjacent`, `cyl_setItemStyle`, `cyl_setGlassLensStyle`, `cyl_playAll`, `cyl_setAnimationSpeed`, `cyl_setAnimationLoop`, `cyl_setHiddenIdentifiers` (property `hiddenIdentifiers`: tabs or the plus button left out of the bar, e.g. by user role), `cyl_setTabBarHidden` (property `tabBarHidden`: hides the bar of one page). Page behavior for swiping between tabs: `cyl-tabbar-miniprogram/cyl-tab-bar/cyl_swipe_behavior`.

## The icon + title component: `cyl-animated-item`

`src/cyl-animated-item/` is the icon + title view other repositories reuse (the counterpart of iOS and Android
`CYLAnimatedItemView`, see [docs/Animated-Item.md](../../docs/Animated-Item.md)). It takes the same abstract nodes
(`cyl-lottie-view`, `cyl-pag-view`, `cyl-rive-view`, `cyl-svga-view`) and draws GIF with `<image>`.

Properties: `title`, `image`, `selectedImage`, `placeholderImage`, `animationUrl` or `animationData` (Lottie JSON as an
object, each item plays its own copy), `animationType` (when the extension does not say it, e.g. `.riv.bin`), `selected`, `enabled`, `axis`, `iconSize`, `loop`, `speed`, `autoplay` (default
true; false rests until `playAnimation()`), `restingProgress` (0...1, the frame at rest; selected shows the last),
`gifFirstFrame` / `gifLastFrame` / `gifDuration` (GIF stills at rest and one pass in milliseconds on play; without
stills a GIF always plays), `riveWasmPath` / `pagWasmPath` (cyl-rive / cyl-pag `wasm-path`; '' keeps their default), `accessoryImage`, `accessoryText`,
`accessoryAccessibilityLabel`, `accessoryPlacement`, `animationTint` (one color for a Rive animation, passed to cyl-rive `tint`; '' keeps the file's colors), `titleColor`, `titleDarkColor` (the title color while dark; '' keeps `titleColor`), `userInterfaceStyle` ('system', the default, follows the system theme and needs `"darkmode": true` in app.json; 'light' or 'dark' forces it), `titleFontSize` (px; 0 keeps 14), `titleFontWeight` ('normal', 'bold', 'bolder', 'lighter' or 100–900; '' keeps the default), `titleLines` (1: one line with an ellipsis, the default; 0: no limit; n > 1: up to n lines), `titleLineHeight` (px; 0 keeps the default), `titleSpacing` (px between the icon and the title; -1 keeps 2 px vertical / 4 px horizontal; a vertical item centres each wrapped line), `dragEnabled`, `accessibilityLabel`, `embedded` (inside a control that is the accessibility element: no padding, no 44 px
minimum, hidden from accessibility, no gestures). Methods (through
`selectComponent`): `playAnimation()` (from progress 0; a file still loading plays when ready), `restartAnimation()`,
`stopAnimation()`, `cyl_player()` (the player, below). Events: `itemtap`, `itemlongpress`, `accessorytap`, `dragstart` / `dragmove` / `dragend`, and the engine's own, forwarded with its detail: `animationready` (e.g. `duration`), `animationcomplete` (a non-looping pass ended, e.g. to count repeats; `animationend` is sent with it, the same detail, the HarmonyOS name), `animationloopcomplete` (a looping pass ended), `animationerror` (`message`; the item still shows its image). GIF sends none of the four.

### Engine contract: the player, host-driven mode, `restartToken`

The same contract HarmonyOS defines (`CrossPlatform/harmonyos-cyltabbar/cylanimateditem/README.md`, "Engine views";
[docs/Animated-Item.md](../../docs/Animated-Item.md), "Engine API across platforms").

- **`cyl_player()`** (a method, not an event) returns the item's one `CYLAnimatedItemPlayer`
  (`src/cyl-animated-item/cyl_animated_item_player.js`, pure JavaScript): `play()` (from progress 0 once; before
  `animationready` it waits for the file), `stopAtProgress(p)` (pauses, then seeks to 0...1; where the engine has no seek it
  rests on the first frame, or the last at 1), `speed`, `loops` (the item's `speed` and `loop`, applied at once),
  `supportsSpeed` / `supportsLoops` / `supportsProgress` / `supportsColors`, `isPlaying`, `onEnded(cb)` (the end of a
  play-once pass, the same moment as `animationcomplete`; returns a function that removes it), `applyColors(colors)` (a `Map`
  or an object; undefined restores the file's colors). Support, by type: Lottie speed, progress, colors; PAG and SVGA speed,
  progress; Rive speed, colors (no seek); GIF none of them (loops only with stills). `progress` (the current position) is not
  offered: no engine component reports it.
- **`drivesAnimationPlayback`** (default true). false: the item applies none of the default rules (a selection change touches no
  engine, the engine never autoplays on `ready`, `restartToken` is ignored, the engine's own resting frame stays on the host's
  last `stopAtProgress`) and the host plays through `cyl_player()`. `playAnimation()`, `restartAnimation()` and `stopAnimation()`
  still do what they are called for. Set it when the item is created. All engines stay behind the four generic nodes
  (`generic:cyl-lottie-view=…`), each package with its own default, so the 2 MB package limit is unchanged.
- **`restartToken`** (Number, default 0): each time it grows the item plays again from the start, like `restartAnimation()`;
  the value at creation and a lower value are not restarts. **`animationRestartToken`** is the same property under the HarmonyOS
  name: growth of either one restarts (each has its own baseline).
- **The end callback** is the `animationcomplete` event, sent together with its alias `animationend` (the HarmonyOS name, the same
  detail), and `player.onEnded`. A GIF given
  as the `image` (canvas) sends neither.
- Tests: `test/cyl_animated_item_player.test.js` (player, host-driven mode, restart token) and
  `test/cyl_animated_item_source.test.js` (`cylAnimatedItemSource`, the `#` options, against
  `CrossPlatform/animated-item-fixtures/source-options.json`).

## The tab switch contract

The same as iOS (`CYLTabBar` / `CYLAnimatedItemView`): **a switch stops and resets every other tab first, then the selected tab
plays.** After any switch exactly one tab is selected (its `selected` comes from the one `selectedIdentifier`), and every other tab is
stopped on its unselected look (`restingProgress` frame or static image), also when the switch comes mid-animation or two taps arrive
quickly. `cyl-tab-bar` does it in `cyl_syncLottie` (`cyl_stopOtherAnimations`, then `cyl_playLottie`); `cyl-animated-item` does it for
itself when `selected` turns false (`cyl_halt`: cancel a play still waiting for the file, pause the engine, then the resting frame).
Exception: a tab with `CYLTabBarLottieLoopsWhenUnselected` keeps looping. Engines must stop on `cyl_pause()` and cancel a pending
`cyl_playFromStart`; a seek alone (`cyl_setProgress`) is not a stop. Tests: `test/cyl_tab_switch.test.js`.

## Layout

| Path | What |
|:---|:---|
| `src/cyl-tab-bar/` | The component; `cyl_configuration.js` reads the configuration (no wx API, tested in Node) |
| `src/cyl-tab-bar-item/` | The icon and title of a tab (`CYLFlatDesignTabBarItem`); its abstract nodes take the animation components |
| `src/cyl-animated-item/` | The reusable icon + title component; `cyl_animated_item_model.js` holds its display logic (tested in Node) |
| `src/cyl-animation-placeholder/` | The default of the abstract nodes: an empty view for a library that is not installed |
| `test/` | Node tests of the configuration reader |
| `example/` | The example mini program: `project.config.json`, `miniprogram/` (pages, custom tab bar, generated `shared/`), `scripts/` |
| `../lottie-miniprogram/`, `../pag-miniprogram/`, `../rive-miniprogram/`, `../gif-miniprogram/` | The optional animation packages |

No code was copied from the projects listed as references in the documentation: see [NOTICE](NOTICE).
