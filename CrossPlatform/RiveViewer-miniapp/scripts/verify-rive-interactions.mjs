import assert from 'node:assert/strict'
import fs from 'node:fs/promises'
import path from 'node:path'
import { createRequire } from 'node:module'
import { fileURLToPath, pathToFileURL } from 'node:url'

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const modulePath = path.join(
  projectRoot,
  'node_modules/@rive-app/canvas-advanced/canvas_advanced.mjs'
)
const wasmPath = path.join(projectRoot, 'node_modules/@rive-app/canvas-advanced/rive.wasm')
const vendoredModulePath = path.join(projectRoot, 'vendor/rive/canvas_advanced.js')
const require = createRequire(import.meta.url)
const {
  collectPianoCueChanges,
  createPianoCueBindings,
  detectEmbeddedImageExtension,
  getAudioBlockedReason,
  getPlaybackPerformanceProfile,
  isCompatibleCueAudioContext,
  isCompatibleWebAudioContext,
  isPianoAudioCandidate,
  MAX_AUDIO_SOURCE_BYTES,
  MiniProgramCueAudio,
  NativeRivePlayer,
  resumeAudioDevices,
  suspendAudioDevices,
  shouldBypassEmbeddedAudio
} = require('../utils/rive-native')

globalThis.document = {
  createElement() {
    return { getContext: () => null }
  },
  addEventListener() {},
  removeEventListener() {}
}
Object.defineProperty(globalThis, 'navigator', {
  value: { userAgent: 'Node' },
  configurable: true
})

const factory = (await import(pathToFileURL(modulePath).href)).default
const runtime = await factory({ wasmBinary: await fs.readFile(wasmPath) })
const metadataOnlyAssetLoader = new runtime.CustomFileAssetLoader({
  loadContents() {
    return true
  }
})

async function loadRive(relativePath) {
  return runtime.load(
    new Uint8Array(await fs.readFile(path.join(projectRoot, relativePath))),
    metadataOnlyAssetLoader,
    false
  )
}

function advanceStateMachine(machine, artboard, elapsed = 0) {
  machine.advance(elapsed)
  artboard.advance(elapsed)
}

async function verifyGuideIdleFallback() {
  const file = await loadRive('assets/samples/guide.riv')
  const artboard = file.artboardByName('叫叫')
  const machine = new runtime.StateMachineInstance(
    artboard.stateMachineByName('jojo-machine'),
    artboard
  )
  advanceStateMachine(machine, artboard)
  machine.input(1).asTrigger().fire()
  advanceStateMachine(machine, artboard)
  const changedStates = Array.from(
    { length: machine.stateChangedCount() },
    (_, index) => machine.stateChangedNameByIndex(index)
  )
  const hasIdleTimeline = Array.from(
    { length: artboard.animationCount() },
    (_, index) => artboard.animationByIndex(index).name
  ).some((name) => name.toLowerCase() === 'idle')

  assert.ok(changedStates.length > 0)
  assert.ok(changedStates.every((name) => !String(name || '').trim()))
  assert.equal(hasIdleTimeline, true)

  machine.delete()
  artboard.delete()
  file.unref()
}

async function verifyPianoAutoBinding() {
  const file = await loadRive('rive测试文件/Rive/27375-51723-a-piano-game.riv')
  const artboard = file.artboardByName('StageAPT')
  const machine = new runtime.StateMachineInstance(
    artboard.stateMachineByName('Piano Game'),
    artboard
  )
  const viewModel = file.defaultArtboardViewModel(artboard)
  const viewModelInstance = viewModel.defaultInstance()
  machine.setViewModelInstance(viewModelInstance)
  machine.bind()

  const keyD = () => (
    viewModelInstance.viewModel('pianoKeys').boolean('keyD').value
  )
  advanceStateMachine(machine, artboard, 1 / 60)
  assert.equal(keyD(), false)
  const pianoCueBindings = createPianoCueBindings(viewModelInstance)
  assert.ok(pianoCueBindings.length >= 12)

  machine.pointerDown(300, 500, 7)
  advanceStateMachine(machine, artboard)
  assert.equal(keyD(), true)
  assert.ok(collectPianoCueChanges(pianoCueBindings).includes('D'))
  assert.equal(collectPianoCueChanges(pianoCueBindings).includes('D'), false)

  machine.pointerUp(300, 500, 7)
  machine.pointerExit(300, 500, 7)
  advanceStateMachine(machine, artboard)
  assert.equal(keyD(), false)
  collectPianoCueChanges(pianoCueBindings)

  machine.pointerDown(300, 500, 7)
  advanceStateMachine(machine, artboard)
  assert.ok(collectPianoCueChanges(pianoCueBindings).includes('D'))

  machine.delete()
  pianoCueBindings.owners.forEach((owner) => owner.unref())
  viewModelInstance.unref()
  artboard.delete()
  file.unref()
}

