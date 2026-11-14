/**
 * [EN] UI tests of the example in WeChat DevTools, through miniprogram-automator. They drive the real simulator: the
 *      custom tab bar of the current page, its slots, tab switching, the item style and the glass lens look, the plus
 *      button title line, the playback controls and the animated icons during and after a page scroll. Run: `npm run test-ui` (DevTools installed, logged in, with
 *      "Settings > Security > Service port" on). CYL_DEVTOOLS_CLI overrides the DevTools command line tool;
 *      CYL_AUTOMATOR_WS connects to a DevTools already started with `cli auto --auto-port <port>`.
 * [CN] 通过 miniprogram-automator 在微信开发者工具中运行的示例 UI 测试。驱动真实模拟器：当前页面的自定义 TabBar、
 *      其各个位置、切换 Tab、Item 样式与玻璃镜片外观、PlusButton 标题行、播放控件以及页面滚动期间与之后的动画图标。运行：`npm run test-ui`（已安装并
 *      登录开发者工具，且开启「设置 > 安全 > 服务端口」）。CYL_DEVTOOLS_CLI 指定开发者工具命令行；CYL_AUTOMATOR_WS
 *      连接已用 `cli auto --auto-port <端口>` 启动的开发者工具。
 */
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const automator = require('miniprogram-automator');
const { PNG } = require('pngjs');
const pixelmatch = require('pixelmatch');

const CYL_PROJECT = path.resolve(__dirname, '..');
const CYL_CLI = process.env.CYL_DEVTOOLS_CLI || '/Applications/wechatwebdevtools.app/Contents/MacOS/cli';
// [EN] State changes reach the pages on the next turn of the app's event loop. [CN] 状态变化在 App 事件循环的下一轮到达页面。
const CYL_SETTLE_MS = 800;

let miniProgram;

const cylSleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * [EN] The render data of the current page's tab bar. [CN] 当前页面 TabBar 的渲染数据。
 */
function cylTabBar() {
  return miniProgram.evaluate(() => {
    const pages = getCurrentPages();
    const bar = pages[pages.length - 1].getTabBar().selectComponent('#cyl-tab-bar');
    return {
      route: pages[pages.length - 1].route,
      slots: bar.data.cylSlots.map((slot) => ({ key: slot.key, selected: Boolean(slot.selected), isPlusButton: Boolean(slot.isPlusButton) })),
      itemStyle: bar.data.cylItemStyle,
      styleType: bar.data.cylStyleType,
      glassLensStyle: bar.data.cylGlassLensStyle,
      animationSpeed: bar.data.animationSpeed,
      animationLoop: bar.data.animationLoop,
    };
  });
}

/**
 * [EN] Changes the example's tab bar state (app.js) and waits for the bars to follow it.
 * [CN] 修改示例的 TabBar 状态（app.js），并等待 TabBar 跟随。
 */
async function cylSetState(change) {
  await miniProgram.evaluate((value) => {
    setTimeout(() => getApp().cyl_updateTabBarState(value), 0);
  }, change);
  await cylSleep(CYL_SETTLE_MS);
}

/**
 * [EN] Taps a tab of the current page's bar, as a finger does (the bar's tap handler). [CN] 像手指一样点击当前页面 TabBar 的一个 Tab（TabBar 的点击处理）。
 */
async function cylTap(key) {
  await miniProgram.evaluate((identifier) => {
    setTimeout(() => {
      const pages = getCurrentPages();
      pages[pages.length - 1].getTabBar().selectComponent('#cyl-tab-bar')
        .cyl_onTap({ currentTarget: { dataset: { key: identifier } } });
    }, 0);
  }, key);
  await cylSleep(CYL_SETTLE_MS * 2);
}

/**
 * [EN] The vertical extent of every title on the bar, the plus button's included. [CN] TabBar 上每个标题（含 PlusButton 的）的纵向范围。
 */
function cylTitleRects() {
  return miniProgram.evaluate(() => new Promise((resolve) => {
    const pages = getCurrentPages();
    const bar = pages[pages.length - 1].getTabBar().selectComponent('#cyl-tab-bar');
    bar.createSelectorQuery()
      .selectAll('.cyl-plus-slot .cyl-title').boundingClientRect()
      .selectAll('.cyl-tab-item >>> .cyl-item-title').boundingClientRect()
      .exec((result) => resolve({
        plus: (result[0] || []).map((rect) => ({ top: rect.top, bottom: rect.bottom })),
        tabs: (result[1] || []).map((rect) => ({ top: rect.top, bottom: rect.bottom })),
      }));
  }));
}

