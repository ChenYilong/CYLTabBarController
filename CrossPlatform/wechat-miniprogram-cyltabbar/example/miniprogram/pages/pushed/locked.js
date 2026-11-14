/**
 * [EN] A page pushed from a tab's feed; see utils/cyl_pushed_page.js. [CN] 从 Tab 信息流 push 的页面；见 utils/cyl_pushed_page.js。
 */
const { cylPushedPage } = require('../../utils/cyl_pushed_page');

Page(cylPushedPage());
