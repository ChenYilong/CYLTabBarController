import fs from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const modulePath = path.join(
  projectRoot,
  'node_modules/@rive-app/canvas-advanced/canvas_advanced.mjs'
)
const wasmPath = path.join(projectRoot, 'node_modules/@rive-app/canvas-advanced/rive.wasm')
const inputPaths = process.argv.slice(2).length
  ? process.argv.slice(2).map((value) => path.resolve(value))
  : [
      path.join(projectRoot, 'assets/samples/guide.riv'),
      path.join(projectRoot, 'assets/samples/question.riv')
    ]

globalThis.document = {
  createElement() {
    return { getContext: () => null }
  }
}
Object.defineProperty(globalThis, 'navigator', {
  value: { userAgent: 'Node' },
  configurable: true
})

const factory = (await import(pathToFileURL(modulePath).href)).default
const runtime = await factory({ wasmBinary: await fs.readFile(wasmPath) })
const metadataOnlyAssetLoader = new runtime.CustomFileAssetLoader({
  loadContents() {
    // Metadata inspection does not need to decode embedded images/audio in Node.
    return true
  }
})

for (const filePath of inputPaths) {
  const file = await runtime.load(
    new Uint8Array(await fs.readFile(filePath)),
    metadataOnlyAssetLoader,
    false
  )
  const result = { file: path.basename(filePath), artboards: [] }
  for (let index = 0; index < file.artboardCount(); index += 1) {
    const artboard = file.artboardByIndex(index)
    const bounds = artboard.bounds
    const item = {
      name: artboard.name,
      width: Math.round(bounds.maxX - bounds.minX),
      height: Math.round(bounds.maxY - bounds.minY),
      animations: [],
      stateMachines: []
    }
    for (let animationIndex = 0; animationIndex < artboard.animationCount(); animationIndex += 1) {
      item.animations.push(artboard.animationByIndex(animationIndex).name)
    }
    for (let machineIndex = 0; machineIndex < artboard.stateMachineCount(); machineIndex += 1) {
      const definition = artboard.stateMachineByIndex(machineIndex)
      const instance = new runtime.StateMachineInstance(definition, artboard)
      const inputs = []
      for (let inputIndex = 0; inputIndex < instance.inputCount(); inputIndex += 1) {
        const input = instance.input(inputIndex)
        const type = input.type === runtime.SMIInput.trigger
          ? 'trigger'
          : input.type === runtime.SMIInput.bool
            ? 'boolean'
            : 'number'
        inputs.push({ name: input.name, type })
      }
      item.stateMachines.push({
        name: definition.name,
        inputs,
        hasListeners: Boolean(runtime.hasListeners?.(instance))
      })
      instance.delete()
    }
    result.artboards.push(item)
    artboard.delete()
  }
  file.unref()
  console.log(JSON.stringify(result, null, 2))
}