before(async () => {
  miniProgram = process.env.CYL_AUTOMATOR_WS
    ? await automator.connect({ wsEndpoint: process.env.CYL_AUTOMATOR_WS })
    : await automator.launch({ cliPath: CYL_CLI, projectPath: CYL_PROJECT });
  await miniProgram.reLaunch('/pages/home/index');
  await cylSleep(CYL_SETTLE_MS * 2);
  await cylSetState({ loggedIn: true, itemStyle: '', glassLensStyle: 'regular' });
});

after(async () => {
  if (!miniProgram) {
    return;
  }
  await cylSetState({ loggedIn: false, itemStyle: '', glassLensStyle: 'regular' });
  await miniProgram.reLaunch('/pages/home/index');
  if (process.env.CYL_AUTOMATOR_WS) {
    miniProgram.disconnect();
  } else {
    await miniProgram.close();
  }
});

test('the bar has the four tabs and the plus button, Home selected', async () => {
  const bar = await cylTabBar();
  assert.equal(bar.route, 'pages/home/index');
  assert.deepEqual(bar.slots.filter((slot) => !slot.isPlusButton).map((slot) => slot.key), ['home', 'message', 'discover', 'me']);
  assert.equal(bar.slots.filter((slot) => slot.isPlusButton).length, 1);
  assert.deepEqual(bar.slots.filter((slot) => slot.selected).map((slot) => slot.key), ['home']);
});

test('a tap on a tab opens its page and selects it', async () => {
  await cylTap('message');
  let bar = await cylTabBar();
  assert.equal(bar.route, 'pages/message/index');
  assert.deepEqual(bar.slots.filter((slot) => slot.selected).map((slot) => slot.key), ['message']);
  await cylTap('home');
  bar = await cylTabBar();
  assert.equal(bar.route, 'pages/home/index');
});

test('the item style and the glass lens look follow the app state', async () => {
  await cylSetState({ itemStyle: 'liquidGlass', glassLensStyle: 'skeuomorphic' });
  let bar = await cylTabBar();
  assert.equal(bar.itemStyle, 'liquidGlass');
  assert.equal(bar.styleType, 'liquidGlass');
  assert.equal(bar.glassLensStyle, 'skeuomorphic');
  await cylSetState({ itemStyle: 'flat', glassLensStyle: 'regular' });
  bar = await cylTabBar();
  assert.equal(bar.itemStyle, 'flat');
  assert.equal(bar.glassLensStyle, 'regular');
});

test('the plus button title lines up with the tab titles (default and Liquid Glass)', async () => {
  for (const itemStyle of ['', 'liquidGlass']) {
    await cylSetState({ itemStyle });
    const rects = await cylTitleRects();
    assert.equal(rects.plus.length, 1, `plus title (${itemStyle || 'default'})`);
    assert.ok(rects.tabs.length >= 4, `tab titles (${itemStyle || 'default'})`);
    rects.tabs.forEach((tab) => {
      assert.ok(Math.abs(tab.top - rects.plus[0].top) <= 1, `top ${tab.top} vs plus ${rects.plus[0].top} (${itemStyle || 'default'})`);
      assert.ok(Math.abs(tab.bottom - rects.plus[0].bottom) <= 1, `bottom ${tab.bottom} vs plus ${rects.plus[0].bottom} (${itemStyle || 'default'})`);
    });
  }
  await cylSetState({ itemStyle: '' });
});

