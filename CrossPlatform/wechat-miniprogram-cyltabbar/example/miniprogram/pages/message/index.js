/**
 * [EN] Message: a tab page of the configuration. Its CYLTabBarItemPlatforms is "ios,android", so the bar leaves it out
 *      in the mini program; the page stays in app.json for configurations that show it.
 * [CN] 消息：配置中的一个 Tab 页面。它的 CYLTabBarItemPlatforms 为 "ios,android"，因此小程序中的 TabBar 不显示它；
 *      页面保留在 app.json 中，供显示它的配置使用。
 */
const cylTabPage = require('../../utils/cyl_tab_page');

Component({ behaviors: [cylTabPage] });