async function verifyMiniProgramRuntimeFallbacks() {
  let capturedMatrix = null
  const revokedUrls = []

  class TestPath2D {
    addPath(path, matrix) {
      capturedMatrix = {
        a: matrix.a,
        b: matrix.b,
        c: matrix.c,
        d: matrix.d,
        e: matrix.e,
        f: matrix.f
      }
    }
  }

  class TestDOMMatrix {
    constructor() {
      this.a = 1
      this.b = 0
      this.c = 0
      this.d = 1
      this.e = 0
      this.f = 0
    }
  }

  class TestImage {
    static shouldFail = true

    set src(value) {
      this.source = value
      queueMicrotask(() => {
        if (TestImage.shouldFail) {
          this.onerror?.(new Error('mock decode failure'))
          return
        }
        this.width = 2
        this.height = 2
        this.onload?.()
      })
    }
  }

  class TestBlob {
    constructor(parts = []) {
      this.parts = parts
    }
  }

  const globalMatrixDescriptor = Object.getOwnPropertyDescriptor(globalThis, 'DOMMatrix')
  try {
    delete globalThis.DOMMatrix
    const factory = (await import(pathToFileURL(vendoredModulePath).href)).default
    const vendoredRuntime = await factory({
      wasmBinary: await fs.readFile(wasmPath),
      document: globalThis.document,
      navigator: globalThis.navigator,
      performance: globalThis.performance,
      requestAnimationFrame: (callback) => setTimeout(() => callback(performance.now()), 16),
      cancelAnimationFrame: (requestId) => clearTimeout(requestId),
      Path2D: TestPath2D,
      DOMMatrix: TestDOMMatrix,
      Image: TestImage,
      Blob: TestBlob,
      URL: {
        createObjectURL: () => 'mock://embedded-image',
        revokeObjectURL: (url) => revokedUrls.push(url)
      }
    })

    const leftPath = vendoredRuntime.renderFactory.makeRenderPath()
    const rightPath = vendoredRuntime.renderFactory.makeRenderPath()
    leftPath.addPath(rightPath, 1, 2, 3, 4, 5, 6)
    assert.deepEqual(capturedMatrix, { a: 1, b: 2, c: 3, d: 4, e: 5, f: 6 })
    leftPath.delete()
    rightPath.delete()

    const decodedImage = await Promise.race([
      new Promise((resolve) => {
        vendoredRuntime.decodeImage(new Uint8Array([0x52, 0x49, 0x46, 0x46]), resolve)
      }),
      new Promise((resolve, reject) => {
        setTimeout(() => reject(new Error('嵌入图片失败回调未结束等待')), 500)
      })
    ])
    assert.equal(revokedUrls.length, 1)
    decodedImage.delete()

    TestImage.shouldFail = false
    const successfulImage = await new Promise((resolve) => {
      vendoredRuntime.decodeImage(new Uint8Array([0x89, 0x50, 0x4e, 0x47]), resolve)
    })
    assert.equal(revokedUrls.length, 1)
    successfulImage.delete()
    assert.equal(revokedUrls.length, 2)
  } finally {
    if (globalMatrixDescriptor) {
      Object.defineProperty(globalThis, 'DOMMatrix', globalMatrixDescriptor)
    } else {
      delete globalThis.DOMMatrix
    }
  }
}

function verifyEmbeddedImageExtensions() {
  assert.equal(detectEmbeddedImageExtension(
    new Uint8Array([0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50])
  ), 'webp')
  assert.equal(detectEmbeddedImageExtension(
    new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
  ), 'png')
  assert.equal(detectEmbeddedImageExtension(new Uint8Array([0xff, 0xd8, 0xff])), 'jpg')
  assert.equal(detectEmbeddedImageExtension(
    new Uint8Array([0x47, 0x49, 0x46, 0x38, 0x39, 0x61])
  ), 'gif')
}

