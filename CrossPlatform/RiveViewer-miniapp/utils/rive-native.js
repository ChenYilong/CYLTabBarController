let runtimePromise = null
let animationCanvas = null
let RiveFactory = null
let embeddedImageSequence = 0
let runtimeAudioWindow = null
let miniProgramAudioCapability = null
const audioResumeTasks = new WeakMap()
const audioDesiredStates = new WeakMap()
const resumedAudioContexts = new WeakSet()

const MAX_AUDIO_SOURCE_BYTES = 8 * 1024 * 1024
const IOS_AUDIO_FRAME_INTERVAL = 1000 / 30
const IOS_AUDIO_PIXEL_RATIO_LIMIT = 1.5
const IOS_COMPLEX_FRAME_INTERVAL = 1000 / 24
const IOS_COMPLEX_PIXEL_RATIO_LIMIT = 1.25
const QUALITY_PROFILES = {
  performance: { frameInterval: 1000 / 30, pixelRatio: 1 },
  balanced: { frameInterval: 1000 / 45, pixelRatio: 1.5 },
  high: { frameInterval: 0, pixelRatio: 2 }
}
const PIANO_AUDIO_ASSET_NAMES = new Set([
  'A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#',
  'switch', 'power01', 'power02'
])
const PIANO_KEY_CUES = [
  ['keyA', 'A'],
  ['keyA2', 'A#'],
  ['keyB', 'B'],
  ['keyC', 'C'],
  ['keyC2', 'C#'],
  ['keyD', 'D'],
  ['keyD2', 'D#'],
  ['keyE', 'E'],
  ['keyF', 'F'],
  ['keyF2', 'F#'],
  ['keyG', 'G'],
  ['keyG2', 'G#']
]
const PIANO_AUDIO_DECODE_ORDER = [
  ...PIANO_KEY_CUES.map(([, cue]) => cue),
  'switch',
  'power01',
  'power02'
]
const PIANO_AUDIO_DECODE_TIMEOUT = 1800
const PIANO_SIGNATURE_SCAN_BYTES = 512 * 1024
const MAX_ACTIVE_PIANO_SOURCES = 16

const RIVE_WASM_FILES = [
  { path: 'vendor/rive/rive.wasm.br', timeout: 7000 },
  { path: 'vendor/rive/rive_fallback.wasm.br', timeout: 12000 }
]

function defineRuntimeGlobal(root, key, value) {
  try {
    root[key] = value
  } catch (error) {
    Object.defineProperty(root, key, {
      value,
      configurable: true,
      writable: true
    })
  }
}

function isCompatibleWebAudioContext(context) {
  return Boolean(
    context
    && Number(context.sampleRate) > 0
    && context.destination
    && typeof context.createScriptProcessor === 'function'
    && typeof context.resume === 'function'
    && typeof context.suspend === 'function'
    && typeof context.close === 'function'
  )
}

function getAudioBlockedReason(sourceSize, platformSupported) {
  if (!platformSupported) return '当前微信版本不支持声音'
  if (Math.max(0, Number(sourceSize) || 0) > MAX_AUDIO_SOURCE_BYTES) {
    return '大文件已启用性能保护'
  }
  return ''
}

function isIOSMiniProgram() {
  if (typeof wx === 'undefined') return false
  try {
    const info = typeof wx.getDeviceInfo === 'function'
      ? wx.getDeviceInfo()
      : (typeof wx.getSystemInfoSync === 'function' ? wx.getSystemInfoSync() : {})
    return String(info?.platform || '').toLowerCase() === 'ios'
      || /iphone|ipad|ios/i.test(`${info?.system || ''} ${info?.model || ''}`)
  } catch (error) {
    return false
  }
}

function getPlaybackPerformanceProfile({
  hasAudio = false,
  isIOS = false,
  isComplexFile = false,
  pixelRatio = 1,
  qualityMode = ''
} = {}) {
  const isIOSAudio = Boolean(isIOS && hasAudio)
  const isIOSComplex = Boolean(isIOS && isComplexFile && !hasAudio)
  const qualityProfile = QUALITY_PROFILES[qualityMode] || null
  const requestedPixelRatio = qualityProfile
    ? Math.min(Math.max(1, Number(pixelRatio) || 1), qualityProfile.pixelRatio)
    : Math.max(1, Number(pixelRatio) || 1)
  const automaticFrameInterval = isIOSAudio
    ? IOS_AUDIO_FRAME_INTERVAL
    : (isIOSComplex ? IOS_COMPLEX_FRAME_INTERVAL : (isComplexFile ? 30 : 0))
  const automaticPixelRatio = isIOSAudio
    ? Math.min(requestedPixelRatio, IOS_AUDIO_PIXEL_RATIO_LIMIT)
    : (isIOSComplex
        ? Math.min(requestedPixelRatio, IOS_COMPLEX_PIXEL_RATIO_LIMIT)
        : (isComplexFile ? Math.min(requestedPixelRatio, 1.25) : requestedPixelRatio))
  return {
    frameInterval: Math.max(automaticFrameInterval, qualityProfile?.frameInterval || 0),
    pixelRatio: automaticPixelRatio
  }
}

function byteArrayIncludesASCII(source, text) {
  const bytes = source instanceof Uint8Array
    ? source
    : new Uint8Array(source || 0)
  const pattern = Array.from(String(text), (character) => character.charCodeAt(0))
  if (!pattern.length || pattern.length > bytes.length) return false
  const limit = bytes.length - pattern.length
  for (let offset = 0; offset <= limit; offset += 1) {
    if (bytes[offset] !== pattern[0]) continue
    let matched = true
    for (let index = 1; index < pattern.length; index += 1) {
      if (bytes[offset + index] !== pattern[index]) {
        matched = false
        break
      }
    }
    if (matched) return true
  }
  return false
}

function isPianoAudioCandidate(fileName, source) {
  if (/piano/i.test(String(fileName || ''))) return true
  const bytes = source instanceof Uint8Array ? source : new Uint8Array(source || 0)
  const signatureBytes = bytes.subarray(Math.max(0, bytes.length - PIANO_SIGNATURE_SCAN_BYTES))
  return byteArrayIncludesASCII(signatureBytes, 'Piano Game')
    && byteArrayIncludesASCII(signatureBytes, 'pianoKeys')
}

function isCompatibleCueAudioContext(context) {
  return Boolean(
    context
    && context.destination
    && typeof context.decodeAudioData === 'function'
    && typeof context.createBufferSource === 'function'
    && typeof context.resume === 'function'
    && typeof context.suspend === 'function'
    && typeof context.close === 'function'
  )
}

class MiniProgramCueAudio {
  constructor() {
    this.context = null
    this.rawAssets = new Map()
    this.buffers = new Map()
    this.capturedAssetNames = new Set()
    this.prepareTask = null
    this.resumeTask = null
    this.resumeGeneration = 0
    this.pendingCue = ''
    this.wantsRunning = false
    this.activeSources = new Set()
    this.enabled = true
    this.disposed = false
  }

  ensureContext() {
    if (this.context) return this.context
    if (
      this.disposed
      || typeof wx === 'undefined'
      || typeof wx.createWebAudioContext !== 'function'
    ) return null
    try {
      const context = wx.createWebAudioContext()
      if (!isCompatibleCueAudioContext(context)) {
        context?.close?.()
        return null
      }
      this.context = context
      return context
    } catch (error) {
      console.warn('iOS 钢琴音频上下文创建失败', error)
      return null
    }
  }

