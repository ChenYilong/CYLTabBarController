import fs from 'node:fs/promises'
import path from 'node:path'
import { promisify } from 'node:util'
import { brotliCompress, constants as zlibConstants } from 'node:zlib'
import { fileURLToPath } from 'node:url'

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const nativePackage = path.join(projectRoot, 'node_modules/@rive-app/canvas-advanced')
const nativeOutput = path.join(projectRoot, 'vendor/rive')
const compressBrotli = promisify(brotliCompress)

await fs.mkdir(nativeOutput, { recursive: true })

const nativeSource = await fs.readFile(path.join(nativePackage, 'canvas_advanced.mjs'), 'utf8')
const wasmBytes = await fs.readFile(path.join(nativePackage, 'rive.wasm'))
const fallbackWasmBytes = await fs.readFile(path.join(nativePackage, 'rive_fallback.wasm'))
const compressWasm = (bytes) => compressBrotli(bytes, {
  params: { [zlibConstants.BROTLI_PARAM_QUALITY]: 11 }
})
const [compressedWasmBytes, compressedFallbackWasmBytes] = await Promise.all([
  compressWasm(wasmBytes),
  compressWasm(fallbackWasmBytes)
])
const miniProgramSource = nativeSource.replace(
  'function(moduleArg = {}) {',
  `function(moduleArg = {}) {
  var document = moduleArg.document;
  var navigator = moduleArg.navigator;
  var performance = moduleArg.performance || {
    now: function() { return Date.now(); },
    mark: function() {},
    measure: function() {},
    clearMarks: function() {},
    clearMeasures: function() {}
  };
  var requestAnimationFrame = moduleArg.requestAnimationFrame;
  var cancelAnimationFrame = moduleArg.cancelAnimationFrame;
  var Path2D = moduleArg.Path2D;
  var DOMMatrix = moduleArg.DOMMatrix;
  var Image = moduleArg.Image;
  var Blob = moduleArg.Blob;
  var URL = moduleArg.URL;`
)
const assetSafeSource = miniProgramSource.replace(
  `    I.onload = function() {
      u.tb = I;
      u.Ca = ma.Ab(I);
      u.size(I.width, I.height);
      u.ha && u.ha(u);
    };
    I.src = u.Oa;`,
  `    var completed = !1;
    I.onload = function() {
      if (completed) return;
      completed = !0;
      u.tb = I;
      u.Ca = ma.Ab(I);
      u.size(I.width, I.height);
      u.ha && u.ha(u);
    };
    I.onerror = function() {
      if (completed) return;
      completed = !0;
      console.warn("Rive embedded image decode failed");
      URL.revokeObjectURL(u.Oa);
      u.Oa = "";
      u.ha && u.ha(u);
    };
    I.src = u.Oa;`
)
const resourceSafeSource = assetSafeSource.replace(
  '    this.Ca && (ma.Bb(this.Ca), URL.revokeObjectURL(this.Oa));',
  `    this.Ca && ma.Bb(this.Ca);
    this.Oa && URL.revokeObjectURL(this.Oa);`
)
const audioSafeSource = resourceSafeSource
  .replaceAll('window.AudioContext', 'moduleArg.audioWindow.AudioContext')
  .replaceAll('window.webkitAudioContext', 'moduleArg.audioWindow.webkitAudioContext')
  .replaceAll('window.miniaudio', 'moduleArg.audioWindow.miniaudio')
  .replace('"undefined" === typeof window ||', '!moduleArg.audioWindow ||')
const playbackOnlyAudioSource = audioSafeSource
  .replace(
    '489775:() => void 0 !== navigator.mediaDevices && void 0 !== navigator.mediaDevices.getUserMedia,',
    '489775:() => !1,'
  )
  .replace(
    'navigator.mediaDevices.getUserMedia({audio:!0, video:!1})',
    'Promise.reject(new Error("Audio capture disabled"))'
  )
const commonJsSource = playbackOnlyAudioSource.replace(
  /export default Rive;\s*$/,
  'module.exports = Rive;\n'
).replace(/[ \t]+$/gm, '')

if (
  miniProgramSource === nativeSource
  || assetSafeSource === miniProgramSource
  || resourceSafeSource === assetSafeSource
  || audioSafeSource === resourceSafeSource
  || playbackOnlyAudioSource === audioSafeSource
  || commonJsSource === playbackOnlyAudioSource
  || /window\.(?:AudioContext|webkitAudioContext|miniaudio)/.test(commonJsSource)
  || /getUserMedia/.test(commonJsSource)
) {
  throw new Error('Rive 原生运行时导出格式发生变化，请检查依赖版本')
}

await Promise.all([
  fs.writeFile(path.join(nativeOutput, 'canvas_advanced.js'), commonJsSource),
  fs.writeFile(path.join(nativeOutput, 'rive.wasm.br'), compressedWasmBytes),
  fs.writeFile(path.join(nativeOutput, 'rive_fallback.wasm.br'), compressedFallbackWasmBytes),
  fs.rm(path.join(nativeOutput, 'rive.wasm'), { force: true })
])

console.log('Rive 原生 Canvas 运行时与 Brotli WASM 已同步。')