function verifyAudioCompatibilityPolicy() {
  const compatibleContext = {
    sampleRate: 48000,
    destination: {},
    createScriptProcessor() {},
    resume() {},
    suspend() {},
    close() {}
  }
  assert.equal(isCompatibleWebAudioContext(compatibleContext), true)
  assert.equal(isCompatibleWebAudioContext({ ...compatibleContext, suspend: undefined }), false)
  assert.equal(shouldBypassEmbeddedAudio({ isAudio: true }, false), true)
  assert.equal(shouldBypassEmbeddedAudio({ isAudio: true }, true), false)
  assert.equal(shouldBypassEmbeddedAudio({ isImage: true }, false), false)
  assert.equal(MAX_AUDIO_SOURCE_BYTES, 8 * 1024 * 1024)
  assert.equal(getAudioBlockedReason(1024 * 1024, true), '')
  assert.equal(
    getAudioBlockedReason(MAX_AUDIO_SOURCE_BYTES + 1, true),
    '大文件已启用性能保护'
  )
  assert.equal(getAudioBlockedReason(1024, false), '当前微信版本不支持声音')

  assert.deepEqual(
    getPlaybackPerformanceProfile({
      hasAudio: true,
      isIOS: true,
      isComplexFile: false,
      pixelRatio: 3
    }),
    { frameInterval: 1000 / 30, pixelRatio: 1.5 }
  )
  assert.deepEqual(
    getPlaybackPerformanceProfile({
      hasAudio: false,
      isIOS: true,
      isComplexFile: true,
      pixelRatio: 2
    }),
    { frameInterval: 1000 / 24, pixelRatio: 1.25 }
  )
}

async function verifyLazyArtboardCatalog() {
  const deleted = []
  const metadataEvents = []
  const progressEvents = []
  const player = Object.create(NativeRivePlayer.prototype)
  Object.assign(player, {
    disposed: false,
    file: {
      artboardByIndex(index) {
        return {
          name: ['Main', 'Second', 'Third'][index],
          delete() { deleted.push(index) }
        }
      }
    },
    isIOS: false,
    totalArtboardCount: 3,
    activeArtboardName: 'Main',
    selectedStateMachineName: 'Main Machine',
    activeAnimationName: '',
    inputRefs: [],
    hasAudio: false,
    audioEnabled: true,
    audioSupported: true,
    audioBlockedReason: '',
    fitKey: 'cover',
    alignmentKey: 'center',
    artboardCatalogPromise: null,
    artboardCatalogProgressCallbacks: new Set(),
    metadata: {
      artboardCount: 3,
      artboardCatalogLoaded: false,
      artboards: [{
        name: 'Main',
        width: 3000,
        height: 3000,
        animations: ['Main'],
        stateMachines: [{ name: 'Main Machine', inputs: [] }],
        loaded: true
      }]
    },
    onMetadata(metadata) { metadataEvents.push(metadata) }
  })

  const metadata = await player.loadArtboardCatalog((progress) => {
    progressEvents.push(progress)
  })
  assert.deepEqual(deleted, [1, 2])
  assert.equal(metadata.artboardCount, 3)
  assert.equal(metadata.artboardCatalogLoaded, true)
  assert.deepEqual(metadata.artboards.map((item) => item.name), ['Main', 'Second', 'Third'])
  assert.deepEqual(metadata.artboards.map((item) => item.loaded), [true, false, false])
  assert.equal(metadataEvents.length, 1)
  assert.equal(progressEvents.at(-1).progress, 100)

  const cachedMetadata = await player.loadArtboardCatalog()
  assert.equal(cachedMetadata.artboards.length, 3)
  assert.deepEqual(deleted, [1, 2])
}