test('the playback controls reach the bar: speed, loop, Play all', async () => {
  const result = await miniProgram.evaluate(() => new Promise((resolve) => {
    setTimeout(() => {
      const pages = getCurrentPages();
      const bar = pages[pages.length - 1].getTabBar().selectComponent('#cyl-tab-bar');
      bar.cyl_setAnimationSpeed(2);
      bar.cyl_setAnimationLoop(true);
      bar.cyl_playAll();
      setTimeout(() => resolve({
        speed: bar.data.animationSpeed,
        loop: bar.data.animationLoop,
        // [EN] Playing icons show their canvas, not the still image. [CN] 播放中的图标显示画布，而不是静态图片。
        snapshots: bar.selectAllComponents('.cyl-tab-item').map((item) => Boolean(item.selectComponent('#cyl-item-animation').data.cylSnapshotShown)),
      }), 300);
    }, 0);
  }));
  assert.deepEqual(result, { speed: 2, loop: true, snapshots: [false, false, false, false] });
  const reset = await miniProgram.evaluate(() => {
    const pages = getCurrentPages();
    const bar = pages[pages.length - 1].getTabBar().selectComponent('#cyl-tab-bar');
    bar.cyl_setAnimationSpeed(1);
    bar.cyl_setAnimationLoop(false);
    return { speed: bar.data.animationSpeed, loop: bar.data.animationLoop };
  });
  assert.deepEqual(reset, { speed: 1, loop: false });
});

/**
 * [EN] The share of different pixels between two screenshots (base64 PNG) inside `rect` (in window points). A
 *      screenshot is the whole screen: the window starts `windowTop` points down, below the status and navigation bars.
 * [CN] 两张截图（base64 PNG）在 `rect`（窗口点坐标）内不同像素的比例。截图是整个屏幕：窗口从 `windowTop` 点处开始，
 *      位于状态栏与导航栏之下。
 */
function cylDifference(before, after, rect, windowWidth, windowTop) {
  const first = PNG.sync.read(Buffer.from(before, 'base64'));
  const second = PNG.sync.read(Buffer.from(after, 'base64'));
  const scale = first.width / windowWidth;
  const x = Math.round(rect.left * scale);
  const y = Math.round((rect.top + windowTop) * scale);
  const width = Math.round(rect.width * scale);
  const height = Math.round(rect.height * scale);
  const crop = (png) => {
    const out = new PNG({ width, height });
    PNG.bitblt(png, out, x, y, width, height, 0, 0);
    return out.data;
  };
  return pixelmatch(crop(first), crop(second), null, width, height, { threshold: 0.1 }) / (width * height);
}

test('the animated icons stay in the bar during and after a page scroll (WeChat DevTools)', async () => {
  await miniProgram.switchTab('/pages/me/index');
  await cylSleep(CYL_SETTLE_MS * 4);
  const layout = await miniProgram.evaluate(() => new Promise((resolve) => {
    const pages = getCurrentPages();
    const bar = pages[pages.length - 1].getTabBar().selectComponent('#cyl-tab-bar');
    bar.createSelectorQuery().selectAll('.cyl-tab-item >>> .cyl-item-icon-box').boundingClientRect()
      .exec((result) => resolve({
        windowWidth: wx.getWindowInfo().windowWidth,
        windowTop: wx.getWindowInfo().screenHeight - wx.getWindowInfo().windowHeight,
        icons: (result[0] || []).map((rect) => ({ left: rect.left, top: rect.top, width: rect.width, height: rect.height })),
      }));
  }));
  assert.ok(layout.icons.length >= 4, 'icon boxes');
  const snapshots = await miniProgram.evaluate(() => {
    const pages = getCurrentPages();
    const bar = pages[pages.length - 1].getTabBar().selectComponent('#cyl-tab-bar');
    return bar.selectAllComponents('.cyl-tab-item').map((item) => {
      const view = item.selectComponent('#cyl-item-animation');
      return Boolean(view && view.data.cylSnapshotShown);
    });
  });
  assert.deepEqual(snapshots, [true, true, true, true], 'idle icons show their still image');
  const before = await miniProgram.screenshot();
  for (const top of [300, 1380]) {
    await miniProgram.pageScrollTo(top);
    await cylSleep(CYL_SETTLE_MS * 1.5);
    const after = await miniProgram.screenshot();
    if (process.env.CYL_UI_SCREENSHOTS) {
      require('node:fs').writeFileSync(path.join(process.env.CYL_UI_SCREENSHOTS, `cyl-scroll-${top}.png`), Buffer.from(after, 'base64'));
    }
    layout.icons.forEach((rect, index) => {
      const difference = cylDifference(before, after, rect, layout.windowWidth, layout.windowTop);
      assert.ok(difference < 0.02, `icon ${index} after a scroll to ${top}: ${(difference * 100).toFixed(1)}% of its pixels changed`);
    });
  }
  // [EN] During an animated scroll too: idle icons are still images in DevTools (cyl-lottie CYL_USES_SNAPSHOTS).
  // [CN] 动画滚动期间也一样：开发者工具中空闲的图标是静态图片（cyl-lottie 的 CYL_USES_SNAPSHOTS）。
  await miniProgram.evaluate(() => { wx.pageScrollTo({ scrollTop: 0, duration: 3000 }); });
  await cylSleep(1200);
  const during = await miniProgram.screenshot();
  if (process.env.CYL_UI_SCREENSHOTS) {
    require('node:fs').writeFileSync(path.join(process.env.CYL_UI_SCREENSHOTS, 'cyl-scroll-during.png'), Buffer.from(during, 'base64'));
  }
  layout.icons.forEach((rect, index) => {
    const difference = cylDifference(before, during, rect, layout.windowWidth, layout.windowTop);
    assert.ok(difference < 0.02, `icon ${index} during a scroll: ${(difference * 100).toFixed(1)}% of its pixels changed`);
  });
  await cylSleep(2000);
  await miniProgram.pageScrollTo(0);
  await miniProgram.switchTab('/pages/home/index');
  await cylSleep(CYL_SETTLE_MS);
});