  capture(asset, bytes) {
    if (this.disposed) return false
    const name = String(asset?.name || '').trim()
    if (!asset?.isAudio || !PIANO_AUDIO_ASSET_NAMES.has(name) || !bytes?.length) {
      return false
    }
    const data = bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength)
    this.rawAssets.set(name, data)
    this.capturedAssetNames.add(name)
    return true
  }

  decodeAudioData(context, data, name) {
    return new Promise((resolve) => {
      let settled = false
      const timer = setTimeout(() => finish(null), PIANO_AUDIO_DECODE_TIMEOUT)
      const finish = (buffer) => {
        if (settled) return
        settled = true
        clearTimeout(timer)
        resolve(buffer || null)
      }
      try {
        const request = context.decodeAudioData(
          data,
          (buffer) => finish(buffer),
          () => finish(null)
        )
        request?.then?.((buffer) => finish(buffer), () => finish(null))
      } catch (error) {
        console.warn(`iOS 钢琴音频 ${name} 解码失败`, error)
        finish(null)
      }
    })
  }

  prepare() {
    if (this.prepareTask) return this.prepareTask
    this.prepareTask = (async () => {
      const context = this.ensureContext()
      if (!context) throw new Error('当前微信版本不支持低延迟钢琴声音')
      for (const name of PIANO_AUDIO_DECODE_ORDER) {
        if (this.disposed) return false
        const data = this.rawAssets.get(name)
        if (!data) continue
        const buffer = await this.decodeAudioData(context, data, name)
        if (buffer && !this.disposed) this.buffers.set(name, buffer)
      }
      this.rawAssets.clear()
      return PIANO_KEY_CUES.every(([, cue]) => this.buffers.has(cue))
    })()
    return this.prepareTask
  }

  get capturedCount() {
    return this.capturedAssetNames.size
  }

  get hasRequiredPianoCues() {
    return PIANO_KEY_CUES.every(([, cue]) => this.capturedAssetNames.has(cue))
  }

  whenReady() {
    return this.prepareTask || Promise.resolve(false)
  }

  resumeContext() {
    const context = this.context
    if (!this.enabled || !context || this.disposed) return Promise.resolve(false)
    this.wantsRunning = true
    if (!context.state || context.state === 'running') {
      const cue = this.pendingCue
      this.pendingCue = ''
      if (cue) this.startCue(cue)
      return Promise.resolve(true)
    }
    if (this.resumeTask) return this.resumeTask
    const generation = this.resumeGeneration
    let request = null
    try {
      request = context.resume()
    } catch (error) {
      console.warn('iOS 钢琴音频恢复失败', error)
      return Promise.resolve(false)
    }
    const task = Promise.resolve(request)
      .then(() => {
        const isCurrent = (
          generation === this.resumeGeneration
          && this.context === context
          && this.enabled
          && this.wantsRunning
          && !this.disposed
        )
        if (!isCurrent) {
          if ((!this.enabled || !this.wantsRunning || this.disposed) && this.context === context) {
            const suspendRequest = context.suspend?.()
            suspendRequest?.catch?.(() => {})
          }
          return false
        }
        const cue = this.pendingCue
        this.pendingCue = ''
        if (cue) this.startCue(cue)
        return !context.state || context.state === 'running'
      })
      .catch((error) => {
        if (generation === this.resumeGeneration && this.context === context) {
          this.pendingCue = ''
        }
        console.warn('iOS 钢琴音频恢复失败', error)
        return false
      })
      .finally(() => {
        if (this.resumeTask === task) this.resumeTask = null
      })
    this.resumeTask = task
    return task
  }

  resume() {
    if (!this.enabled || !this.context || this.disposed) return false
    this.resumeContext()
    return true
  }

  releaseSource(source, shouldStop = false) {
    if (!source) return
    this.activeSources.delete(source)
    source.onended = null
    if (shouldStop) {
      try {
        source.stop?.(0)
      } catch (error) {}
    }
    try {
      source.disconnect?.()
    } catch (error) {}
  }

  stopActiveSources() {
    Array.from(this.activeSources).forEach((source) => this.releaseSource(source, true))
    this.activeSources.clear()
  }

  suspend() {
    this.wantsRunning = false
    this.resumeGeneration += 1
    this.pendingCue = ''
    this.resumeTask = null
    this.stopActiveSources()
    if (!this.context) return false
    return suspendAudioDevices([{ I: this.context }])
  }

  setEnabled(enabled) {
    this.enabled = Boolean(enabled)
    if (!this.enabled) this.suspend()
  }

  startCue(name) {
    if (!this.enabled || this.disposed || !this.context) return false
    const buffer = this.buffers.get(name)
    if (!buffer) return false
    if (this.context.state && this.context.state !== 'running') return false
    let source = null
    try {
      while (this.activeSources.size >= MAX_ACTIVE_PIANO_SOURCES) {
        const oldestSource = this.activeSources.values().next().value
        this.releaseSource(oldestSource, true)
      }
      source = this.context.createBufferSource()
      source.buffer = buffer
      source.connect(this.context.destination)
      source.onended = () => this.releaseSource(source)
      this.activeSources.add(source)
      source.start(0)
      return true
    } catch (error) {
      this.releaseSource(source, true)
      console.warn(`iOS 钢琴音频 ${name} 播放失败`, error)
      return false
    }
  }

  play(name) {
    if (!this.enabled || this.disposed || !this.context) return false
    if (!this.buffers.has(name)) return false
    this.wantsRunning = true
    if (this.context.state && this.context.state !== 'running') {
      this.pendingCue = name
      this.resumeContext()
      return true
    }
    return this.startCue(name)
  }

  dispose() {
    if (this.disposed) return
    this.disposed = true
    this.wantsRunning = false
    this.resumeGeneration += 1
    this.pendingCue = ''
    this.resumeTask = null
    this.stopActiveSources()
    const context = this.context
    this.context = null
    this.rawAssets.clear()
    this.buffers.clear()
    this.capturedAssetNames.clear()
    try {
      const request = context?.close?.()
      request?.catch?.(() => {})
    } catch (error) {}
  }
}

function getViewModelBoolean(instance, path) {
  try {
    return instance?.boolean?.(path) || null
  } catch (error) {
    return null
  }
}

function createPianoCueBindings(viewModelInstance) {
  const bindings = []
  const owners = []
  Object.defineProperty(bindings, 'owners', { value: owners })
  try {
    const pianoKeys = viewModelInstance?.viewModel?.('pianoKeys')
    if (pianoKeys) owners.push(pianoKeys)
    PIANO_KEY_CUES.forEach(([path, cue]) => {
      const input = getViewModelBoolean(pianoKeys, path)
      if (input) bindings.push({ input, lastValue: Boolean(input.value), cue, mode: 'rising' })
    })
    const speedSwitch = viewModelInstance?.viewModel?.('speedSwitch')
    if (speedSwitch) owners.push(speedSwitch)
    const speedInput = getViewModelBoolean(speedSwitch, 'speedswitchOn')
    if (speedInput) {
      bindings.push({ input: speedInput, lastValue: Boolean(speedInput.value), cue: 'switch', mode: 'change' })
    }
    const tipsSwitch = viewModelInstance?.viewModel?.('tipsSwitch')
    if (tipsSwitch) owners.push(tipsSwitch)
    const tipsInput = getViewModelBoolean(tipsSwitch, 'tipsswitchOn')
    if (tipsInput) {
      bindings.push({ input: tipsInput, lastValue: Boolean(tipsInput.value), cue: 'switch', mode: 'change' })
    }
    const power = viewModelInstance?.viewModel?.('power')
    if (power) owners.push(power)
    const powerInput = getViewModelBoolean(power, 'isOpen')
    if (powerInput) {
      bindings.push({
        input: powerInput,
        lastValue: Boolean(powerInput.value),
        cue: 'power01',
        alternateCue: 'power02',
        mode: 'change'
      })
    }
  } catch (error) {
    owners.forEach((owner) => owner?.unref?.())
    owners.length = 0
    bindings.length = 0
  }
  return bindings
}

function collectPianoCueChanges(bindings = []) {
  const cues = []
  bindings.forEach((binding) => {
    const nextValue = Boolean(binding.input?.value)
    const changed = nextValue !== binding.lastValue
    if (changed && (binding.mode === 'change' || nextValue)) {
      cues.push(nextValue ? binding.cue : (binding.alternateCue || binding.cue))
    }
    binding.lastValue = nextValue
  })
  return cues
}