function verifyPausedRenderScheduling() {
  let nextRequestId = 0
  let requestCount = 0
  let cancelCount = 0
  let drawCount = 0
  const player = Object.create(NativeRivePlayer.prototype)
  Object.assign(player, {
    canvas: { width: 320, height: 240 },
    runtime: {
      requestAnimationFrame() {
        requestCount += 1
        nextRequestId += 1
        return nextRequestId
      },
      cancelAnimationFrame() { cancelCount += 1 },
      Fit: { cover: 0 },
      Alignment: { center: 0 }
    },
    renderer: {
      clear() {},
      save() {},
      align() {},
      restore() {},
      flush() {}
    },
    artboard: {
      bounds: { minX: 0, minY: 0, maxX: 320, maxY: 240 },
      draw() { drawCount += 1 }
    },
    disposed: false,
    playing: true,
    needsRedraw: false,
    frameRequest: 0,
    frameInterval: 0,
    lastRenderAt: 0,
    lastTime: 0,
    speed: 1,
    fitKey: 'cover',
    alignmentKey: 'center',
    stateMachine: null,
    animation: null,
    sequenceMode: false,
    firstFrameRendered: true,
    hasAudio: false,
    activeAnimationName: '',
    emitTimelineProgress() {},
    onPlaybackChange() {},
    resumeAudioPlayback() {},
    advanceSequence() {}
  })

  assert.equal(player.scheduleRender(), true)
  assert.equal(requestCount, 1)
  player.pause()
  assert.equal(cancelCount, 1)
  assert.equal(player.frameRequest, 0)

  player.requestRedraw()
  assert.equal(requestCount, 2)
  player.renderFrame(100)
  assert.equal(drawCount, 1)
  assert.equal(player.frameRequest, 0)
  assert.equal(requestCount, 2)

  player.play()
  assert.equal(requestCount, 3)
}

async function verifyAudioResumeCoalescing() {
  let resumeCount = 0
  let suspendCount = 0
  let finishResume = null
  const context = {
    state: 'suspended',
    resume() {
      resumeCount += 1
      return new Promise((resolve) => {
        finishResume = () => {
          context.state = 'running'
          resolve()
        }
      })
    },
    suspend() {
      suspendCount += 1
      context.state = 'suspended'
      return Promise.resolve()
    }
  }
  const devices = [{ I: context }]
  assert.equal(resumeAudioDevices(devices), true)
  assert.equal(resumeAudioDevices(devices), true)
  assert.equal(resumeCount, 1)
  finishResume()
  await new Promise((resolve) => setTimeout(resolve, 0))
  resumeAudioDevices(devices)
  assert.equal(resumeCount, 1)
  suspendAudioDevices(devices)
  assert.equal(suspendCount, 1)
  resumeAudioDevices(devices)
  assert.equal(resumeCount, 2)
  finishResume()
  await new Promise((resolve) => setTimeout(resolve, 0))
}

