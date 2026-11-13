import fs from 'node:fs/promises'
import path from 'node:path'
import { performance } from 'node:perf_hooks'
import { fileURLToPath, pathToFileURL } from 'node:url'

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const testRoot = path.join(projectRoot, 'rive测试文件')
const sampleRoot = path.join(projectRoot, 'assets/samples')
const modulePath = path.join(
  projectRoot,
  'node_modules/@rive-app/canvas-advanced/canvas_advanced.mjs'
)
const wasmPath = path.join(projectRoot, 'node_modules/@rive-app/canvas-advanced/rive.wasm')

globalThis.document = {
  createElement() {
    return { getContext: () => null }
  }
}
Object.defineProperty(globalThis, 'navigator', {
  value: { userAgent: 'Node' },
  configurable: true
})
globalThis.Image = class BenchmarkImage {
  constructor() {
    this.width = 1
    this.height = 1
  }

  set src(value) {
    this.source = value
    queueMicrotask(() => this.onload?.())
  }
}
const log = console.log.bind(console)
console.log = (...args) => {
  if (args[0] !== 'No WebGL support. Image mesh will not be drawn.') log(...args)
}

async function findRiveFiles(directory) {
  const entries = await fs.readdir(directory, { withFileTypes: true })
  const nested = await Promise.all(entries.map(async (entry) => {
    const filePath = path.join(directory, entry.name)
    if (entry.isDirectory()) return findRiveFiles(filePath)
    return entry.isFile() && entry.name.toLowerCase().endsWith('.riv') ? [filePath] : []
  }))
  return nested.flat()
}

function round(value) {
  return Math.round(value * 10) / 10
}

const factory = (await import(pathToFileURL(modulePath).href)).default
const runtimeStart = performance.now()
const runtime = await factory({ wasmBinary: await fs.readFile(wasmPath) })
const runtimeMs = performance.now() - runtimeStart
const inputFiles = process.argv.slice(2).map((item) => path.resolve(item))
const benchmarkRoot = await fs.access(testRoot).then(() => testRoot).catch(() => sampleRoot)
const riveFiles = inputFiles.length ? inputFiles : await findRiveFiles(benchmarkRoot)
const rows = []

for (const filePath of riveFiles.sort()) {
  let file = null
  let artboard = null
  let machine = null
  const readStart = performance.now()
  const bytes = await fs.readFile(filePath)
  const readMs = performance.now() - readStart
  const loadStart = performance.now()
  try {
    file = await runtime.load(new Uint8Array(bytes), undefined, false)
    const loadMs = performance.now() - loadStart
    const inspectStart = performance.now()
    const artboardCount = file.artboardCount()
    let animationCount = 0
    let machineCount = 0
    for (let index = 0; index < artboardCount; index += 1) {
      const inspected = file.artboardByIndex(index)
      animationCount += inspected.animationCount()
      machineCount += inspected.stateMachineCount()
      inspected.delete()
    }
    const inspectMs = performance.now() - inspectStart

    artboard = file.artboardByIndex(0)
    if (artboard.stateMachineCount() > 0) {
      machine = new runtime.StateMachineInstance(artboard.stateMachineByIndex(0), artboard)
    }
    const frameStart = performance.now()
    for (let frame = 0; frame < 120; frame += 1) {
      machine?.advance(1 / 60)
      artboard.advance(1 / 60)
    }
    const advance120Ms = performance.now() - frameStart
    rows.push({
      file: path.relative(benchmarkRoot, filePath),
      mb: round(bytes.byteLength / 1024 / 1024),
      readMs: round(readMs),
      loadMs: round(loadMs),
      inspectMs: round(inspectMs),
      advance120Ms: round(advance120Ms),
      artboards: artboardCount,
      animations: animationCount,
      machines: machineCount
    })
  } catch (error) {
    rows.push({
      file: path.relative(benchmarkRoot, filePath),
      mb: round(bytes.byteLength / 1024 / 1024),
      error: error.message || String(error)
    })
  } finally {
    machine?.delete()
    artboard?.delete()
    file?.unref()
  }
}

console.log(`Rive runtime 初始化：${round(runtimeMs)} ms`)
console.table(rows)