function supportsMiniProgramWebAudio() {
  if (miniProgramAudioCapability === true) return true
  if (typeof wx === 'undefined' || typeof wx.createWebAudioContext !== 'function') {
    return false
  }
  let context = null
  let supported = false
  try {
    context = wx.createWebAudioContext()
    supported = isCompatibleWebAudioContext(context)
    if (supported) miniProgramAudioCapability = true
  } catch (error) {
    console.warn('微信 WebAudio 能力检测失败', error)
  } finally {
    try {
      const request = context?.close?.()
      request?.catch?.(() => {})
    } catch (error) {}
  }
  return supported
}

function MiniProgramAudioContext() {
  const context = wx.createWebAudioContext()
  if (!context) throw new Error('无法创建微信 WebAudio 上下文')
  return context
}

function installAudioShims(root, probeAudio = true) {
  runtimeAudioWindow ||= {}
  const supported = probeAudio && supportsMiniProgramWebAudio()
  if (supported) {
    runtimeAudioWindow.AudioContext = MiniProgramAudioContext
    runtimeAudioWindow.webkitAudioContext = MiniProgramAudioContext
  }
  if (typeof root.document?.addEventListener !== 'function') {
    defineRuntimeGlobal(root.document, 'addEventListener', () => {})
  }
  if (typeof root.document?.removeEventListener !== 'function') {
    defineRuntimeGlobal(root.document, 'removeEventListener', () => {})
  }
  return supported
}

function resumeAudioDevices(devices = []) {
  let resumed = false
  devices.forEach((device) => {
    const context = device?.I
    if (!context?.resume) return
    resumed = true
    audioDesiredStates.set(context, 'running')
    if (context.state === 'running') return
    if (context.state === 'suspended') resumedAudioContexts.delete(context)
    if (!context.state && resumedAudioContexts.has(context)) return
    if (audioResumeTasks.has(context)) return
    try {
      const request = context.resume()
      if (!request?.then) {
        resumedAudioContexts.add(context)
        return
      }
      const task = Promise.resolve(request)
        .then(() => {
          if (audioDesiredStates.get(context) === 'running') {
            resumedAudioContexts.add(context)
            return
          }
          resumedAudioContexts.delete(context)
          return context.suspend?.()
        })
        .catch((error) => console.warn('Rive 音频恢复失败', error))
        .finally(() => {
          if (audioResumeTasks.get(context) === task) audioResumeTasks.delete(context)
        })
      audioResumeTasks.set(context, task)
    } catch (error) {
      console.warn('Rive 音频恢复失败', error)
    }
  })
  return resumed
}

function suspendAudioDevices(devices = []) {
  let suspended = false
  devices.forEach((device) => {
    const context = device?.I
    if (!context?.suspend) return
    suspended = true
    audioDesiredStates.set(context, 'suspended')
    resumedAudioContexts.delete(context)
    if (context.state === 'suspended') return
    try {
      const request = context.suspend()
      request?.catch?.((error) => console.warn('Rive 音频暂停失败', error))
    } catch (error) {
      console.warn('Rive 音频暂停失败', error)
    }
  })
  return suspended
}

function resumeRuntimeAudio() {
  return resumeAudioDevices(runtimeAudioWindow?.miniaudio?.devices || [])
}

function suspendRuntimeAudio() {
  return suspendAudioDevices(runtimeAudioWindow?.miniaudio?.devices || [])
}

function shouldBypassEmbeddedAudio(asset, audioSupported) {
  return Boolean(asset?.isAudio && !audioSupported)
}

function installImageShims(root) {
  if (typeof root.Image === 'undefined') {
    defineRuntimeGlobal(root, 'Image', function MiniProgramImage() {
      if (!animationCanvas?.createImage) {
        throw new Error('当前 Canvas 不支持嵌入图片资源')
      }
      return animationCanvas.createImage()
    })
  }

  const needsObjectUrlShim = (
    typeof root.Blob === 'undefined'
    || typeof root.URL?.createObjectURL !== 'function'
    || typeof root.URL?.revokeObjectURL !== 'function'
  )
  if (needsObjectUrlShim) {
    defineRuntimeGlobal(root, 'Blob', class MiniProgramBlob {
      constructor(parts = [], options = {}) {
        this.parts = parts
        this.type = options.type || 'application/octet-stream'
      }
    })
  }

  const urlApi = root.URL || {}
  if (needsObjectUrlShim) {
    const createObjectURL = (blob) => {
      const part = blob?.parts?.[0]
      if (!part) throw new Error('嵌入图片数据为空')
      const bytes = part instanceof Uint8Array
        ? part
        : new Uint8Array(part)
      const data = bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength)
      const extension = detectEmbeddedImageExtension(bytes)
      const filePath = `${wx.env.USER_DATA_PATH}/rive-embedded-${Date.now()}-${embeddedImageSequence += 1}.${extension}`
      wx.getFileSystemManager().writeFileSync(filePath, data)
      return filePath
    }
    const revokeObjectURL = (filePath) => {
      if (!String(filePath || '').startsWith(wx.env.USER_DATA_PATH)) return
      try {
        wx.getFileSystemManager().unlinkSync(filePath)
      } catch (error) {}
    }
    try {
      urlApi.createObjectURL = createObjectURL
      urlApi.revokeObjectURL = revokeObjectURL
    } catch (error) {
      Object.defineProperties(urlApi, {
        createObjectURL: { value: createObjectURL, configurable: true },
        revokeObjectURL: { value: revokeObjectURL, configurable: true }
      })
    }
  }
  if (!root.URL) defineRuntimeGlobal(root, 'URL', urlApi)
}

function detectEmbeddedImageExtension(bytes) {
  if (
    bytes.length >= 12
    && bytes[0] === 0x52
    && bytes[1] === 0x49
    && bytes[2] === 0x46
    && bytes[3] === 0x46
    && bytes[8] === 0x57
    && bytes[9] === 0x45
    && bytes[10] === 0x42
    && bytes[11] === 0x50
  ) return 'webp'
  if (
    bytes.length >= 8
    && bytes[0] === 0x89
    && bytes[1] === 0x50
    && bytes[2] === 0x4e
    && bytes[3] === 0x47
  ) return 'png'
  if (bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) {
    return 'jpg'
  }
  if (
    bytes.length >= 6
    && bytes[0] === 0x47
    && bytes[1] === 0x49
    && bytes[2] === 0x46
  ) return 'gif'
  return 'png'
}

class MiniProgramDOMMatrix {
  constructor(values) {
    this.a = 1
    this.b = 0
    this.c = 0
    this.d = 1
    this.e = 0
    this.f = 0
    if (Array.isArray(values) && values.length >= 6) {
      const [a, b, c, d, e, f] = values
      this.a = a
      this.b = b
      this.c = c
      this.d = d
      this.e = e
      this.f = f
    }
  }
}

function requestRuntimeFrame(callback) {
  if (animationCanvas?.requestAnimationFrame) {
    return animationCanvas.requestAnimationFrame(callback)
  }
  return setTimeout(() => callback(Date.now()), 16)
}

function cancelRuntimeFrame(requestId) {
  if (animationCanvas?.cancelAnimationFrame) {
    animationCanvas.cancelAnimationFrame(requestId)
    return
  }
  clearTimeout(requestId)
}

function installRuntimeShims(canvas, { probeAudio = true } = {}) {
  if (canvas) animationCanvas = canvas
  const root = typeof globalThis !== 'undefined' ? globalThis : global

  if (typeof root.document === 'undefined') {
    root.document = {
      currentScript: null,
      createElement() {
        return {
          style: {},
          getContext() {
            return null
          }
        }
      }
    }
  }

  if (typeof root.navigator === 'undefined') {
    try {
      root.navigator = { userAgent: 'WeChat MiniProgram' }
    } catch (error) {
      Object.defineProperty(root, 'navigator', {
        value: { userAgent: 'WeChat MiniProgram' },
        configurable: true
      })
    }
  }

  if (typeof root.performance === 'undefined' || typeof root.performance.now !== 'function') {
    const startedAt = Date.now()
    const performanceShim = {
      now() {
        return Date.now() - startedAt
      },
      mark() {},
      measure() {},
      clearMarks() {},
      clearMeasures() {}
    }

    try {
      root.performance = performanceShim
    } catch (error) {
      Object.defineProperty(root, 'performance', {
        value: performanceShim,
        configurable: true
      })
    }
  }

  installImageShims(root)
  installAudioShims(root, probeAudio)

  if (typeof root.DOMMatrix === 'undefined') {
    defineRuntimeGlobal(root, 'DOMMatrix', MiniProgramDOMMatrix)
  }

  root.requestAnimationFrame = requestRuntimeFrame
  root.cancelAnimationFrame = cancelRuntimeFrame

  if (typeof root.WebAssembly === 'undefined') {
    root.WebAssembly = {
      RuntimeError: Error,
      CompileError: Error
    }
  }
}

