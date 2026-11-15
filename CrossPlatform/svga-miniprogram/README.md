# cyl-svga-miniprogram

SVGA animations for WeChat Mini Program: the `cyl-svga` component, an SVGA 2.x player written for the mini program
`<canvas type="2d">`. Its properties, events and methods are those of `cyl-lottie`, `cyl-pag` and `cyl-rive`, so
`cyl-tab-bar` of `cyl-tabbar-miniprogram` shows SVGA tab icons through its `cyl-svga-view` generic.

SVGA 2.x 动画的微信小程序组件 `cyl-svga`：为小程序 `<canvas type="2d">` 编写的 SVGA 2.x 播放器。属性、事件与方法与
`cyl-lottie`、`cyl-pag`、`cyl-rive` 相同，`cyl-tabbar-miniprogram` 的 `cyl-tab-bar` 通过泛型 `cyl-svga-view` 显示 SVGA Tab 图标。

```html
<cyl-tab-bar generic:cyl-svga-view="cyl-svga" configuration="{{configuration}}" />
```

```json
{ "usingComponents": { "cyl-svga": "cyl-svga-miniprogram/cyl-svga/index" } }
```

Tab attributes: `CYLTabBarSVGAFilePath` / `CYLTabBarSVGAURL` (and the `Dark` variants), `CYLTabBarSVGASize`, as on iOS and
Android. A mini program code package cannot hold `.svga` files: copy them as `.svga.bin`, or load them from a URL or the
user data folder.

- Supported: SVGA 2.x (zlib-compressed protobuf): bitmaps, vector shapes (paths, rects, ellipses, fill, stroke, dash),
  alpha, transforms, clip paths. Not yet: masks (`matteKey`), audio; SVGA 1.x (ZIP) files are rejected with an error.
- Tests: `npm test` (decoding and drawing of the example files, the component with a fake `wx`).
- `npm run build` rebuilds `miniprogram_dist/svga/fflate.js` from fflate 0.8.2 (`npm install` first).
