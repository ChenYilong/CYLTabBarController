/**
 * [EN] Reports a page scroll to the lifecycle library, so `cylPausesAnimationsWhileUserScrolls(true)` (app.js) pauses the tab icon
 *      animations while the user scrolls and resumes them 150 ms after the last scroll event.
 * [CN] 把页面滚动报告给生命周期库，使 `cylPausesAnimationsWhileUserScrolls(true)`（app.js）在用户滚动时暂停 Tab 图标动画，
 *      并在最后一次滚动事件 150 毫秒后恢复。
 */
const { LifecycleController } = require('cyl-tabbar-miniprogram/cyl-dealloc-block-executor/index');

function cylPageScrolled(page, event) {
  page.cylScrollController = page.cylScrollController || new LifecycleController(page);
  page.cylScrollController.onPageScroll(event || {});
}

module.exports = { cylPageScrolled };