function instantiateRiveWasm(imports, receiveInstance, reject) {
  let activeAttempt = 0
  let settled = false
  let firstError = null

  const attempt = (index) => {
    const candidate = RIVE_WASM_FILES[index]
    const attemptId = activeAttempt + 1
    activeAttempt = attemptId
    const timer = setTimeout(() => {
      if (settled || activeAttempt !== attemptId) return
      if (index + 1 < RIVE_WASM_FILES.length) {
        firstError ||= new Error(`${candidate.path} 初始化超时`)
        attempt(index + 1)
        return
      }
      settled = true
      reject(new Error('Rive WASM 初始化超时，请更新微信后重试'))
    }, candidate.timeout)

    WXWebAssembly.instantiate(candidate.path, imports)
      .then((result) => {
        if (settled || activeAttempt !== attemptId) return
        settled = true
        clearTimeout(timer)
        receiveInstance(result.instance || result)
      })
      .catch((error) => {
        if (settled || activeAttempt !== attemptId) return
        clearTimeout(timer)
        firstError ||= error
        if (index + 1 < RIVE_WASM_FILES.length) {
          attempt(index + 1)
          return
        }
        settled = true
        const reason = error?.message || firstError?.message || '未知错误'
        reject(new Error(`Rive WASM 初始化失败：${reason}`))
      })
  }

  attempt(0)
  return {}
}

function initializeRuntime() {
  if (runtimePromise) return runtimePromise
  RiveFactory = RiveFactory || require('../vendor/rive/canvas_advanced')
  const root = typeof globalThis !== 'undefined' ? globalThis : global

  const pendingRuntime = new Promise((resolve, reject) => {
    if (typeof WXWebAssembly === 'undefined') {
      reject(new Error('当前基础库不支持 WXWebAssembly'))
      return
    }

    RiveFactory({
      document: root.document,
      navigator: root.navigator,
      performance: root.performance,
      requestAnimationFrame: root.requestAnimationFrame,
      cancelAnimationFrame: root.cancelAnimationFrame,
      Path2D: function MiniProgramPath2D() {
        if (!animationCanvas?.createPath2D) {
          throw new Error('当前 Canvas 不支持 Path2D')
        }
        return animationCanvas.createPath2D()
      },
      DOMMatrix: root.DOMMatrix,
      Image: root.Image,
      Blob: root.Blob,
      URL: root.URL,
      audioWindow: runtimeAudioWindow,
      instantiateWasm(imports, receiveInstance) {
        return instantiateRiveWasm(imports, receiveInstance, reject)
      }
    }).then(resolve, reject)
  })
  runtimePromise = pendingRuntime

  pendingRuntime.catch(() => {
    if (runtimePromise === pendingRuntime) runtimePromise = null
  })

  return pendingRuntime
}

function prewarmRuntime() {
  installRuntimeShims(null, { probeAudio: false })
  return initializeRuntime()
}

function getRuntime(canvas, { probeAudio = true } = {}) {
  installRuntimeShims(canvas, { probeAudio })
  return initializeRuntime()
}

function fitLabel(key) {
  const labels = {
    contain: '完整显示',
    cover: '铺满画布',
    fill: '拉伸填充',
    fitWidth: '适应宽度',
    fitHeight: '适应高度'
  }
  return labels[key] || key
}

function alignmentLabel(key) {
  const labels = {
    topCenter: '顶部',
    center: '居中',
    bottomCenter: '底部'
  }
  return labels[key] || key
}

function getAnimationDuration(definition) {
  const duration = Number(definition?.duration) || 0
  const fps = Number(definition?.fps) || 0
  const workStart = Number(definition?.workStart)
  const workEnd = Number(definition?.workEnd)
  if (
    definition?.enableWorkArea
    && fps > 0
    && Number.isFinite(workStart)
    && Number.isFinite(workEnd)
    && workEnd > workStart
  ) {
    return (workEnd - workStart) / fps
  }
  return fps > 0 ? duration / fps : duration
}

class NativeRivePlayer {
  constructor(options) {
    this.canvas = options.canvas
    this.fileName = options.fileName || ''
    this.width = options.width
    this.height = options.height
    this.pixelRatio = options.pixelRatio || 1
    this.requestedPixelRatio = this.pixelRatio
    this.qualityMode = QUALITY_PROFILES[options.qualityMode] ? options.qualityMode : ''
    this.onMetadata = options.onMetadata || (() => {})
    this.onStateChange = options.onStateChange || (() => {})
    this.onPlaybackChange = options.onPlaybackChange || (() => {})
    this.onTimelineProgress = options.onTimelineProgress || (() => {})
    this.onFirstFrame = options.onFirstFrame || (() => {})
    this.onPerformance = options.onPerformance || (() => {})
    this.onError = options.onError || (() => {})
    this.fitKey = 'cover'
    this.alignmentKey = 'center'
    this.speed = 1
    this.playing = true
    this.lastTime = 0
    this.frameRequest = 0
    this.disposed = false
    this.viewMatrix = null
    this.inputRefs = []
    this.boundViewModelInstances = []
    this.metadata = null
    this.selectedStateMachineName = ''
    this.sequenceNames = []
    this.sequenceIndex = -1
    this.sequenceElapsed = 0
    this.sequenceMode = false
    this.sequenceFinished = false
    this.sequenceHasOut = false
    this.lastProgressEmitAt = 0
    this.animationElapsed = 0
    this.frameInterval = 0
    this.lastRenderAt = 0
    this.performanceStartedAt = 0
    this.performanceFrames = 0
    this.needsRedraw = true
    this.artboardCatalogPromise = null
    this.artboardCatalogProgressCallbacks = new Set()
    this.totalArtboardCount = 0
    this.isIOS = options.isIOS === undefined
      ? isIOSMiniProgram()
      : Boolean(options.isIOS)
    this.audioEnabled = options.audioEnabled !== false
    this.sourceSize = Math.max(0, Number(options.sourceSize) || 0)
    this.audioPlatformSupported = null
    this.audioBlockedReason = getAudioBlockedReason(
      this.sourceSize,
      true
    )
    this.audioSupported = !this.audioBlockedReason
    this.hasAudio = false
    this.nativePianoAudio = null
    this.usesNativePianoAudio = false
    this.nativePianoAudioPreparationStarted = false
    this.nativePianoAudioPrepareTimer = 0
    this.pianoCueBindings = []
    this.pianoCueOwners = []
  }

  activateCanvas() {
    animationCanvas = this.canvas
  }

  requestFrame(callback) {
    this.activateCanvas()
    return this.runtime.requestAnimationFrame(callback)
  }

  cancelFrame(requestId) {
    if (!requestId || !this.runtime?.cancelAnimationFrame) return
    this.runtime.cancelAnimationFrame(requestId)
  }

  scheduleRender() {
    if (this.disposed || !this.runtime || !this.renderer || this.frameRequest) return false
    this.frameRequest = this.requestFrame((time) => this.render(time))
    return true
  }

  requestRedraw() {
    this.needsRedraw = true
    return this.scheduleRender()
  }

