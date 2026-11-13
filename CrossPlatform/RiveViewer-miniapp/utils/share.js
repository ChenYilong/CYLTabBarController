const SHARE_TITLE = 'Rive 预览台｜在微信中预览 Rive 动效'
const HOME_PATH = '/pages/index/index'
const TIMELINE_QUERY = 'shareLanding=1'
const FRIEND_SHARE_IMAGE = '/share-friend.png'
const TIMELINE_SHARE_IMAGE = '/share-timeline.png'
const SHARE_MENUS = ['shareAppMessage', 'shareTimeline']

function enableShareMenu() {
  if (typeof wx.showShareMenu !== 'function') return
  const options = {
    withShareTicket: false,
    ...(typeof wx.canIUse !== 'function' || wx.canIUse('showShareMenu.object.menus')
      ? { menus: SHARE_MENUS }
      : {}),
    fail(error) {
      console.warn('微信平台未开放当前小程序的分享权限', error)
    }
  }
  wx.showShareMenu(options)
}

function isShareLanding(options = {}) {
  return String(options.shareLanding || '') === '1'
}

function openShareLanding() {
  wx.reLaunch({ url: HOME_PATH })
}

module.exports = {
  enableShareMenu,
  FRIEND_SHARE_IMAGE,
  HOME_PATH,
  isShareLanding,
  openShareLanding,
  SHARE_TITLE,
  TIMELINE_SHARE_IMAGE,
  TIMELINE_QUERY
}
