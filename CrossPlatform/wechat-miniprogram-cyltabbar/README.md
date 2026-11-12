# cyl-tabbar-miniprogram

CYLTabBarController for WeChat Mini Program: `cyl-tab-bar`, a custom tab bar component configured with the same keys as
the iOS and Android libraries ([docs/Configuration-File.md](../../docs/Configuration-File.md)), with Lottie tab icons
through its sub-dependency [`cyl-lottie-miniprogram`](../lottie-miniprogram). Full documentation, the scores (keys, API,
lottie-miniprogram issues) and the screenshots: [docs/WeChat-Mini-Program.md](../../docs/WeChat-Mini-Program.md).

## Run the example

1. `cd example && npm run setup` (Node 18+, no network): installs `cyl-tabbar-miniprogram` and its sub-dependency
   `cyl-lottie-miniprogram` into `example/miniprogram/miniprogram_npm`, and copies the shared configuration,
   localization tables, skin images and Lottie icons into `example/miniprogram/shared`.
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
symbolic links): it installs the package and `cyl-lottie-miniprogram`, its own relative-path dependency.

```json
// app.json
{ "tabBar": { "custom": true, "list": [{ "pagePath": "pages/home/index", "text": "Home" }] } }
// custom-tab-bar/index.json
{ "component": true, "usingComponents": { "cyl-tab-bar": "cyl-tabbar-miniprogram/cyl-tab-bar/index" } }
```

```xml
<!-- custom-tab-bar/index.wxml -->
<cyl-tab-bar configuration="{{configuration}}" selected-identifier="{{selected}}" animation-base-path="/assets/lottie" bind:select="onSelect" />
```

Properties: `configuration`, `strings`, `symbolsByTheme`, `imageBasePath`, `animationBasePath`, `selectedIdentifier`,
`loggedIn`, `appVersion`. Events: `select`, `reselect`, `plustap`, `loginrequired` (detail: `index`, `identifier`,
`pageIdentifier`, `pageParameters`, `context`, `isPlusButton`). Methods: `cyl_selectIdentifier`, `cyl_showBadgeValue`,
`cyl_showBadgeDot`, `cyl_removeBadge`, `cyl_setThemeIdentifier`, `cyl_themeIdentifiers`, `cyl_playLottie`,
`cyl_selectAdjacent`. Page behavior for swiping between tabs: `cyl-tabbar-miniprogram/cyl-tab-bar/cyl_swipe_behavior`.

## Layout

| Path | What |
|:---|:---|
| `src/cyl-tab-bar/` | The component; `cyl_configuration.js` reads the configuration (no wx API, tested in Node) |
| `test/` | Node tests of the configuration reader |
| `example/` | The example mini program: `project.config.json`, `miniprogram/` (pages, custom tab bar, generated `shared/`), `scripts/` |
| `../lottie-miniprogram/` | `cyl-lottie-miniprogram`: the `cyl-lottie` component and the lottie library |

No code was copied from the projects listed as references in the documentation: see [NOTICE](NOTICE).