  async load(arrayBuffer) {
    try {
      const canTryNativePianoAudio = Boolean(
        this.isIOS
        && !this.audioBlockedReason
        && typeof wx !== 'undefined'
        && typeof wx.createWebAudioContext === 'function'
        && isPianoAudioCandidate(this.fileName, arrayBuffer)
      )
      if (canTryNativePianoAudio) {
        this.nativePianoAudio = new MiniProgramCueAudio()
      }
      this.runtime = await getRuntime(this.canvas, {
        probeAudio: !canTryNativePianoAudio
      })
      if (this.disposed) return false
      this.activateCanvas()
      this.canvas.width = Math.max(1, Math.round(this.width * this.pixelRatio))
      this.canvas.height = Math.max(1, Math.round(this.height * this.pixelRatio))
      this.renderer = this.runtime.makeRenderer(this.canvas)
      this.audioPlatformSupported = canTryNativePianoAudio
        ? true
        : supportsMiniProgramWebAudio()
      this.audioBlockedReason = getAudioBlockedReason(this.sourceSize, this.audioPlatformSupported)
      this.audioSupported = !this.audioBlockedReason
      const audioSupported = this.audioSupported
      const nativePianoAudio = this.nativePianoAudio
      const assetLoader = new this.runtime.CustomFileAssetLoader({
        loadContents(asset, bytes) {
          if (nativePianoAudio && asset?.isAudio) {
            nativePianoAudio.capture(asset, bytes)
            return true
          }
          return shouldBypassEmbeddedAudio(asset, audioSupported)
        }
      })
      let file = null
      try {
        file = await this.runtime.load(new Uint8Array(arrayBuffer), assetLoader, false)
      } finally {
        assetLoader.delete?.()
      }
      if (this.disposed) {
        file?.unref?.()
        this.renderer?.delete?.()
        this.renderer = null
        return false
      }
      this.file = file
      this.hasAudio = Boolean(file.hasAudio)
      this.usesNativePianoAudio = Boolean(nativePianoAudio)
      this.totalArtboardCount = this.file.artboardCount()
      const initialArtboard = this.file.artboardByIndex(0)
      if (!initialArtboard) throw new Error('Rive 文件不包含可预览的画板')
      const initialMetadata = this.inspectArtboard(initialArtboard)
      this.metadata = {
        artboards: [initialMetadata],
        artboardCount: this.totalArtboardCount,
        artboardCatalogLoaded: this.totalArtboardCount <= 1
      }
      this.configurePerformanceProfile()
      this.activateArtboard(initialMetadata.name, '', initialArtboard)
      if (nativePianoAudio && !nativePianoAudio.hasRequiredPianoCues) {
        this.disableNativePianoAudio('钢琴音效资源不完整', { notify: false })
      }
      if (!this.activeStateMachineHasListeners()) this.playDefaultSequence()
      this.onMetadata(this.getPublicMetadata())
      this.requestRedraw()
      return true
    } catch (error) {
      if (this.disposed) return false
      this.renderer?.delete?.()
      this.renderer = null
      this.onError(error)
      throw error
    }
  }

  inspectArtboard(artboard) {
    const animations = []
    const stateMachines = []
    for (let index = 0; index < artboard.animationCount(); index += 1) {
      animations.push(artboard.animationByIndex(index).name)
    }
    for (let index = 0; index < artboard.stateMachineCount(); index += 1) {
      stateMachines.push({
        name: artboard.stateMachineByIndex(index).name,
        inputs: []
      })
    }
    const bounds = artboard.bounds
    return {
      name: artboard.name,
      width: Math.round(bounds.maxX - bounds.minX),
      height: Math.round(bounds.maxY - bounds.minY),
      animations,
      stateMachines,
      loaded: true
    }
  }

  createArtboardCatalogEntry(name) {
    return {
      name,
      width: 0,
      height: 0,
      animations: [],
      stateMachines: [],
      loaded: false
    }
  }

  upsertArtboardMetadata(metadata) {
    const index = this.metadata.artboards.findIndex((item) => item.name === metadata.name)
    if (index >= 0) this.metadata.artboards.splice(index, 1, metadata)
    else this.metadata.artboards.push(metadata)
    return metadata
  }

  emitArtboardCatalogProgress(current, total) {
    const payload = {
      current,
      total,
      progress: total > 0 ? Math.round((current / total) * 100) : 100
    }
    this.artboardCatalogProgressCallbacks.forEach((callback) => {
      try {
        callback(payload)
      } catch (error) {
        console.warn('Rive 画板目录进度回调失败', error)
      }
    })
  }

  loadArtboardCatalog(onProgress) {
    const options = typeof onProgress === 'function'
      ? { onProgress }
      : (onProgress || {})
    if (typeof options.onProgress === 'function') {
      this.artboardCatalogProgressCallbacks.add(options.onProgress)
    }
    if (this.metadata?.artboardCatalogLoaded) {
      this.emitArtboardCatalogProgress(this.totalArtboardCount, this.totalArtboardCount)
      if (typeof options.onProgress === 'function') {
        this.artboardCatalogProgressCallbacks.delete(options.onProgress)
      }
      return Promise.resolve(this.getPublicMetadata())
    }
    if (this.artboardCatalogPromise) return this.artboardCatalogPromise

    const batchSize = Math.max(1, Number(options.batchSize) || (this.isIOS ? 2 : 6))
    const yieldDelay = this.isIOS ? 16 : 0
    const task = (async () => {
      const catalog = [this.metadata.artboards[0]]
      let current = Math.min(1, this.totalArtboardCount)
      this.emitArtboardCatalogProgress(current, this.totalArtboardCount)
      for (let index = 1; index < this.totalArtboardCount; index += 1) {
        if (this.disposed || !this.file) throw new Error('Rive 预览已关闭')
        const artboard = this.file.artboardByIndex(index)
        if (artboard) {
          try {
            const existing = this.metadata.artboards.find((item) => item.name === artboard.name)
            catalog.push(existing || this.createArtboardCatalogEntry(artboard.name))
          } finally {
            artboard.delete()
          }
        }
        current = index + 1
        if (current % batchSize === 0 || current === this.totalArtboardCount) {
          this.emitArtboardCatalogProgress(current, this.totalArtboardCount)
          if (current < this.totalArtboardCount) {
            await new Promise((resolve) => setTimeout(resolve, yieldDelay))
          }
        }
      }
      const latestByName = new Map(this.metadata.artboards.map((item) => [item.name, item]))
      this.metadata.artboards = catalog.map((item) => latestByName.get(item.name) || item)
      this.metadata.artboardCatalogLoaded = true
      const publicMetadata = this.getPublicMetadata()
      this.onMetadata(publicMetadata)
      return publicMetadata
    })()
    this.artboardCatalogPromise = task
    const clearCatalogTask = () => {
      if (this.artboardCatalogPromise === task) this.artboardCatalogPromise = null
      this.artboardCatalogProgressCallbacks.clear()
    }
    task.then(clearCatalogTask, clearCatalogTask)
    return task
  }

  configurePerformanceProfile() {
    const artboards = (this.metadata?.artboards || []).filter((item) => item.loaded !== false)
    const animationCount = artboards.reduce((sum, item) => sum + item.animations.length, 0)
    const stateMachineCount = artboards.reduce((sum, item) => sum + item.stateMachines.length, 0)
    const isComplexFile = this.sourceSize >= 2 * 1024 * 1024
      || (this.metadata?.artboardCount || artboards.length) >= 32
      || animationCount >= 120
      || stateMachineCount >= 64
    this.isComplexFile = isComplexFile
    const profile = getPlaybackPerformanceProfile({
      hasAudio: this.hasAudio && this.audioSupported,
      isIOS: this.isIOS,
      isComplexFile,
      pixelRatio: this.requestedPixelRatio,
      qualityMode: this.qualityMode
    })
    this.frameInterval = profile.frameInterval
    this.performanceStartedAt = 0
    this.performanceFrames = 0
    this.lastRenderAt = 0
    if (profile.pixelRatio === this.pixelRatio) return
    this.pixelRatio = profile.pixelRatio
    this.activateCanvas()
    this.canvas.width = Math.max(1, Math.round(this.width * this.pixelRatio))
    this.canvas.height = Math.max(1, Math.round(this.height * this.pixelRatio))
  }

  describeInput(input, index) {
    let type = 'number'
    if (input.type === this.runtime.SMIInput.bool) type = 'boolean'
    if (input.type === this.runtime.SMIInput.trigger) type = 'trigger'
    return {
      index,
      name: input.name,
      type,
      value: type === 'trigger' ? null : input.value
    }
  }