async function verifyNativePianoCueAudio() {
  const originalWx = globalThis.wx
  const decodedFirstBytes = []
  const sources = []
  let throwOnStart = false
  let resumeCount = 0
  let suspendCount = 0
  let closeCount = 0
  let finishCueResume = null
  const context = {
    destination: {},
    state: 'suspended',
    decodeAudioData(data, success) {
      decodedFirstBytes.push(new Uint8Array(data)[0])
      queueMicrotask(() => success({ id: decodedFirstBytes.length }))
    },
    createBufferSource() {
      const source = {
        connected: false,
        started: false,
        stopped: false,
        connect() { source.connected = true },
        disconnect() { source.connected = false },
        start() {
          if (throwOnStart) throw new Error('mock start failure')
          source.started = true
        },
        stop() { source.stopped = true }
      }
      sources.push(source)
      return source
    },
    resume() {
      resumeCount += 1
      return new Promise((resolve) => {
        finishCueResume = () => {
          context.state = 'running'
          resolve()
        }
      })
    },
    suspend() {
      suspendCount += 1
      context.state = 'suspended'
      return Promise.resolve()
    },
    close() {
      closeCount += 1
      context.state = 'closed'
      return Promise.resolve()
    }
  }
  globalThis.wx = { createWebAudioContext: () => context }
  try {
    assert.equal(isCompatibleCueAudioContext(context), true)
    const signature = new TextEncoder().encode('prefix Piano Game pianoKeys suffix')
    assert.equal(isPianoAudioCandidate('renamed.riv', signature), true)
    assert.equal(isPianoAudioCandidate('ordinary.riv', new Uint8Array([1, 2, 3])), false)

    const player = new MiniProgramCueAudio()
    const assetNames = [
      'A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#',
      'switch', 'power01', 'power02'
    ]
    assetNames.forEach((name, index) => {
      const bytes = new Uint8Array([index + 1, 2, 3])
      assert.equal(player.capture({ isAudio: true, name }, bytes), true)
      bytes[0] = 255
    })
    assert.equal(player.capturedCount, 15)
    assert.equal(player.hasRequiredPianoCues, true)
    await player.prepare()
    assert.deepEqual(decodedFirstBytes, assetNames.map((_, index) => index + 1))
    assert.equal(player.play('D'), true)
    assert.equal(player.play('A'), true)
    assert.equal(sources.length, 0)
    assert.equal(resumeCount, 1)
    finishCueResume()
    await new Promise((resolve) => setTimeout(resolve, 0))
    assert.equal(sources.length, 1)
    assert.equal(sources[0].buffer.id, 1)
    assert.equal(sources[0].started, true)
    for (let index = 0; index < 20; index += 1) player.play('D')
    assert.equal(player.activeSources.size, 16)
    assert.ok(sources.some((source) => source.stopped))
    throwOnStart = true
    const originalWarn = console.warn
    console.warn = () => {}
    try {
      assert.equal(player.play('D'), false)
    } finally {
      console.warn = originalWarn
    }
    assert.equal(player.activeSources.size, 15)
    throwOnStart = false
    player.setEnabled(false)
    assert.equal(sources[0].stopped, true)
    assert.ok(suspendCount >= 1)
    player.setEnabled(true)
    const sourceCountBeforeSuspendedResume = sources.length
    assert.equal(player.play('D'), true)
    assert.equal(resumeCount, 2)
    player.suspend()
    finishCueResume()
    await new Promise((resolve) => setTimeout(resolve, 0))
    assert.equal(sources.length, sourceCountBeforeSuspendedResume)
    assert.equal(context.state, 'suspended')
    player.dispose()
    assert.equal(closeCount, 1)
    player.dispose()
    assert.equal(closeCount, 1)
    assert.equal(player.capture({ isAudio: true, name: 'A' }, new Uint8Array([1])), false)
  } finally {
    if (originalWx === undefined) delete globalThis.wx
    else globalThis.wx = originalWx
  }
}

