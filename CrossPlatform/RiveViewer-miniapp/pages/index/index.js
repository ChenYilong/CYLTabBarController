const {
  getAllFiles,
  getFileById,
  importTempFiles,
  removeFile
} = require('../../utils/library')
const {
  describeFileActionError,
  isCancelError,
  sharePreparedFile
} = require('../../utils/file-actions')
const {
  enableShareMenu,
  FRIEND_SHARE_IMAGE,
  HOME_PATH,
  SHARE_TITLE,
  TIMELINE_SHARE_IMAGE,
  TIMELINE_QUERY
} = require('../../utils/share')
const {
  getWindowInfo,
  supportsDesktopSplit
} = require('../../utils/desktop-split')

const WEB_VIEW_URL = 'https://mikeywa.site/rive-viewer/'

Page({
  data: {
    files: [],
    importing: false,
    userFileCount: 0,
    expandedFileId: '',
    desktopSplitEnabled: false,
    desktopPreviewFileId: ''
  },

  onLoad(options = {}) {
    const windowInfo = getWindowInfo()
    const desktopSplitEnabled = supportsDesktopSplit(windowInfo)
    const requestedPreviewId = decodeURIComponent(options.preview || '')
    const desktopPreviewFileId = desktopSplitEnabled
      && requestedPreviewId
      && getFileById(requestedPreviewId)
      ? requestedPreviewId
      : ''
    this.setData({ desktopSplitEnabled, desktopPreviewFileId })
    this.desktopWindowResizeHandler = (result) => {
      this.updateDesktopSplit(result?.size || getWindowInfo())
    }
    if (typeof wx.onWindowResize === 'function') {
      wx.onWindowResize(this.desktopWindowResizeHandler)
    }
  },

  onReady() {
    this.rivePrewarmTimer = setTimeout(() => this.startRivePrewarm(), 600)
  },

  onHide() {
    clearTimeout(this.rivePrewarmTimer)
    this.rivePrewarmTimer = 0
  },

  onUnload() {
    clearTimeout(this.rivePrewarmTimer)
    this.rivePrewarmTimer = 0
    if (this.desktopWindowResizeHandler && typeof wx.offWindowResize === 'function') {
      wx.offWindowResize(this.desktopWindowResizeHandler)
    }
    this.desktopWindowResizeHandler = null
  },

  onShareAppMessage: function () {
    return {
      title: SHARE_TITLE,
      path: HOME_PATH,
      imageUrl: FRIEND_SHARE_IMAGE
    }
  },

  onShareTimeline: function () {
    return {
      title: SHARE_TITLE,
      query: TIMELINE_QUERY,
      imageUrl: TIMELINE_SHARE_IMAGE
    }
  },

  onShow() {
    enableShareMenu()
    this.updateDesktopSplit(getWindowInfo())
    this.refreshFiles()
  },

  updateDesktopSplit(windowInfo) {
    const desktopSplitEnabled = supportsDesktopSplit(windowInfo)
    if (desktopSplitEnabled === this.data.desktopSplitEnabled) return
    const activeFileId = this.data.desktopPreviewFileId
    if (desktopSplitEnabled || !activeFileId) {
      this.setData({ desktopSplitEnabled })
      return
    }
    this.setData({
      desktopSplitEnabled: false,
      desktopPreviewFileId: ''
    }, () => {
      wx.navigateTo({
        url: `/pages/preview/index?id=${encodeURIComponent(activeFileId)}`
      })
    })
  },

  startRivePrewarm() {
    clearTimeout(this.rivePrewarmTimer)
    this.rivePrewarmTimer = 0
    if (this.rivePrewarmStarted) return
    this.rivePrewarmStarted = true
    const { prewarmRuntime } = require('../../utils/rive-native')
    prewarmRuntime().catch((error) => {
      this.rivePrewarmStarted = false
      console.warn('Rive 运行时预热失败，将在预览时重试', error)
    })
  },

  refreshFiles() {
    const files = getAllFiles()
    const desktopPreviewFileId = this.data.desktopPreviewFileId
    const activeFileExists = !desktopPreviewFileId
      || files.some((file) => file.id === desktopPreviewFileId)
    this.setData({
      files,
      userFileCount: files.filter((file) => !file.builtin).length,
      desktopPreviewFileId: activeFileExists ? desktopPreviewFileId : ''
    })
  },

  showImportMenu() {
    if (this.data.importing) return
    const canChooseSystemFile = typeof wx.miniapp?.chooseFile === 'function'
    const itemList = canChooseSystemFile
      ? ['从微信聊天文件导入', '从系统文件导入']
      : ['从微信聊天文件导入']
    wx.showActionSheet({
      alertText: canChooseSystemFile
        ? '支持多选 .riv 文件并逐个保存在本地'
        : '聊天文件支持多选 .riv 并逐个保存在本地',
      itemList,
      success: ({ tapIndex }) => {
        if (tapIndex === 0) this.chooseMessageFile()
        if (tapIndex === 1 && canChooseSystemFile) this.chooseSystemFile()
      }
    })
  },

  copyWebViewerUrl() {
    if (typeof wx.setClipboardData !== 'function') {
      wx.showToast({ title: '请长按网址复制', icon: 'none' })
      return
    }
    wx.setClipboardData({
      data: WEB_VIEW_URL,
      success: () => {
        wx.showToast({ title: '已复制网址', icon: 'none' })
      },
      fail: (error) => {
        console.error('网页版地址复制失败', error)
        wx.showToast({ title: '复制失败，请长按网址', icon: 'none' })
      }
    })
  },

  chooseMessageFile() {
    if (this.data.importing) return
    this.setData({ importing: true })
    wx.chooseMessageFile({
      count: 100,
      type: 'file',
      extension: ['riv'],
      success: (result) => this.importSelectedFiles(result.tempFiles, '微信聊天文件'),
      fail: (error) => {
        this.setData({ importing: false })
        if (!String(error.errMsg || '').includes('cancel')) {
          wx.showToast({ title: '文件选择失败', icon: 'none' })
        }
      }
    })
  },

  chooseSystemFile() {
    if (this.data.importing || typeof wx.miniapp?.chooseFile !== 'function') return
    this.setData({ importing: true })
    wx.miniapp.chooseFile({
      allowsMultipleSelection: true,
      success: (result) => this.importSelectedFiles(
        result.tempFiles || result.files,
        '系统文件'
      ),
      fail: (error) => {
        this.setData({ importing: false })
        if (!String(error.errMsg || '').includes('cancel')) {
          wx.showToast({ title: '系统文件选择失败', icon: 'none' })
        }
      }
    })
  },

  async importSelectedFiles(tempFiles, source) {
    const selectedFiles = Array.isArray(tempFiles) ? tempFiles.filter(Boolean) : []
    try {
      if (!selectedFiles.length) throw new Error('没有选择文件')
      wx.showLoading({ title: `导入 0/${selectedFiles.length}`, mask: true })
      const { imported, failures } = await importTempFiles(
        selectedFiles,
        source,
        ({ current, total }) => {
          wx.showLoading({ title: `导入 ${current}/${total}`, mask: true })
        }
      )
      wx.hideLoading()
      this.refreshFiles()
      if (!imported.length) {
        const firstFailure = failures[0]
        throw new Error(firstFailure?.message || '所选文件均未能导入')
      }
      if (failures.length) {
        wx.showModal({
          title: '部分文件未导入',
          content: `已导入 ${imported.length} 个，失败 ${failures.length} 个。${failures[0].name}：${failures[0].message}`,
          showCancel: false
        })
      } else {
        wx.showToast({
          title: imported.length === 1 ? '已导入' : `已导入${imported.length}个`,
          icon: 'success'
        })
      }
      if (imported.length === 1 && selectedFiles.length === 1) {
        this.openById(imported[0].id)
      }
    } catch (error) {
      wx.hideLoading()
      wx.showModal({
        title: '无法导入',
        content: error.message || error.errMsg || '请确认文件可读取',
        showCancel: false
      })
    } finally {
      this.setData({ importing: false })
    }
  },

  openFile(event) {
    this.setData({ expandedFileId: '' })
    const id = event.currentTarget.dataset.id
    const index = Number(event.currentTarget.dataset.index)
    const file = this.data.files[index]
    if (!file || file.id !== id || !file.cover) {
      this.openById(id)
      return
    }
    this.openWithCoverTransition(file, index)
  },

  openWithCoverTransition(file, index) {
    if (this.transitioningFileId) return
    this.startRivePrewarm()
    if (this.data.desktopSplitEnabled) {
      this.openDesktopPreview(file.id)
      return
    }
    this.transitioningFileId = file.id
    wx.createSelectorQuery()
      .selectAll('.file-cover')
      .boundingClientRect((rects) => {
        const rect = rects?.[index]
        if (rect?.width && rect?.height) {
          getApp().globalData.pendingPreviewTransition = {
            fileId: file.id,
            cover: file.cover,
            rect: {
              left: rect.left,
              top: rect.top,
              width: rect.width,
              height: rect.height
            }
          }
        }
        wx.navigateTo({
          url: `/pages/preview/index?id=${encodeURIComponent(file.id)}`,
          animationType: 'none',
          animationDuration: 0,
          fail: () => {
            if (getApp().globalData.pendingPreviewTransition?.fileId === file.id) {
              getApp().globalData.pendingPreviewTransition = null
            }
          },
          complete: () => {
            this.transitioningFileId = ''
          }
        })
      })
      .exec()
  },

  toggleFileMenu(event) {
    const id = event.currentTarget.dataset.id
    this.setData({
      expandedFileId: this.data.expandedFileId === id ? '' : id
    })
  },

  openById(id) {
    this.startRivePrewarm()
    if (this.data.desktopSplitEnabled) {
      this.openDesktopPreview(id)
      return
    }
    wx.navigateTo({
      url: `/pages/preview/index?id=${encodeURIComponent(id)}`
    })
  },

  openDesktopPreview(fileId) {
    if (!fileId) return
    this.transitioningFileId = ''
    getApp().globalData.pendingPreviewTransition = null
    this.setData({
      expandedFileId: '',
      desktopPreviewFileId: fileId
    })
  },

  closeDesktopPreview() {
    this.setData({ desktopPreviewFileId: '' })
  },

  selectDesktopPreviewFile(event) {
    const fileId = event.detail?.fileId
    if (!fileId || fileId === this.data.desktopPreviewFileId) return
    this.setData({ desktopPreviewFileId: fileId })
  },

  showAuthorWechat() {
    wx.showModal({
      title: '联系作者反馈意见',
      content: '微信号：yanghaoeleng\n请在微信“添加朋友”中手动输入。',
      showCancel: false,
      confirmText: '知道了'
    })
  },

  showFileActionError(title, error) {
    if (isCancelError(error)) return
    console.error(title, error)
    wx.showModal({
      title,
      content: describeFileActionError(error, '请稍后重试'),
      showCancel: false,
      confirmText: '知道了'
    })
  },

  shareFileById(id) {
    sharePreparedFile(id, {
      success: () => wx.showToast({ title: '已打开发送面板', icon: 'success' }),
      fail: (error) => this.showFileActionError('发送失败', error)
    })
  },

  shareFile(event) {
    const id = event.currentTarget.dataset.id
    this.setData({ expandedFileId: '' })
    this.shareFileById(id)
  },

  deleteFile(event) {
    const id = event.currentTarget.dataset.id
    const file = this.data.files.find((item) => item.id === id)
    if (!file) return
    this.setData({ expandedFileId: '' })
    wx.showModal({
      title: file.builtin ? '删除示例文件' : '删除本地文件',
      content: file.builtin
        ? `删除后“${file.name}”将不再显示。清除小程序本地数据后可恢复。`
        : `将从小程序本地存储中删除“${file.name}”。`,
      confirmText: '删除',
      confirmColor: '#b94040',
      success: async (result) => {
        if (!result.confirm) return
        try {
          await removeFile(id)
          if (id === this.data.desktopPreviewFileId) {
            this.setData({ desktopPreviewFileId: '' })
          }
          this.refreshFiles()
          wx.showToast({ title: '已删除', icon: 'success' })
        } catch (error) {
          wx.showToast({ title: '删除失败', icon: 'none' })
        }
      }
    })
  }
})
