const previewDefinition = require('../../pages/preview/preview-definition')

const LIFECYCLE_METHODS = new Set([
  'onLoad',
  'onReady',
  'onShow',
  'onHide',
  'onUnload',
  'onShareAppMessage',
  'onShareTimeline'
])

const sharedMethods = {}
Object.entries(previewDefinition).forEach(([name, value]) => {
  if (
    name !== 'data'
    && !LIFECYCLE_METHODS.has(name)
    && typeof value === 'function'
  ) {
    sharedMethods[name] = value
  }
})

const initialData = JSON.parse(JSON.stringify(previewDefinition.data))

Component({
  options: {
    styleIsolation: 'isolated'
  },

  properties: {
    fileId: {
      type: String,
      value: '',
      observer: '_fileIdChanged'
    }
  },

  data: {
    ...initialData
  },

  lifetimes: {
    attached() {
      this.isEmbeddedPreview = true
      this.embeddedPreviewAttached = true
      this.pageVisible = true
      this._loadEmbeddedFile(this.data.fileId)
    },
    ready() {
      previewDefinition.onReady.call(this)
    },
    detached() {
      this.embeddedPreviewAttached = false
      previewDefinition.onUnload.call(this)
    }
  },

  pageLifetimes: {
    show() {
      previewDefinition.onShow.call(this)
    },
    hide() {
      previewDefinition.onHide.call(this)
    }
  },

  methods: {
    ...sharedMethods,

    _fileIdChanged(fileId) {
      if (!this.embeddedPreviewAttached || !fileId) return
      this._loadEmbeddedFile(fileId)
    },

    _loadEmbeddedFile(fileId) {
      if (!fileId || fileId === this.embeddedPreviewFileId) return
      const replacingFile = Boolean(this.embeddedPreviewFileId)
      this.embeddedPreviewFileId = fileId
      if (replacingFile) {
        this.disposePreview()
        this.setData(JSON.parse(JSON.stringify(initialData)))
      }
      this.pageVisible = true
      this.setData({
        previewTransitionVisible: false,
        previewTransitionExpanding: false,
        previewTransitionLeaving: false
      })
      previewDefinition.onLoad.call(this, {
        id: encodeURIComponent(fileId),
        embedded: '1'
      })
      if (replacingFile && this.previewReady && this.data.file) {
        this.startPreview()
      }
    },

    closeEmbedded() {
      this.disposePreview()
      this.triggerEvent('close')
    }
  }
})
