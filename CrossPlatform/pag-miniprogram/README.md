# cyl-pag-miniprogram

PAG animations for WeChat Mini Program: the `cyl-pag` component on
[libpag-lite-miniprogram](https://github.com/Tencent/libpag/tree/main/web/lite) 0.0.6 (Tencent, Apache-2.0, vendored in
`miniprogram_dist/libpag`). `cyl-tabbar-miniprogram` uses it for `.pag` tab icons through `cyl-tab-bar-item`.

```json
{ "usingComponents": { "cyl-pag": "cyl-pag-miniprogram/cyl-pag/index" } }
```

```xml
<cyl-pag path="/assets/2J.pag" loop autoplay style="width: 120px; height: 120px" />
```

Properties: `path` (package file, user data file or http(s) URL), `loop`, `autoplay`, `restingFrame` (first, last),
`fit` (contain, cover, fill), `label`; `colors` is accepted for parity with `cyl-lottie` and ignored. Events: `ready`,
`complete`, `loopcomplete`, `error`. Methods: `cyl_play`, `cyl_pause`, `cyl_stop`, `cyl_playFromStart`,
`cyl_setProgress`, `cyl_animation`.

**Limit of the lite library**: it plays PAG files made of **one BMP video sequence** only (in After Effects, export the
composition with BMP checked: File → Export → PAG File (Panel) → settings → BMP), decoded with `wx.createVideoDecoder`.
Vector PAG files (for example the iOS example's tab icons) emit `error` ("PAGFile has no BMP video sequence!"); they need
the full `libpag-miniprogram` (WebAssembly). See [docs/WeChat-Mini-Program.md](../../docs/WeChat-Mini-Program.md).