/**
 * [EN] Whether each animated icon of the current page's bar shows its still image (DevTools).
 * [CN] 当前页面 TabBar 的每个动画图标是否显示静态图片（开发者工具）。
 */
function cylSnapshotsShown() {
  return miniProgram.evaluate(() => {
    const pages = getCurrentPages();
    const bar = pages[pages.length - 1].getTabBar().selectComponent('#cyl-tab-bar');
    return bar.selectAllComponents('.cyl-tab-item').map((item) => Boolean(item.selectComponent('#cyl-item-animation').data.cylSnapshotShown));
  });
}

test('looping icons hold still during a page scroll and play again after it (WeChat DevTools)', async () => {
  await miniProgram.switchTab('/pages/me/index');
  await cylSleep(CYL_SETTLE_MS * 2);
  const layout = await miniProgram.evaluate(() => new Promise((resolve) => {
    const pages = getCurrentPages();
    const bar = pages[pages.length - 1].getTabBar().selectComponent('#cyl-tab-bar');
    bar.cyl_setAnimationLoop(true);
    bar.cyl_playAll();
    bar.createSelectorQuery().selectAll('.cyl-tab-item >>> .cyl-item-icon-box').boundingClientRect()
      .exec((result) => resolve({
        windowWidth: wx.getWindowInfo().windowWidth,
        windowTop: wx.getWindowInfo().screenHeight - wx.getWindowInfo().windowHeight,
        icons: (result[0] || []).map((rect) => ({ left: rect.left, top: rect.top, width: rect.width, height: rect.height })),
      }));
  }));
  try {
    await cylSleep(500);
    assert.deepEqual(await cylSnapshotsShown(), [false, false, false, false], 'looping icons play on their canvas');
    await miniProgram.evaluate(() => { wx.pageScrollTo({ scrollTop: 1380, duration: 3000 }); });
    await cylSleep(800);
    const first = await miniProgram.screenshot();
    const shown = await cylSnapshotsShown();
    await cylSleep(600);
    const second = await miniProgram.screenshot();
    assert.deepEqual(shown, [true, true, true, true], 'still images while the page scrolls');
    layout.icons.forEach((rect, index) => {
      const difference = cylDifference(first, second, rect, layout.windowWidth, layout.windowTop);
      assert.ok(difference < 0.02, `icon ${index} moved during the scroll: ${(difference * 100).toFixed(1)}% of its pixels changed`);
    });
    await cylSleep(2200);
    assert.deepEqual(await cylSnapshotsShown(), [false, false, false, false], 'the canvases come back after the scroll');
  } finally {
    await miniProgram.evaluate(() => {
      const pages = getCurrentPages();
      pages[pages.length - 1].getTabBar().selectComponent('#cyl-tab-bar').cyl_setAnimationLoop(false);
    });
    await miniProgram.pageScrollTo(0);
    await miniProgram.switchTab('/pages/home/index');
    await cylSleep(CYL_SETTLE_MS * 2);
  }
});