  castInput(input) {
    if (input.type === this.runtime.SMIInput.bool) return input.asBool()
    if (input.type === this.runtime.SMIInput.trigger) return input.asTrigger()
    return input.asNumber()
  }

  activateArtboard(name, machineName, preparedArtboard = null) {
    this.clearSequence()
    this.disposeActiveInstances()
    this.artboard = preparedArtboard || this.file.artboardByName(name)
    if (!this.artboard) throw new Error(`未找到 Rive 画板：${name}`)
    this.activeArtboardName = this.artboard.name
    this.applyAudioPreference()
    let artboardMeta = this.metadata.artboards.find((item) => item.name === this.activeArtboardName)
    if (!artboardMeta || artboardMeta.loaded === false) {
      artboardMeta = this.upsertArtboardMetadata(this.inspectArtboard(this.artboard))
    }
    const selectedMachine = machineName || artboardMeta.stateMachines[0]?.name || ''
    this.selectedStateMachineName = selectedMachine
    this.activeStateMachineName = selectedMachine

    if (selectedMachine) {
      const definition = this.artboard.stateMachineByName(selectedMachine)
      this.stateMachine = new this.runtime.StateMachineInstance(definition, this.artboard)
      this.inputRefs = Array.from({ length: this.stateMachine.inputCount() }, (_, index) => (
        this.castInput(this.stateMachine.input(index))
      ))
    } else if (artboardMeta.animations.length) {
      const definition = this.artboard.animationByName(artboardMeta.animations[0])
      this.animation = new this.runtime.LinearAnimationInstance(definition, this.artboard)
      this.animationDuration = getAnimationDuration(definition)
      this.animationElapsed = 0
      this.activeAnimationName = artboardMeta.animations[0]
    }

    this.bindDefaultViewModels()
    this.lastTime = 0
    this.playing = true
    this.needsRedraw = true
    this.updateViewMatrix()
    if (this.stateMachine) this.advanceStateMachine(0)
    this.onTimelineProgress({
      animation: '',
      progress: 0,
      time: 0,
      duration: 0,
      isPlaying: true
    })
    this.scheduleRender()
  }

  selectArtboard(name) {
    this.activateArtboard(name)
    if (!this.activeStateMachineHasListeners()) this.playDefaultSequence()
    this.resumeAudioPlayback()
    this.onMetadata(this.getPublicMetadata())
  }

  selectStateMachine(name) {
    this.activateArtboard(this.activeArtboardName, name)
    this.resumeAudioPlayback()
    this.onMetadata(this.getPublicMetadata())
  }

  selectAnimation(name) {
    this.clearSequence()
    this.disposeActiveInstances()
    this.artboard = this.file.artboardByName(this.activeArtboardName)
    this.applyAudioPreference()
    const definition = this.artboard.animationByName(name)
    this.animation = new this.runtime.LinearAnimationInstance(definition, this.artboard)
    this.animationDuration = getAnimationDuration(definition)
    this.animationElapsed = 0
    this.activeAnimationName = name
    this.activeStateMachineName = ''
    this.bindDefaultViewModels()
    this.lastTime = 0
    this.playing = true
    this.updateViewMatrix()
    this.onPlaybackChange({
      isPlaying: true,
      activeState: `播放 ${name}`,
      animation: name
    })
    this.resumeAudioPlayback()
    this.emitTimelineProgress(true)
    this.onMetadata(this.getPublicMetadata())
    this.requestRedraw()
  }

  clearSequence() {
    this.sequenceNames = []
    this.sequenceIndex = -1
    this.sequenceElapsed = 0
    this.sequenceMode = false
    this.sequenceFinished = false
    this.sequenceHasOut = false
  }

  getDefaultSequence(animationNames) {
    const findName = (target) => animationNames.find((name) => name.trim().toLowerCase() === target)
    const intro = findName('in')
    const idle = findName('idle')
    const outro = findName('out')
    return [intro, idle, outro].filter(Boolean)
  }

  playDefaultSequence() {
    const artboardMeta = this.metadata?.artboards.find((item) => item.name === this.activeArtboardName)
    const sequenceNames = this.getDefaultSequence(artboardMeta?.animations || [])
    if (!sequenceNames.length) return false
    this.sequenceNames = sequenceNames
    this.sequenceIndex = 0
    this.sequenceElapsed = 0
    this.sequenceMode = true
    this.sequenceFinished = false
    this.sequenceHasOut = sequenceNames.some((name) => name.trim().toLowerCase() === 'out')
    this.activateSequenceStep(0)
    return true
  }

  activeStateMachineHasListeners() {
    if (!this.stateMachine || typeof this.runtime?.hasListeners !== 'function') return false
    try {
      return Boolean(this.runtime.hasListeners(this.stateMachine))
    } catch {
      return false
    }
  }

  bindDefaultViewModels() {
    const target = this.stateMachine || this.artboard
    if (!target?.bind) return
    const viewModelInstances = []
    try {
      const viewModel = this.file.defaultArtboardViewModel?.(this.artboard)
      const viewModelInstance = viewModel?.defaultInstance?.()
      if (viewModelInstance) {
        viewModelInstances.push(viewModelInstance)
      }
      if (viewModelInstance && target.setViewModelInstance) {
        target.setViewModelInstance(viewModelInstance)
      }

      const globalNames = this.file.globalViewModelNames?.() || []
      globalNames.forEach((name) => {
        const globalInstance = this.file.viewModelByName?.(name)?.defaultInstance?.()
        if (!globalInstance) return
        viewModelInstances.push(globalInstance)
        target.setGlobalViewModelInstance?.(name, globalInstance)
      })
      target.bind()
      const pianoCueBindings = this.usesNativePianoAudio
        ? createPianoCueBindings(viewModelInstance)
        : []
      this.pianoCueBindings = pianoCueBindings
      this.pianoCueOwners = pianoCueBindings.owners || []
      this.boundViewModelInstances = viewModelInstances
    } catch (error) {
      viewModelInstances.forEach((instance) => instance?.unref?.())
      console.warn('Rive View Model 自动绑定失败', error)
    }
  }

  activateSequenceStep(index) {
    const name = this.sequenceNames[index]
    if (!name) return
    this.disposeActiveInstances()
    this.artboard = this.file.artboardByName(this.activeArtboardName)
    this.applyAudioPreference()
    const definition = this.artboard.animationByName(name)
    this.animation = new this.runtime.LinearAnimationInstance(definition, this.artboard)
    this.animationDuration = getAnimationDuration(definition)
    this.animationElapsed = 0
    this.activeAnimationName = name
    this.activeStateMachineName = ''
    this.bindDefaultViewModels()
    this.sequenceIndex = index
    this.sequenceElapsed = 0
    this.lastTime = 0
    this.playing = true
    this.updateViewMatrix()
    this.onPlaybackChange({
      isPlaying: true,
      activeState: `播放 ${name}`,
      animation: name
    })
    this.emitTimelineProgress(true)
    this.requestRedraw()
  }

  emitTimelineProgress(force = false) {
    if (!this.animation) {
      if (force) {
        this.onTimelineProgress({
          animation: '',
          progress: 0,
          time: 0,
          duration: 0,
          isPlaying: this.playing
        })
      }
      return
    }
    const now = Date.now()
    if (!force && now - this.lastProgressEmitAt < 180) return
    this.lastProgressEmitAt = now
    const duration = this.animationDuration || 0
    const isLoopingIdle = this.activeAnimationName.trim().toLowerCase() === 'idle'
      && (!this.sequenceMode || !this.sequenceHasOut)
    const time = duration > 0
      ? (isLoopingIdle
          ? this.animationElapsed % duration
          : Math.min(this.animationElapsed, duration))
      : Math.max(0, this.animationElapsed)
    const progress = duration > 0
      ? Math.max(0, Math.min(100, (time / duration) * 100))
      : 0
    this.onTimelineProgress({
      animation: this.activeAnimationName,
      progress,
      time,
      duration,
      isPlaying: this.playing
    })
  }

