# cyl-pag-miniprogram

PAG animations for WeChat Mini Program: the `cyl-pag` component on
[libpag-miniprogram](https://github.com/Tencent/libpag/tree/main/web) 4.5.85 (Tencent, Apache-2.0, the full WebAssembly +
WebGL build, vendored in `miniprogram_dist/libpag`). It plays vector PAG files, such as the iOS example's tab icons.
`cyl-tabbar-miniprogram` uses it for `.pag` tab icons through `cyl-tab-bar-item`.

```json
{ "usingComponents": { "cyl-pag": "cyl-pag-miniprogram/cyl-pag/index" } }
```

```xml
<cyl-pag path="/assets/tab_home.pag.bin" loop autoplay style="width: 120px; height: 120px" />
```

Properties: `path` (package file, user data file or http(s) URL), `loop`, `autoplay`, `restingFrame` (first, last),
`fit` (contain, cover, fill), `label`, `wasmPath`; `colors` is accepted for parity with `cyl-lottie` and ignored. Events: `ready`,
`complete`, `loopcomplete`, `error`. Methods: `cyl_play`, `cyl_pause`, `cyl_stop`, `cyl_playFromStart`,
`cyl_setProgress`, `cyl_animation`.

**WebAssembly**: a mini program cannot read files under `miniprogram_npm`, so copy
`miniprogram_dist/libpag/libpag.wasm.br` (listed in `cylMiniprogramAssets`) to `/cyl-pag-miniprogram/libpag.wasm.br` in
the code package, or set the `wasmPath` property. The example's installer does it. Version 4.4.76 (November 2026) fails
in WeChat DevTools ("UnboundTypeError: Cannot call VectorString.push_back"); 4.5.85 works. See
[docs/WeChat-Mini-Program.md](../../docs/WeChat-Mini-Program.md).
