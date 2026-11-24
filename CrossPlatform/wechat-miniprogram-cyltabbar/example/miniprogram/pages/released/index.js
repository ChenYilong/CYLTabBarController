/**
 * [EN] What the mini program shows after the tab bars were released (iOS CYLDemoReleasedViewController): the dealloc callbacks that
 *      ran, refreshed as they run (utils/cyl_demo_teardown.js).
 * [CN] TabBar 被释放后小程序显示的内容（对应 iOS 的 CYLDemoReleasedViewController）：已执行的 dealloc 回调，随执行刷新。
 */
const { t } = require('../../utils/cyl_demo_localization');
const { cylSummary, cylAddListener, cylRemoveListener } = require('../../utils/cyl_demo_teardown');

Page({
  data: { text: '' },
  onLoad() {
    this.cylListener = () => this.cyl_refresh();
    cylAddListener(this.cylListener);
    this.cyl_refresh();
  },
  onUnload() {
    cylRemoveListener(this.cylListener);
  },
  cyl_refresh() {
    this.setData({ text: `${t('Tab bar controller released')}\n\n${cylSummary()}` });
  },
});