async function verifyVendoredPianoAudioBridge() {
  const contexts = []
  class TestAudioContext {
    constructor(options = {}) {
      this.sampleRate = options.sampleRate || 48000
      this.destination = {}
      this.state = 'suspended'
      this.resumeCount = 0
      contexts.push(this)
    }

    createScriptProcessor(...args) {
      this.processorArgs = args
      this.processorCount = (this.processorCount || 0) + 1
      return {
        onaudioprocess: null,
        connect() {},
        disconnect() {}
      }
    }

    resume() {
      this.state = 'running'
      this.resumeCount += 1
      return Promise.resolve()
    }

    suspend() {
      this.state = 'suspended'
      return Promise.resolve()
    }

    close() {
      this.state = 'closed'
      return Promise.resolve()
    }
  }
  class TestPath2D {
    addPath() {}
  }
  class TestDOMMatrix {
    constructor() {
      this.a = 1
      this.b = 0
      this.c = 0
      this.d = 1
      this.e = 0
      this.f = 0
    }
  }
  class TestImage {}
  class TestBlob {
    constructor(parts = []) {
      this.parts = parts
    }
  }

  const factory = (await import(pathToFileURL(vendoredModulePath).href)).default
  const audioWindow = {
    AudioContext: TestAudioContext,
    webkitAudioContext: TestAudioContext
  }
  const vendoredRuntime = await factory({
    wasmBinary: await fs.readFile(wasmPath),
    document: globalThis.document,
    navigator: { userAgent: 'WeChat MiniProgram' },
    performance: globalThis.performance,
    requestAnimationFrame: (callback) => setTimeout(() => callback(performance.now()), 16),
    cancelAnimationFrame: (requestId) => clearTimeout(requestId),
    Path2D: TestPath2D,
    DOMMatrix: TestDOMMatrix,
    Image: TestImage,
    Blob: TestBlob,
    URL: {
      createObjectURL: () => 'mock://embedded-asset',
      revokeObjectURL() {}
    },
    audioWindow
  })
  const pianoBytes = new Uint8Array(await fs.readFile(
    path.join(projectRoot, 'rive测试文件/Rive/27375-51723-a-piano-game.riv')
  ))
  const directCueAudio = new MiniProgramCueAudio()
  const directAssetLoader = new vendoredRuntime.CustomFileAssetLoader({
    loadContents(asset, bytes) {
      if (asset.isAudio) {
        directCueAudio.capture(asset, bytes)
        return true
      }
      return !asset.isAudio
    }
  })
  const directFile = await vendoredRuntime.load(pianoBytes, directAssetLoader, false)
  const directArtboard = directFile.artboardByName('StageAPT')
  const directMachine = new vendoredRuntime.StateMachineInstance(
    directArtboard.stateMachineByName('Piano Game'),
    directArtboard
  )
  const directViewModelInstance = directFile
    .defaultArtboardViewModel(directArtboard)
    .defaultInstance()
  directMachine.setViewModelInstance(directViewModelInstance)
  directMachine.bind()
  advanceStateMachine(directMachine, directArtboard)
  directMachine.pointerDown(300, 500, 7)
  advanceStateMachine(directMachine, directArtboard)
  assert.equal(directCueAudio.capturedCount, 15)
  assert.equal(contexts.length, 0)
  assert.equal(audioWindow.miniaudio?.devices?.length || 0, 0)
  directMachine.delete()
  directViewModelInstance.unref()
  directArtboard.delete()
  directFile.unref()
  directAssetLoader.delete?.()
  directCueAudio.dispose()

  let embeddedAudioCount = 0
  const assetLoader = new vendoredRuntime.CustomFileAssetLoader({
    loadContents(asset) {
      if (asset.isAudio) embeddedAudioCount += 1
      return !asset.isAudio
    }
  })
  const file = await vendoredRuntime.load(
    pianoBytes,
    assetLoader,
    false
  )
  const artboard = file.artboardByName('StageAPT')
  const machine = new vendoredRuntime.StateMachineInstance(
    artboard.stateMachineByName('Piano Game'),
    artboard
  )
  const viewModelInstance = file.defaultArtboardViewModel(artboard).defaultInstance()
  machine.setViewModelInstance(viewModelInstance)
  machine.bind()
  advanceStateMachine(machine, artboard)

  assert.equal(file.hasAudio, true)
  assert.equal(artboard.hasAudio, true)
  assert.equal(embeddedAudioCount, 15)
  artboard.volume = 0
  assert.equal(artboard.volume, 0)
  artboard.volume = 1
  assert.equal(artboard.volume, 1)

  machine.pointerDown(300, 500, 7)
  advanceStateMachine(machine, artboard)
  const playbackContext = contexts.find((context) => context.state !== 'closed')
  assert.ok(playbackContext)
  assert.ok(playbackContext.resumeCount > 0)
  assert.deepEqual(playbackContext.processorArgs, [2048, 0, 2])
  assert.equal(playbackContext.processorCount, 1)
  assert.equal(audioWindow.miniaudio.devices.length, 1)

  for (let index = 0; index < 32; index += 1) {
    machine.pointerUp(300, 500, 7)
    machine.pointerExit(300, 500, 7)
    advanceStateMachine(machine, artboard)
    machine.pointerDown(300, 500, 7)
    advanceStateMachine(machine, artboard)
  }
  assert.equal(embeddedAudioCount, 15)
  assert.equal(playbackContext.processorCount, 1)
  assert.equal(contexts.filter((context) => context.processorCount).length, 1)

  machine.pointerUp(300, 500, 7)
  machine.pointerExit(300, 500, 7)
  advanceStateMachine(machine, artboard)
  machine.delete()
  viewModelInstance.unref()
  artboard.delete()
  file.unref()
  assetLoader.delete?.()
}

await verifyGuideIdleFallback()
verifyEmbeddedImageExtensions()
verifyAudioCompatibilityPolicy()
await verifyLazyArtboardCatalog()
verifyPausedRenderScheduling()
await verifyAudioResumeCoalescing()
await verifyNativePianoCueAudio()
await verifyMiniProgramRuntimeFallbacks()
try {
  await fs.access(path.join(projectRoot, 'rive测试文件/Rive/27375-51723-a-piano-game.riv'))
  await verifyPianoAutoBinding()
  await verifyVendoredPianoAudioBridge()
  console.log('真机运行时回退、Guide idle、Piano 点击与 WebAudio 桥接验证通过。')
} catch (error) {
  if (error.code !== 'ENOENT') throw error
  console.log('真机运行时回退与 Guide idle 验证通过；本机未提供 Piano，已跳过点击链。')
}