  advanceSequence(elapsed) {
    if (!this.sequenceMode || !this.animation) return
    this.sequenceElapsed += elapsed
    const duration = this.animationDuration || 0
    const completed = Boolean(this.animation.didLoop) || (duration > 0 && this.sequenceElapsed >= duration)
    if (!completed) return

    const activeName = this.sequenceNames[this.sequenceIndex] || ''
    const isIdle = activeName.trim().toLowerCase() === 'idle'
    const nextIndex = this.sequenceIndex + 1
    if (isIdle && !this.sequenceHasOut) {
      this.sequenceElapsed = 0
      return
    }
    if (nextIndex < this.sequenceNames.length) {
      this.activateSequenceStep(nextIndex)
      return
    }
    this.playing = false
    this.sequenceFinished = true
    this.onTimelineProgress({
      animation: activeName,
      progress: 100,
      time: duration,
      duration,
      isPlaying: false
    })
    this.onPlaybackChange({
      isPlaying: false,
      activeState: `${activeName} 播放完成`,
      animation: activeName
    })
  }

  getPublicMetadata() {
    const artboard = this.metadata.artboards.find((item) => item.name === this.activeArtboardName)
    const selectedMachine = artboard.stateMachines.find(
      (item) => item.name === this.selectedStateMachineName
    ) || artboard.stateMachines[0]
    const inputs = this.inputRefs.length
      ? this.inputRefs.map((input, index) => this.describeInput(input, index))
      : (selectedMachine?.inputs || [])
    return {
      artboards: this.metadata.artboards,
      artboardCount: this.metadata.artboardCount || this.metadata.artboards.length,
      artboardCatalogLoaded: Boolean(this.metadata.artboardCatalogLoaded),
      activeArtboard: this.activeArtboardName,
      activeStateMachine: selectedMachine?.name || '',
      activeAnimation: this.activeAnimationName || '',
      isPlaying: this.playing,
      width: artboard.width,
      height: artboard.height,
      animations: artboard.animations,
      stateMachines: artboard.stateMachines,
      inputs,
      hasAudio: this.hasAudio,
      audioEnabled: this.audioEnabled,
      audioSupported: this.audioSupported,
      audioBlockedReason: this.audioBlockedReason,
      fitLabel: fitLabel(this.fitKey),
      alignmentLabel: alignmentLabel(this.alignmentKey)
    }
  }

  updateViewMatrix() {
    if (!this.runtime || !this.artboard) return
    if (this.viewMatrix?.delete) this.viewMatrix.delete()
    this.viewMatrix = this.runtime.computeAlignment(
      this.runtime.Fit[this.fitKey],
      this.runtime.Alignment[this.alignmentKey],
      {
        minX: 0,
        minY: 0,
        maxX: this.width,
        maxY: this.height
      },
      this.artboard.bounds
    )
  }

  setFit(key) {
    if (!this.runtime.Fit[key] && this.runtime.Fit[key] !== 0) return
    this.fitKey = key
    this.updateViewMatrix()
    this.requestRedraw()
  }

  setAlignment(key) {
    if (!this.runtime.Alignment[key]) return
    this.alignmentKey = key
    this.updateViewMatrix()
    this.requestRedraw()
  }

  applyAudioPreference() {
    if (!this.artboard) return
    this.nativePianoAudio?.setEnabled(this.audioEnabled && this.audioSupported)
    try {
      this.artboard.volume = this.usesNativePianoAudio
        ? 0
        : (this.audioEnabled && this.audioSupported ? 1 : 0)
    } catch (error) {
      console.warn('Rive 音量设置失败', error)
    }
  }

  releasePianoCueBindings() {
    this.pianoCueBindings = []
    this.pianoCueOwners.forEach((owner) => owner?.unref?.())
    this.pianoCueOwners = []
  }

  prepareNativePianoAudio() {
    const nativePianoAudio = this.nativePianoAudio
    if (
      this.nativePianoAudioPreparationStarted
      || !this.usesNativePianoAudio
      || !nativePianoAudio
      || this.disposed
    ) return
    this.nativePianoAudioPreparationStarted = true
    nativePianoAudio.prepare()
      .then((ready) => {
        if (this.disposed || this.nativePianoAudio !== nativePianoAudio) return
        if (!ready) this.disableNativePianoAudio('部分钢琴音效无法解码')
      })
      .catch((error) => {
        if (this.disposed || this.nativePianoAudio !== nativePianoAudio) return
        console.warn('iOS 钢琴低延迟声音准备失败', error)
        this.disableNativePianoAudio(
          error?.message || '当前微信版本不支持低延迟声音'
        )
      })
  }

  disableNativePianoAudio(reason, { notify = true } = {}) {
    if (!this.usesNativePianoAudio) return
    this.audioSupported = false
    this.audioBlockedReason = reason || '当前设备不支持低延迟声音'
    clearTimeout(this.nativePianoAudioPrepareTimer)
    this.nativePianoAudioPrepareTimer = 0
    this.releasePianoCueBindings()
    this.nativePianoAudio?.setEnabled(false)
    this.nativePianoAudio?.dispose()
    this.nativePianoAudio = null
    this.applyAudioPreference()
    if (notify && this.metadata && !this.disposed) this.onMetadata(this.getPublicMetadata())
  }

  resumeAudioPlayback() {
    if (!this.audioEnabled || !this.audioSupported || !this.hasAudio) return false
    if (this.usesNativePianoAudio) return this.nativePianoAudio?.resume() || false
    return resumeRuntimeAudio()
  }

  suspendAudioPlayback() {
    if (this.usesNativePianoAudio) return this.nativePianoAudio?.suspend() || false
    return suspendRuntimeAudio()
  }

  setAudioEnabled(enabled) {
    this.audioEnabled = Boolean(enabled)
    this.applyAudioPreference()
    if (this.audioEnabled && this.audioSupported && this.hasAudio) this.resumeAudioPlayback()
    else this.suspendAudioPlayback()
    return {
      enabled: this.audioEnabled,
      hasAudio: this.hasAudio,
      supported: this.audioSupported,
      blockedReason: this.audioBlockedReason
    }
  }

  resize(width, height) {
    const nextWidth = Math.max(1, Number(width) || this.width)
    const nextHeight = Math.max(1, Number(height) || this.height)
    if (nextWidth === this.width && nextHeight === this.height) return
    this.width = nextWidth
    this.height = nextHeight
    this.activateCanvas()
    this.canvas.width = Math.max(1, Math.round(nextWidth * this.pixelRatio))
    this.canvas.height = Math.max(1, Math.round(nextHeight * this.pixelRatio))
    this.updateViewMatrix()
    this.requestRedraw()
  }

  setQualityMode(mode) {
    if (!QUALITY_PROFILES[mode]) return
    this.qualityMode = mode
    this.configurePerformanceProfile()
    this.updateViewMatrix()
    this.requestRedraw()
  }

  setSpeed(value) {
    this.speed = Math.max(0.1, Math.min(8, Number(value) || 1))
  }

  play() {
    if (this.sequenceMode && this.sequenceFinished) {
      this.playDefaultSequence()
      return
    }
    this.playing = true
    this.lastTime = 0
    this.scheduleRender()
    this.resumeAudioPlayback()
    this.onPlaybackChange({
      isPlaying: true,
      activeState: this.activeAnimationName ? `播放 ${this.activeAnimationName}` : '正在播放'
    })
  }

  pause() {
    this.playing = false
    this.lastTime = 0
    this.cancelFrame(this.frameRequest)
    this.frameRequest = 0
    if (this.hasAudio) this.suspendAudioPlayback()
    this.emitTimelineProgress(true)
    this.onPlaybackChange({ isPlaying: false, activeState: '已暂停' })
  }

  stop() {
    this.activateArtboard(this.activeArtboardName, this.activeStateMachineName)
    this.playing = false
    this.lastTime = 0
    if (this.hasAudio) this.suspendAudioPlayback()
    this.requestRedraw()
  }

  reset() {
    this.activateArtboard(this.activeArtboardName, this.selectedStateMachineName)
    if (!this.activeStateMachineHasListeners()) this.playDefaultSequence()
    this.resumeAudioPlayback()
    this.onPlaybackChange({ isPlaying: true, activeState: '已重置' })
  }

