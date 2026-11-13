const { calculateNavigationLayout } = require('./navigation-layout')

const HOME_PATH = '/pages/index/index'

function getWindowInfo() {
  try {
    return typeof wx.getWindowInfo === 'function'
      ? wx.getWindowInfo()
      : wx.getSystemInfoSync()
  } catch (error) {
    return {}
  }
}

function getDeviceInfo() {
  try {
    return typeof wx.getDeviceInfo === 'function'
      ? wx.getDeviceInfo()
      : wx.getSystemInfoSync()
  } catch (error) {
    return {}
  }
}

function getMenuRect() {
  try {
    return typeof wx.getMenuButtonBoundingClientRect === 'function'
      ? wx.getMenuButtonBoundingClientRect()
      : {}
  } catch (error) {
    return {}
  }
}

Component({
  options: {
    multipleSlots: true // 在组件定义时的选项中启用多slot支持
  },
  /**
   * 组件的属性列表
   */
  properties: {
    extClass: {
      type: String,
      value: ''
    },
    title: {
      type: String,
      value: ''
    },
    background: {
      type: String,
      value: ''
    },
    color: {
      type: String,
      value: ''
    },
    back: {
      type: Boolean,
      value: true
    },
    externalBack: {
      type: Boolean,
      value: false
    },
    loading: {
      type: Boolean,
      value: false
    },
    homeButton: {
      type: Boolean,
      value: false,
    },
    animated: {
      // 显示隐藏的时候opacity动画效果
      type: Boolean,
      value: true
    },
    show: {
      // 显示隐藏导航，隐藏的时候navigation-bar的高度占位还在
      type: Boolean,
      value: true,
      observer: '_showChange'
    },
    // back为true的时候，返回的页面深度
    delta: {
      type: Number,
      value: 1
    },
  },
  /**
   * 组件的初始数据
   */
  data: {
    displayStyle: '',
    innerPaddingRight: '',
    leftWidth: '',
    safeAreaTop: ''
  },
  lifetimes: {
    attached() {
      this._windowResizeHandler = () => this._updateLayout()
      this._updateLayout()
      if (typeof wx.onWindowResize === 'function') {
        wx.onWindowResize(this._windowResizeHandler)
      }
    },
    detached() {
      if (this._windowResizeHandler && typeof wx.offWindowResize === 'function') {
        wx.offWindowResize(this._windowResizeHandler)
      }
      this._windowResizeHandler = null
    }
  },
  /**
   * 组件的方法列表
   */
  methods: {
    _updateLayout() {
      const layout = calculateNavigationLayout({
        windowInfo: getWindowInfo(),
        deviceInfo: getDeviceInfo(),
        menuRect: getMenuRect()
      })
      const safeAreaTop = layout.topInset
        ? `height: calc(var(--height) + ${layout.topInset}px); padding-top: ${layout.topInset}px`
        : ''
      this.setData({
        ios: !layout.isAndroid,
        desktop: layout.isDesktop,
        innerPaddingRight: `padding-right: ${layout.edgeWidth}px`,
        leftWidth: `width: ${layout.edgeWidth}px`,
        safeAreaTop
      })
    },
    _showChange(show) {
      const animated = this.data.animated
      let displayStyle = ''
      if (animated) {
        displayStyle = `opacity: ${show ? '1' : '0'
          };transition:opacity 0.5s;`
      } else {
        displayStyle = `display: ${show ? '' : 'none'}`
      }
      this.setData({
        displayStyle
      })
    },
    back() {
      const data = this.data
      if (data.externalBack) {
        this.triggerEvent('back', { delta: data.delta }, {})
        return
      }
      const delta = Math.max(1, Number(data.delta) || 1)
      const pages = typeof getCurrentPages === 'function' ? getCurrentPages() : []
      if (data.delta && pages.length > delta) {
        wx.navigateBack({
          delta,
          fail: () => this._goHome()
        })
      } else if (data.delta) {
        this._goHome()
      }
      this.triggerEvent('back', { delta: data.delta }, {})
    },
    home() {
      this._goHome()
    },
    _goHome() {
      if (typeof wx.reLaunch === 'function') {
        wx.reLaunch({ url: HOME_PATH })
        return
      }
      wx.redirectTo({ url: HOME_PATH })
    }
  },
})
