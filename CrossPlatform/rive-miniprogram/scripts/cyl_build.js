#!/usr/bin/env node
/**
 * [EN] Builds miniprogram_dist/rive from @rive-app/canvas-advanced 2.39.1 (MIT, `npm install` first), the way
 *      RiveViewer-miniapp's README describes running Rive in a mini program (its code itself is not used):
 *      - canvas_advanced.js: the ES module as CommonJS, with the browser names a mini program lacks declared inside
 *        the module: Path2D (canvas.createPath2D() of the canvas being drawn), DOMMatrix, performance and
 *        requestAnimationFrame / cancelAnimationFrame (the canvas's own);
 *      - rive.wasm.br: rive.wasm compressed with Brotli, which WXWebAssembly loads from the package (2 MB -> about
 *        570 KB).
 * [CN] 从 @rive-app/canvas-advanced 2.39.1（MIT，先执行 `npm install`）构建 miniprogram_dist/rive，方式与
 *      RiveViewer-miniapp README 描述的在小程序中运行 Rive 的方式相同（不使用其代码）：
 *      - canvas_advanced.js：ES 模块转为 CommonJS，并在模块内声明小程序缺少的浏览器名称：Path2D（当前绘制画布的
 *        canvas.createPath2D()）、DOMMatrix、performance 与 requestAnimationFrame / cancelAnimationFrame（画布自己的）；
 *      - rive.wasm.br：用 Brotli 压缩的 rive.wasm，WXWebAssembly 可以从包内加载（2 MB -> 约 570 KB）。
 */
const fs = require('fs')
const path = require('path')
const zlib = require('zlib')

const CYL_ROOT = path.resolve(__dirname, '..')
const CYL_SOURCE = path.join(CYL_ROOT, 'node_modules', '@rive-app', 'canvas-advanced')
const CYL_TARGET = path.join(CYL_ROOT, 'miniprogram_dist', 'rive')

const CYL_HEADER = `// Built by scripts/cyl_build.js from @rive-app/canvas-advanced ${require(path.join(CYL_SOURCE, 'package.json')).version} (MIT, Copyright (c) Rive); do not edit by hand.
// [EN] Browser names the runtime uses and a mini program does not have, declared for this module only.
// [CN] 运行时使用而小程序没有的浏览器名称，只在本模块内声明。
var CYLRiveEnvironment = { canvas: null };
var Path2D = function CYLPath2D(source) {
  var canvas = CYLRiveEnvironment.canvas;
  if (!canvas || typeof canvas.createPath2D !== 'function') {
    throw new Error('cyl-rive: Path2D needs the node of a <canvas type="2d">.');
  }
  return canvas.createPath2D(source);
};
var DOMMatrix = function CYLDOMMatrix() {
  this.a = 1; this.b = 0; this.c = 0; this.d = 1; this.e = 0; this.f = 0;
};
var performance = { now: function () { return Date.now(); } };
// [EN] Only the image-mesh helper (WebGL) and the FPS overlay create elements: a canvas without WebGL makes the runtime log
//      "No WebGL support" and skip image meshes, which tab icons do not use.
// [CN] 只有图片网格辅助（WebGL）与 FPS 浮层会创建元素：没有 WebGL 的 canvas 让运行时输出 "No WebGL support" 并跳过
//      图片网格，Tab 图标用不到。
var CYLRiveElement = function () {
  return { style: {}, innerHTML: '', getContext: function () { return null; }, remove: function () {}, appendChild: function () {} };
};
var document = {
  body: { appendChild: function () {}, remove: function () {} },
  createElement: CYLRiveElement,
  addEventListener: function () {},
  removeEventListener: function () {},
};
var navigator = { userAgent: '' };
var requestAnimationFrame = function (callback) {
  var canvas = CYLRiveEnvironment.canvas;
  return canvas && canvas.requestAnimationFrame ? canvas.requestAnimationFrame(callback) : setTimeout(function () { callback(Date.now()); }, 16);
};
var cancelAnimationFrame = function (id) {
  var canvas = CYLRiveEnvironment.canvas;
  if (canvas && canvas.cancelAnimationFrame) { canvas.cancelAnimationFrame(id); } else { clearTimeout(id); }
};
`

function cylMain() {
  const source = fs.readFileSync(path.join(CYL_SOURCE, 'canvas_advanced.mjs'), 'utf8')
  if (!source.includes('export default Rive;')) {
    throw new Error('canvas_advanced.mjs no longer ends with "export default Rive;": update scripts/cyl_build.js.')
  }
  const body = source.replace('export default Rive;', 'module.exports = { Rive: Rive, CYLRiveEnvironment: CYLRiveEnvironment };')
  fs.mkdirSync(CYL_TARGET, { recursive: true })
  fs.writeFileSync(path.join(CYL_TARGET, 'canvas_advanced.js'), CYL_HEADER + body)
  const wasm = fs.readFileSync(path.join(CYL_SOURCE, 'rive.wasm'))
  const compressed = zlib.brotliCompressSync(wasm, {
    params: { [zlib.constants.BROTLI_PARAM_QUALITY]: 11, [zlib.constants.BROTLI_PARAM_SIZE_HINT]: wasm.length },
  })
  fs.writeFileSync(path.join(CYL_TARGET, 'rive.wasm.br'), compressed)
  console.log(`canvas_advanced.js ${fs.statSync(path.join(CYL_TARGET, 'canvas_advanced.js')).size} B, rive.wasm ${wasm.length} B -> rive.wasm.br ${compressed.length} B`)
}

cylMain()
