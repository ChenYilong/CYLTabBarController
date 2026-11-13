# cyl-rive-miniprogram

Rive animations for WeChat Mini Program: the `cyl-rive` component on
[@rive-app/canvas-advanced](https://github.com/rive-app/rive-wasm) 2.39.1 (MIT) running on a `<canvas type="2d">`, its
WebAssembly loaded by `WXWebAssembly` from `miniprogram_dist/rive/rive.wasm.br` (573 KB). `cyl-tabbar-miniprogram` uses
it for `.riv` tab icons through `cyl-tab-bar-item`.

```json
{ "usingComponents": { "cyl-rive": "cyl-rive-miniprogram/cyl-rive/index" } }
```

```xml
<cyl-rive path="/assets/icons.riv.bin#artboard=CHAT&stateMachine=CHAT_Interactivity&input=active" style="width: 64px; height: 64px" />
```

A mini program code package leaves out `.riv` files: name package copies `*.riv.bin`, or load from an http(s) URL.

Properties: `path` (with optional options in its fragment), `artboard`, `stateMachine`, `input` / `triggerInput` (legacy
state machine inputs), `active` / `trigger` (view model properties), `duration` (seconds the input stays true, default 1),
`colors` (view model color path -> color), `loop` (turns the input on again after each play), `speed` (render clock and input duration, applied live), `autoplay`, `fit`, `label`, `wasmPath` (default
`/cyl-rive-miniprogram/rive.wasm.br`). A mini program cannot read files under `miniprogram_npm` (`readFileSync` and
`WXWebAssembly` answer "permission denied"), so copy `miniprogram_dist/rive/rive.wasm.br` to that path in your package
(listed in `cylMiniprogramAssets` of `package.json`; the example's installer does it) or set `wasmPath`. Events: `ready` (artboard, state machine, inputs),
`complete`, `error`. Methods: `cyl_play`, `cyl_pause`, `cyl_stop`, `cyl_playFromStart`, `cyl_input`, `cyl_animation`.

Build: `npm install && npm run build` (writes `miniprogram_dist/rive`, committed). The approach follows the README of
RiveViewer-miniapp; see [NOTICE](NOTICE) and [docs/WeChat-Mini-Program.md](../../docs/WeChat-Mini-Program.md).
