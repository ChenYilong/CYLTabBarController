import assert from 'node:assert/strict'
import { createRequire } from 'node:module'
import test from 'node:test'

globalThis.wx = { env: { USER_DATA_PATH: '/tmp/rive-viewer-tests' } }

const requireModule = createRequire(import.meta.url)
const previewDefinition = requireModule('../pages/preview/preview-definition.js')

function createHarness(fit = 'cover') {
  const context = {
    ...previewDefinition,
    data: {
      ...previewDefinition.data,
      fit,
      stageHeight: 480,
      stageWidth: 702,
      stageDragging: false,
      stageResizeMenuActive: false,
      stageResizeTapOpen: false,
      stageResizePressActive: false,
      stageResizeHoverFit: ''
    },
    windowInfo: { windowWidth: 375 },
    activeResourceSize: { width: 750, height: 1160 },
    clock: 0,
    applyFitCalls: [],
    menuScheduleCount: 0,
    setData(patch, callback) {
      Object.assign(this.data, patch)
      callback?.()
    },
    getStageResizeTimestamp() {
      return this.clock
    },
    clearStageResizeMenuDismiss() {
      this.stageResizeMenuDismissTimer = 0
    },
    scheduleStageResizeMenuDismiss() {
      this.menuScheduleCount += 1
    },
    measureStageResizeSelector() {
      this.stageResizeSelectorRect = { left: 0, width: 300 }
    },
    applyFit(nextFit, announce) {
      this.applyFitCalls.push({ fit: nextFit, announce })
      this.data.fit = nextFit
    },
    syncCanvasSize() {},
    recordResizeAdjustment() {}
  }
  return context
}

function startGesture(context, x = 150, y = 100) {
  context.stageResizeStart({
    touches: [{ clientX: x, clientY: y }]
  })
}

function endGesture(context, time, x = 150, y = 100) {
  context.clock = time
  context.stageResizeEnd({
    changedTouches: [{ clientX: x, clientY: y }],
    target: { dataset: {} }
  })
}

function moveGesture(context, x, y) {
  context.stageResizeMove({
    touches: [{ clientX: x, clientY: y }]
  })
}

test('单击只展开选项，500ms 内第二击切换完整或铺满', () => {
  const context = createHarness('cover')

  startGesture(context)
  endGesture(context, 1000)

  assert.equal(context.data.stageResizeTapOpen, true)
  assert.equal(context.data.fit, 'cover')
  assert.equal(context.menuScheduleCount, 1)
  assert.deepEqual(context.applyFitCalls, [])

  startGesture(context)
  endGesture(context, 1250)

  assert.equal(context.data.stageResizeTapOpen, false)
  assert.equal(context.data.fit, 'contain')
  assert.deepEqual(context.applyFitCalls, [{ fit: 'contain', announce: true }])
  assert.equal(context.lastStageTapAt, 0)
})

test('超过 500ms 的第二次点击按新的单击处理', () => {
  const context = createHarness('cover')

  startGesture(context)
  endGesture(context, 1000)
  startGesture(context)
  endGesture(context, 1600)

  assert.equal(context.data.stageResizeTapOpen, true)
  assert.equal(context.data.fit, 'cover')
  assert.equal(context.menuScheduleCount, 2)
  assert.deepEqual(context.applyFitCalls, [])
})

test('拖动或长按不会被识别成双击', () => {
  const dragged = createHarness('cover')
  startGesture(dragged)
  dragged.lastStageTapAt = 1000
  dragged.stageResizePointerMoved = true
  dragged.stageResizeMoved = true
  dragged.data.stageDragging = true
  endGesture(dragged, 1200)

  assert.deepEqual(dragged.applyFitCalls, [])
  assert.equal(dragged.lastStageTapAt, 0)
  assert.equal(dragged.data.stageResizeMenuActive, false)

  const longPressed = createHarness('cover')
  startGesture(longPressed)
  longPressed.stageResizeLongPress()
  endGesture(longPressed, 1000)

  assert.deepEqual(longPressed.applyFitCalls, [])
  assert.equal(longPressed.lastStageTapAt, 0)
})

test('双击时的轻微手指抖动不会被误判为拖动', () => {
  const context = createHarness('cover')

  startGesture(context)
  moveGesture(context, 153, 103)
  endGesture(context, 1000)
  startGesture(context)
  moveGesture(context, 154, 102)
  endGesture(context, 1250)

  assert.equal(context.data.fit, 'contain')
  assert.deepEqual(context.applyFitCalls, [{ fit: 'contain', announce: true }])
})

test('展开后的完整或铺满选项由父层 touchend 直接生效', () => {
  const context = createHarness('cover')

  startGesture(context)
  endGesture(context, 1000)
  startGesture(context, 40)
  context.clock = 1200
  context.stageResizeEnd({
    changedTouches: [{ clientX: 40, clientY: 100 }],
    target: { dataset: { fit: 'contain' } }
  })

  assert.equal(context.data.stageResizeMenuActive, false)
  assert.deepEqual(context.applyFitCalls, [{ fit: 'contain', announce: true }])
})

test('左右滑选以松手位置为准', () => {
  const context = createHarness('contain')

  startGesture(context, 40)
  moveGesture(context, 260, 100)
  endGesture(context, 1000, 260)

  assert.deepEqual(context.applyFitCalls, [{ fit: 'cover', announce: true }])
})
