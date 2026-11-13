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

Properties: `itemStyle` (CYLTabBarItemStyle `flat` / `liquidGlass`), `animationSpeed`, `animationLoop`, `configuration`, `strings`, `symbolsByTheme`, `imageBasePath`, `animationBasePath`, `selectedIdentifier`,
`loggedIn`, `appVersion`. Events: `select`, `reselect`, `plustap`, `loginrequired` (detail: `index`, `identifier`,
`pageIdentifier`, `pageParameters`, `context`, `isPlusButton`). Methods: `cyl_selectIdentifier`, `cyl_showBadgeValue`,
`cyl_showBadgeDot`, `cyl_removeBadge`, `cyl_setThemeIdentifier`, `cyl_themeIdentifiers`, `cyl_playLottie`,
`cyl_selectAdjacent`, `cyl_setItemStyle`, `cyl_playAll`, `cyl_setAnimationSpeed`, `cyl_setAnimationLoop`. Page behavior for swiping between tabs: `cyl-tabbar-miniprogram/cyl-tab-bar/cyl_swipe_behavior`.

## Layout

| Path | What |
|:---|:---|
| `src/cyl-tab-bar/` | The component; `cyl_configuration.js` reads the configuration (no wx API, tested in Node) |
| `src/cyl-tab-bar-item/` | The icon and title of a tab (`CYLFlatDesignTabBarItem`); its abstract nodes take the animation components |
| `src/cyl-animation-placeholder/` | The default of the abstract nodes: an empty view for a library that is not installed |
| `test/` | Node tests of the configuration reader |
| `example/` | The example mini program: `project.config.json`, `miniprogram/` (pages, custom tab bar, generated `shared/`), `scripts/` |
| `../lottie-miniprogram/`, `../pag-miniprogram/`, `../rive-miniprogram/`, `../gif-miniprogram/` | The optional animation packages |

No code was copied from the projects listed as references in the documentation: see [NOTICE](NOTICE).