  ensureStateMachine(machineName) {
    const targetName = machineName || this.selectedStateMachineName
    if (!targetName) return false
    if (!this.stateMachine || this.activeStateMachineName !== targetName) {
      this.activateArtboard(this.activeArtboardName, targetName)
      this.onMetadata(this.getPublicMetadata())
    }
    return true
  }

  setInput(index, value, machineName) {
    if (!this.ensureStateMachine(machineName)) return
    const input = this.inputRefs[index]
    if (!input) return
    input.value = value
    this.advanceStateMachine(0)
    this.requestRedraw()
    this.resumeAudioPlayback()
  }

  fireInput(index, machineName) {
    if (!this.ensureStateMachine(machineName)) return
    const input = this.inputRefs[index]
    if (!input) return
    input.fire()
    const changedStates = this.advanceStateMachine(0)
    this.resumeAudioPlayback()
    const enteredOnlyUnnamedStates = changedStates.length > 0
      && changedStates.every((name) => !String(name || '').trim())
    const fallbackAnimation = enteredOnlyUnnamedStates
      ? this.metadata?.artboards
          .find((item) => item.name === this.activeArtboardName)
          ?.animations.find((name) => (
            name.trim().toLowerCase() === input.name.trim().toLowerCase()
          ))
      : ''
    if (fallbackAnimation) {
      this.selectAnimation(fallbackAnimation)
      return { fallbackAnimation }
    }
    this.play()
    return { fallbackAnimation: '' }
  }

  pointer(type, x, y, pointerId = 0) {
    this.activateCanvas()
    if (type === 'down') this.resumeAudioPlayback()
    if (!this.stateMachine && type === 'down' && this.selectedStateMachineName) {
      this.ensureStateMachine(this.selectedStateMachineName)
    }
    if (!this.stateMachine || !this.viewMatrix) return
    const matrix = this.viewMatrix
    const canvasX = x
    const canvasY = y
    const determinant = matrix.xx * matrix.yy - matrix.yx * matrix.xy
    if (!determinant) return
    const translatedX = canvasX - matrix.tx
    const translatedY = canvasY - matrix.ty
    const artboardX = (matrix.yy * translatedX - matrix.yx * translatedY) / determinant
    const artboardY = (-matrix.xy * translatedX + matrix.xx * translatedY) / determinant
    const method = {
      down: 'pointerDown',
      move: 'pointerMove',
      up: 'pointerUp',
      exit: 'pointerExit'
    }[type]
    if (method && this.stateMachine[method]) {
      this.stateMachine[method](artboardX, artboardY, pointerId)
      this.advanceStateMachine(0)
      this.requestRedraw()
    }
    if (
      (type === 'down' || type === 'up')
      && this.audioEnabled
      && this.audioSupported
      && this.hasAudio
    ) {
      this.resumeAudioPlayback()
    }
  }

  advanceStateMachine(elapsed) {
    if (!this.stateMachine) return []
    this.stateMachine.advance(elapsed)
    this.artboard?.advance(elapsed)
    if (this.usesNativePianoAudio && this.pianoCueBindings.length) {
      collectPianoCueChanges(this.pianoCueBindings).forEach((cue) => {
        this.nativePianoAudio?.play(cue)
      })
    }
    const changed = this.stateMachine.stateChangedCount()
    const states = []
    if (changed > 0) {
      for (let index = 0; index < changed; index += 1) {
        states.push(this.stateMachine.stateChangedNameByIndex(index))
      }
      const meaningfulStates = states.filter((name) => String(name || '').trim())
      if (meaningfulStates.length) this.onStateChange(meaningfulStates)
    }
    return states
  }

  render(time) {
    if (this.disposed) return
    try {
      this.renderFrame(time)
    } catch (error) {
      this.onError(error)
      this.dispose()
    }
  }

  renderFrame(time) {
    this.frameRequest = 0
    this.activateCanvas()
    if (
      this.playing
      && this.frameInterval > 0
      && this.lastRenderAt
      && time - this.lastRenderAt < this.frameInterval
    ) {
      this.scheduleRender()
      return
    }
    if (!this.playing && !this.needsRedraw) return
    this.needsRedraw = false
    this.lastRenderAt = time
    const elapsed = this.lastTime ? Math.min((time - this.lastTime) / 1000, 0.1) : 0
    this.lastTime = time
    this.renderer.clear()

    if (this.playing) {
      const scaledElapsed = elapsed * this.speed
      if (this.stateMachine) {
        if (scaledElapsed > 0) this.advanceStateMachine(scaledElapsed)
      } else {
        if (this.animation) {
          this.animation.advance(scaledElapsed)
          this.animation.apply(1)
          this.animationElapsed += scaledElapsed
        }
        this.artboard.advance(scaledElapsed)
      }
      this.emitTimelineProgress()
      this.advanceSequence(scaledElapsed)
    }

    this.renderer.save()
    this.renderer.align(
      this.runtime.Fit[this.fitKey],
      this.runtime.Alignment[this.alignmentKey],
      {
        minX: 0,
        minY: 0,
        maxX: this.canvas.width,
        maxY: this.canvas.height
      },
      this.artboard.bounds
    )
    this.artboard.draw(this.renderer)
    this.renderer.restore()
    if (this.renderer.flush) this.renderer.flush()
    if (!this.performanceStartedAt) this.performanceStartedAt = time
    this.performanceFrames += 1
    const performanceElapsed = time - this.performanceStartedAt
    if (performanceElapsed >= 700) {
      this.onPerformance(Math.round(this.performanceFrames * 1000 / performanceElapsed))
      this.performanceStartedAt = time
      this.performanceFrames = 0
    }
    if (!this.firstFrameRendered) {
      this.firstFrameRendered = true
      this.onFirstFrame()
      if (this.usesNativePianoAudio && this.nativePianoAudio) {
        this.nativePianoAudioPrepareTimer = setTimeout(() => {
          this.nativePianoAudioPrepareTimer = 0
          this.prepareNativePianoAudio()
        }, 16)
      }
    }
    if (this.playing || this.needsRedraw) this.scheduleRender()
  }

  disposeActiveInstances() {
    if (this.stateMachine?.delete) this.stateMachine.delete()
    if (this.animation?.delete) this.animation.delete()
    this.releasePianoCueBindings()
    this.boundViewModelInstances.forEach((instance) => instance?.unref?.())
    if (this.artboard?.delete) this.artboard.delete()
    this.stateMachine = null
    this.animation = null
    this.animationDuration = 0
    this.animationElapsed = 0
    this.artboard = null
    this.inputRefs = []
    this.boundViewModelInstances = []
    this.activeAnimationName = ''
  }

  dispose() {
    if (this.disposed) return
    this.disposed = true
    clearTimeout(this.nativePianoAudioPrepareTimer)
    this.nativePianoAudioPrepareTimer = 0
    this.cancelFrame(this.frameRequest)
    this.frameRequest = 0
    this.artboardCatalogProgressCallbacks.clear()
    this.audioEnabled = false
    this.applyAudioPreference()
    this.suspendAudioPlayback()
    this.nativePianoAudio?.dispose()
    this.nativePianoAudio = null
    this.disposeActiveInstances()
    if (this.viewMatrix?.delete) this.viewMatrix.delete()
    if (this.renderer?.delete) this.renderer.delete()
    if (this.file?.unref) this.file.unref()
    this.viewMatrix = null
    this.renderer = null
    this.file = null
  }
}

module.exports = {
  collectPianoCueChanges,
  createPianoCueBindings,
  detectEmbeddedImageExtension,
  getAudioBlockedReason,
  getPlaybackPerformanceProfile,
  isCompatibleCueAudioContext,
  isPianoAudioCandidate,
  MiniProgramCueAudio,
  NativeRivePlayer,
  getRuntime,
  isCompatibleWebAudioContext,
  isIOSMiniProgram,
  MAX_AUDIO_SOURCE_BYTES,
  prewarmRuntime,
  resumeAudioDevices,
  shouldBypassEmbeddedAudio,
  supportsMiniProgramWebAudio,
  suspendAudioDevices,
  suspendRuntimeAudio
}
