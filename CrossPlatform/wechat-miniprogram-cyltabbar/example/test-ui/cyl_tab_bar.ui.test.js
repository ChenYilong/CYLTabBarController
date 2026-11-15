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
const CYL_CLI = require('../scripts/cyl_devtools_cli').cylDevtoolsCli();
// [EN] State changes reach the pages on the next turn of the app's event loop. [CN] 状态变化在 App 事件循环的下一轮到达页面。
const CYL_SETTLE_MS = 800;

let miniProgram;

const cylSleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * [EN] A screenshot of the simulator (base64 PNG). On a slow machine (seen on Windows) DevTools sometimes answers
 *      "timeout waiting for automator response" to one screenshot; try again up to twice.
 * [CN] 模拟器截图（base64 PNG）。在较慢的机器上（Windows 上出现过），开发者工具偶尔对某次截图返回
 *      "timeout waiting for automator response"；最多再试两次。
 */
async function cylCapture() {
  for (let attempt = 1; ; attempt += 1) {
    try {
      return await miniProgram.screenshot();
    } catch (error) {
      if (attempt >= 3 || !/timeout waiting for automator response/.test(String(error && error.message))) {
        throw error;
      }
    }
  }
}

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
 * [EN] Whether the bar's icons are animation components (Lottie, PAG, Rive: a canvas each); GIF icons are not.
 * [CN] TabBar 的图标是否为动画组件（Lottie、PAG、Rive：各有一个画布）；GIF 图标不是。
 */
function cylHasAnimationViews() {
  return miniProgram.evaluate(() => {
    const pages = getCurrentPages();
    const bar = pages[pages.length - 1].getTabBar().selectComponent('#cyl-tab-bar');
    return bar.selectAllComponents('.cyl-tab-item').some((item) => Boolean(item.selectComponent('#cyl-item-animation')));
  });
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
  // [EN] The launch badges animate forever and the cover hides Home: the tests compare icons, so they go first; test 12
  //      checks them. [CN] 启动角标一直播放动画，封面遮住首页：测试比较图标，因此先移除；第 12 项测试检查它们。
  await cylClearDecoration();
});

/**
 * [EN] Removes the launch badges and the cover (app.js cyl_decorateTabBar) from every bar.
 * [CN] 从所有 TabBar 移除启动角标与封面（app.js cyl_decorateTabBar）。
 */
async function cylClearDecoration() {
  await miniProgram.evaluate(() => new Promise((resolve) => {
    // [EN] After the launch timer (1.5 s), so it does not put them back. [CN] 在启动计时器（1.5 秒）之后，避免其重新添加。
    setTimeout(() => {
      clearTimeout(getApp().cylDecorateTimer);
      // [EN] The skin is kept across launches: back to Default. [CN] 皮肤在重新启动后保留：恢复默认。
      getApp().cyl_setSkin('Default');
      clearTimeout(getApp().cylCoverTimer);
      getApp().cyl_updateTabBarState({
        badges: { home: '', city: '', message: '', CYLMineViewController: '', plus: '' },
        badgeAttributes: {},
        covers: { home: null },
      });
      resolve();
    }, 0);
  }));
  await cylSleep(CYL_SETTLE_MS);
}

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
  assert.deepEqual(bar.slots.filter((slot) => !slot.isPlusButton).map((slot) => slot.key), ['home', 'city', 'message', 'CYLMineViewController']);
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
        // [EN] DevTools: one layer, the image of the canvas, also while playing. [CN] 开发者工具：只有一个图层（画布的图片），播放时也一样。
        snapshots: bar.selectAllComponents('.cyl-tab-item').map((item) => {
          const view = item.selectComponent('#cyl-item-animation');
          // [EN] GIF icons are <image>s: no canvas, so no second layer. [CN] GIF 图标是 <image>：没有画布，因此不会有第二个图层。
          return view ? Boolean(view.data.cylCovered && view.data.cylSnapshot) : true;
        }),
      }), 300);
    }, 0);
  }));
  assert.deepEqual(result, { speed: 2, loop: true, snapshots: [true, true, true, true] });
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

test('the animated icons stay in the bar during and after a page scroll (WeChat DevTools)', async (t) => {
  if (!(await cylHasAnimationViews())) {
    t.skip('the icons are <image>s (GIF): no canvas');
    return;
  }
  await miniProgram.switchTab('/pages/me/index');
  await cylSleep(CYL_SETTLE_MS * 4);
  const layout = await miniProgram.evaluate(() => new Promise((resolve) => {
    const pages = getCurrentPages();
    const bar = pages[pages.length - 1].getTabBar().selectComponent('#cyl-tab-bar');
    bar.createSelectorQuery().selectAll('.cyl-tab-item >>> .cyl-item-icon-box').boundingClientRect()
      .select('.cyl-tab-bar').boundingClientRect()
      .exec((result) => resolve({
        windowWidth: wx.getWindowInfo().windowWidth,
        // [EN] Me has the system navigation bar. After a page with a custom one (Home), DevTools reports the window as the
        //      whole screen, so the window starts below the status bar and the 44 pt navigation bar. [CN] Me 使用系统导航栏。打开过自定义导航栏的页面（首页）
        //      之后，开发者工具把窗口报告为整个屏幕，因此窗口从状态栏与 44pt 导航栏下方开始。
        windowTop: wx.getWindowInfo().screenHeight - wx.getWindowInfo().windowHeight
          || (wx.getWindowInfo().statusBarHeight + 44),
        icons: (result[0] || []).map((rect) => ({ left: rect.left, top: rect.top, width: rect.width, height: rect.height })),
        // [EN] The whole bar: a second layer of icons anywhere in it changes it. [CN] 整个 TabBar：其中任何位置出现第二层图标都会改变它。
        bar: result[1] && { left: result[1].left, top: result[1].top, width: result[1].width, height: result[1].height },
      }));
  }));
  assert.ok(layout.icons.length >= 4, 'icon boxes');
  assert.ok(layout.bar, 'the bar');
  const areas = layout.icons.map((rect, index) => ({ name: `icon ${index}`, rect })).concat([{ name: 'the bar', rect: layout.bar }]);
  const snapshots = await miniProgram.evaluate(() => {
    const pages = getCurrentPages();
    const bar = pages[pages.length - 1].getTabBar().selectComponent('#cyl-tab-bar');
    return bar.selectAllComponents('.cyl-tab-item').map((item) => {
      const view = item.selectComponent('#cyl-item-animation');
      return Boolean(view && view.data.cylCovered && view.data.cylSnapshot);
    });
  });
  assert.deepEqual(snapshots, [true, true, true, true], 'each icon is one image layer');
  // [EN] From the top: the Me page keeps its scroll position, and the page shows through the glass rim. [CN] 从顶部开始：Me 页面会保留滚动位置，且页面内容会透过玻璃边缘显示。
  await miniProgram.pageScrollTo(0);
  await cylSleep(CYL_SETTLE_MS * 1.5);
  const before = await cylCapture();
  if (process.env.CYL_UI_SCREENSHOTS) {
    require('node:fs').writeFileSync(path.join(process.env.CYL_UI_SCREENSHOTS, 'cyl-scroll-before.png'), Buffer.from(before, 'base64'));
  }
  for (const top of [300, 1380]) {
    await miniProgram.pageScrollTo(top);
    await cylSleep(CYL_SETTLE_MS * 1.5);
    const after = await cylCapture();
    if (process.env.CYL_UI_SCREENSHOTS) {
      require('node:fs').writeFileSync(path.join(process.env.CYL_UI_SCREENSHOTS, `cyl-scroll-${top}.png`), Buffer.from(after, 'base64'));
    }
    areas.forEach(({ name, rect }) => {
      const difference = cylDifference(before, after, rect, layout.windowWidth, layout.windowTop);
      assert.ok(difference < 0.02, `${name} after a scroll to ${top}: ${(difference * 100).toFixed(1)}% of its pixels changed`);
    });
  }
  // [EN] During an animated scroll too: in DevTools each icon is one image layer (CYL_USES_SNAPSHOTS).
  // [CN] 动画滚动期间也一样：开发者工具中每个图标只有一个图片图层（CYL_USES_SNAPSHOTS）。
  await miniProgram.evaluate(() => { wx.pageScrollTo({ scrollTop: 0, duration: 3000 }); });
  await cylSleep(1200);
  const during = await cylCapture();
  if (process.env.CYL_UI_SCREENSHOTS) {
    require('node:fs').writeFileSync(path.join(process.env.CYL_UI_SCREENSHOTS, 'cyl-scroll-during.png'), Buffer.from(during, 'base64'));
  }
  areas.forEach(({ name, rect }) => {
    const difference = cylDifference(before, during, rect, layout.windowWidth, layout.windowTop);
    assert.ok(difference < 0.02, `${name} during a scroll: ${(difference * 100).toFixed(1)}% of its pixels changed`);
  });
  await cylSleep(2000);
  await miniProgram.pageScrollTo(0);
  await miniProgram.switchTab('/pages/home/index');
  await cylSleep(CYL_SETTLE_MS);
});

/**
 * [EN] For each animated icon of the current page's bar: whether it is one image layer, and that image (DevTools).
 * [CN] 当前页面 TabBar 的每个动画图标：是否只有一个图片图层，以及该图片（开发者工具）。
 */
function cylIconLayers() {
  return miniProgram.evaluate(() => {
    const pages = getCurrentPages();
    const bar = pages[pages.length - 1].getTabBar().selectComponent('#cyl-tab-bar');
    return bar.selectAllComponents('.cyl-tab-item').map((item) => {
      const view = item.selectComponent('#cyl-item-animation');
      return { oneLayer: Boolean(view.data.cylCovered && view.data.cylSnapshot), image: view.data.cylSnapshot };
    });
  });
}

test('looping icons stay one layer and keep playing during a page scroll (WeChat DevTools)', async (t) => {
  if (!(await cylHasAnimationViews())) {
    t.skip('the icons are <image>s (GIF): no canvas');
    return;
  }
  await miniProgram.switchTab('/pages/me/index');
  await cylSleep(CYL_SETTLE_MS * 2);
  await miniProgram.evaluate(() => {
    const pages = getCurrentPages();
    const bar = pages[pages.length - 1].getTabBar().selectComponent('#cyl-tab-bar');
    bar.cyl_setAnimationLoop(true);
    bar.cyl_playAll();
  });
  try {
    await miniProgram.evaluate(() => { wx.pageScrollTo({ scrollTop: 1380, duration: 3000 }); });
    await cylSleep(800);
    const first = await cylIconLayers();
    await cylSleep(300);
    const second = await cylIconLayers();
    assert.deepEqual(first.map((icon) => icon.oneLayer), [true, true, true, true], 'one image layer per icon while scrolling');
    assert.ok(first.some((icon, index) => icon.image !== second[index].image), 'the images follow the animation while scrolling');
  } finally {
    await miniProgram.evaluate(() => {
      const pages = getCurrentPages();
      pages[pages.length - 1].getTabBar().selectComponent('#cyl-tab-bar').cyl_setAnimationLoop(false);
    });
    await cylSleep(2500);
    await miniProgram.pageScrollTo(0);
    await miniProgram.switchTab('/pages/home/index');
    await cylSleep(CYL_SETTLE_MS * 2);
  }
});

test('hiddenIdentifiers leaves a tab out of every bar, and tabBarHidden hides one page\'s bar', async () => {
  try {
    await cylSetState({ hiddenIdentifiers: ['city'] });
    let bar = await cylTabBar();
    assert.deepEqual(bar.slots.filter((slot) => !slot.isPlusButton).map((slot) => slot.key), ['home', 'message', 'CYLMineViewController']);
    assert.equal(bar.slots.filter((slot) => slot.isPlusButton).length, 1, 'the plus button stays');
    assert.deepEqual(bar.slots.filter((slot) => slot.selected).map((slot) => slot.key), ['home']);
    // [EN] A hidden selected tab falls back to the first shown one. [CN] 被隐藏的选中 Tab 回退到第一个显示的 Tab。
    await cylSetState({ hiddenIdentifiers: ['home'] });
    bar = await cylTabBar();
    assert.deepEqual(bar.slots.filter((slot) => slot.selected).map((slot) => slot.key), ['city']);
    await cylSetState({ hiddenIdentifiers: [] });
    bar = await cylTabBar();
    assert.deepEqual(bar.slots.filter((slot) => !slot.isPlusButton).map((slot) => slot.key), ['home', 'city', 'message', 'CYLMineViewController']);

    const cylBarHeight = (hidden) => miniProgram.evaluate((value) => new Promise((resolve) => {
      const pages = getCurrentPages();
      const tabBar = pages[pages.length - 1].getTabBar();
      tabBar.cyl_setTabBarHidden(value);
      setTimeout(() => {
        tabBar.selectComponent('#cyl-tab-bar').createSelectorQuery().select('.cyl-tab-bar').boundingClientRect()
          .exec((result) => resolve(result[0] ? result[0].height : -1));
      }, 300);
    }), hidden);
    assert.equal(await cylBarHeight(true), 0, 'the hidden bar takes no space');
    assert.ok(await cylBarHeight(false) >= 49, 'the bar is back');
  } finally {
    await cylSetState({ hiddenIdentifiers: [] });
  }
});

test('the Home feed scrolls under the bar with one layer of icons (flat style, dark skin; the report of 2026-11-14)', async (t) => {
  if (!(await cylHasAnimationViews())) {
    // [EN] A GIF icon is an <image> that animates by itself: two frames of it differ whatever the bar does, and there is
    //      no canvas to leave behind. [CN] GIF 图标是自己会动的 <image>：无论 TabBar 如何，两帧本身就不同，也没有会被留下的画布。
    t.skip('the icons are <image>s (GIF): no canvas, and they animate by themselves');
    return;
  }
  // [EN] The user's case: the feed page (pages/home), the flat item style, the dark skin; the whole bar and the strip under
  //      it (the safe area) must look the same during the scroll as at rest, where the page stops at the same position.
  // [CN] 用户的场景：信息流页面（pages/home）、扁平 Item 样式、深色皮肤；滚动期间整个 TabBar 及其下方的条带（安全区）
  //      必须与页面在同一位置静止时一样。
  try {
    await miniProgram.switchTab('/pages/home/index');
    await cylSetState({ itemStyle: 'flat', themeIdentifier: 'dark' });
    const layout = await miniProgram.evaluate(() => new Promise((resolve) => {
      const pages = getCurrentPages();
      const bar = pages[pages.length - 1].getTabBar().selectComponent('#cyl-tab-bar');
      bar.createSelectorQuery().select('.cyl-tab-bar').boundingClientRect()
        .selectAll('.cyl-tab-item >>> .cyl-item-icon-box').boundingClientRect()
        .exec((result) => {
          const info = wx.getWindowInfo();
          resolve({
            windowWidth: info.windowWidth,
            windowTop: info.screenHeight - info.windowHeight,
            windowHeight: info.windowHeight,
            barTop: result[0].top,
            icons: (result[1] || []).map((rect) => ({ left: rect.left, top: rect.top, width: rect.width, height: rect.height })),
          });
        });
    }));
    // [EN] The whole bar and its strip (under 0.6%: thin icon strokes change little of it; a fake ghost layer made 1.1%, real runs 0.2%) and every icon box (under 2%).
    // [CN] 整个 TabBar 及其下方条带（低于 0.6%：细线条图标只占其很小一部分；模拟的第二图层为 1.1%，真实运行为 0.2%）与每个图标区域（低于 2%）。
    const area = { left: 0, top: layout.barTop, width: layout.windowWidth, height: layout.windowHeight - layout.barTop };
    assert.ok(layout.icons.length >= 4, 'icon boxes');
    const cylCompare = (first, second, label) => {
      const bar = cylDifference(first, second, area, layout.windowWidth, layout.windowTop);
      assert.ok(bar < 0.006, `the bar differs ${label}: ${(bar * 100).toFixed(2)}% of its pixels`);
      layout.icons.forEach((rect, index) => {
        const icon = cylDifference(first, second, rect, layout.windowWidth, layout.windowTop);
        assert.ok(icon < 0.02, `icon ${index} differs ${label}: ${(icon * 100).toFixed(1)}% of its pixels`);
      });
    };
    // [EN] Jumps first (wx.pageScrollTo without a duration): the case where DevTools left the canvases of the icons behind. The
    //      dark bar is opaque, so it looks the same at every scroll position.
    // [CN] 先做跳转（不带 duration 的 wx.pageScrollTo）：开发者工具把图标画布留在原处的情形。深色 TabBar 不透明，
    //      因此在任何滚动位置看起来都一样。
    await cylSleep(1500);
    const baseline = await cylCapture();
    for (const jump of [300, 1380, 700]) {
      await miniProgram.pageScrollTo(jump);
      await cylSleep(900);
      cylCompare(baseline, await cylCapture(), `from its look at the top after a jump to ${jump}`);
    }
    await miniProgram.pageScrollTo(0);
    await cylSleep(900);
    for (const target of [1500, 0]) {
      await miniProgram.evaluate((top) => { wx.pageScrollTo({ scrollTop: top, duration: 3000 }); }, target);
      const frames = [];
      for (let index = 0; index < 5; index += 1) {
        await cylSleep(450);
        frames.push(await cylCapture());
      }
      await cylSleep(2200);
      const rest = await cylCapture();
      frames.forEach((frame, index) => cylCompare(frame, rest, `from its resting look in frame ${index} of the scroll to ${target}`));
    }
  } finally {
    await miniProgram.pageScrollTo(0);
    await cylSetState({ itemStyle: '', themeIdentifier: '' });
  }
});

/**
 * [EN] The current page: the page object, its route and its data. [CN] 当前页面：页面对象、路由与数据。
 */
async function cylCurrentPage() {
  const page = await miniProgram.currentPage();
  return { page, route: page.path, data: await page.data() };
}

/**
 * [EN] Taps the element `selector` of the current page and waits. [CN] 点击当前页面的 `selector` 元素并等待。
 */
async function cylTapElement(selector, wait = CYL_SETTLE_MS) {
  const { page } = await cylCurrentPage();
  const element = await page.$(selector);
  assert.ok(element, `no element ${selector}`);
  await element.tap();
  await cylSleep(wait);
}

test('the cells of the example act on tap (the request of 2026-11-15)', async () => {
  await miniProgram.reLaunch('/pages/home/index');
  await cylSleep(CYL_SETTLE_MS * 2);
  const barTitles = () => miniProgram.evaluate(() => {
    const pages = getCurrentPages();
    return pages[pages.length - 1].getTabBar().selectComponent('#cyl-tab-bar').data.cylSlots
      .map((slot) => (slot.item ? slot.item.title : slot.title));
  });
  const state = () => miniProgram.evaluate(() => getApp().globalData.cylTabBarState);

  // [EN] A direct action: the title of the first tab changes, then comes back. [CN] 直接行为：第一个 Tab 的标题改变后恢复。
  // [EN] "Purchased courses", as UIViewController+CYLTabBarItemUpdate.swift. [CN] 「已购课程」，与 iOS 相同。
  await cylTapElement('.cyl-home-row[data-id="changeTabTitle"]');
  assert.match((await barTitles())[0], /Purchased courses|已购课程|已購課程/);
  await cylTapElement('.cyl-home-row[data-id="changeTabTitle"]');
  assert.doesNotMatch((await barTitles())[0], /Purchased courses|已购课程|已購課程/);

  // [EN] Show / hide the bar. [CN] 显示 / 隐藏 TabBar。
  await cylTapElement('.cyl-home-row[data-id="flatShowHide"]');
  assert.equal((await state()).tabBarHidden, true);
  await cylTapElement('.cyl-home-row[data-id="flatShowHide"]');
  assert.equal((await state()).tabBarHidden, false);

  // [EN] A badge row, as CYLHomeViewController: pushes an orange page without navigation bar. [CN] 角标行，与 CYLHomeViewController 相同：push 无导航栏的橙色页面。
  await cylTapElement('.cyl-home-row[data-index="2"]', CYL_SETTLE_MS * 2);
  assert.equal((await cylCurrentPage()).route, 'pages/pushed/index');
  await miniProgram.navigateBack();
  await cylSleep(CYL_SETTLE_MS);

  // [EN] Configuration-file rows open the demo page with the core's result. [CN] 配置文件行打开演示页，显示核心层的结果。
  await cylTapElement('.cyl-home-row[data-id="configurationA13"]', CYL_SETTLE_MS * 2);
  let current = await cylCurrentPage();
  assert.equal(current.route, 'pages/demo/index');
  assert.match(current.data.result, /JSON/);
  await miniProgram.navigateBack();
  await cylSleep(CYL_SETTLE_MS);
  await cylTapElement('.cyl-home-row[data-id="configurationB12"]', CYL_SETTLE_MS * 2);
  current = await cylCurrentPage();
  assert.match(current.data.result, /3 /);
  assert.ok(await current.page.$('#cyl-demo-tab-bar'), 'the demo page draws a live bar');
  await miniProgram.navigateBack();
  await cylSleep(CYL_SETTLE_MS);

  // [EN] Gallery feed: a post opens its page; like it and comment. [CN] 画廊信息流：帖子打开详情页；点赞与评论。
  await miniProgram.navigateTo('/pages/glass/index');
  await cylSleep(CYL_SETTLE_MS * 2);
  await miniProgram.evaluate(() => {
    const pages = getCurrentPages();
    pages[pages.length - 1].cyl_showPanel('feed');
  });
  await cylSleep(CYL_SETTLE_MS * 2);
  await cylTapElement('.cyl-glass-post', CYL_SETTLE_MS * 2);
  current = await cylCurrentPage();
  assert.equal(current.route, 'pages/post/index');
  const likes = current.data.likes;
  await cylTapElement('#cyl-post-like');
  assert.equal((await current.page.data()).likes, likes + 1);
  await current.page.setData({ draft: 'Nice' });
  await cylTapElement('.cyl-post-send');
  const comments = (await current.page.data()).comments;
  assert.equal(comments[comments.length - 1].text, 'Nice');
  await miniProgram.reLaunch('/pages/home/index');
  await cylSleep(CYL_SETTLE_MS);
});

/**
 * [EN] With CYL_SCREENSHOT_DIR set, saves a screenshot of the simulator there (for docs/assets).
 * [CN] 设置 CYL_SCREENSHOT_DIR 时，把模拟器截图保存到该目录（供 docs/assets 使用）。
 */
async function cylScreenshot(name) {
  if (process.env.CYL_SCREENSHOT_DIR) {
    await miniProgram.screenshot({ path: path.join(process.env.CYL_SCREENSHOT_DIR, `${name}.png`) });
  }
}

test('the feeds of Message, Discover and Me act as on iOS (the request of 2026-11-15)', async () => {
  // [EN] Message row 1 (#202): a pushed tab bar whose plus button has a tappable X. [CN] 消息第 1 行（#202）：push 的 TabBar，PlusButton 带可点击的 X。
  await miniProgram.reLaunch('/pages/message/index');
  await cylSleep(CYL_SETTLE_MS * 2);
  await cylTapElement('.cyl-feed-row[data-index="1"]', CYL_SETTLE_MS * 2);
  let current = await cylCurrentPage();
  assert.equal(current.route, 'pages/pushed/index');
  assert.equal(current.data.bar, 'close');
  assert.ok(await current.page.$('#cyl-pushed-tab-bar'), 'a live tab bar');
  const before = current.data.closeColor;
  await cylTapElement('#cyl-pushed-close');
  assert.notEqual((await current.page.data()).closeColor, before);
  await cylScreenshot('1-message-close-plus');
  // [EN] Discover: the details page; a tap goes to Me and pushes the red page. [CN] 发现：详情页；点击跳到「我的」并 push 红色页面。
  await miniProgram.reLaunch('/pages/web/index');
  await cylSleep(CYL_SETTLE_MS * 2);
  await cylTapElement('.cyl-feed-row[data-index="0"]', CYL_SETTLE_MS * 2);
  current = await cylCurrentPage();
  assert.equal(current.route, 'pages/pushed/locked');
  assert.equal(current.data.toMe, true);
  await cylScreenshot('2-discover-details');
  await cylTapElement('.cyl-pushed', CYL_SETTLE_MS * 3);
  current = await cylCurrentPage();
  assert.equal(current.route, 'pages/pushed/locked');
  assert.equal(current.data.color, '#FF3B30');
  // [EN] Me: the row number becomes Me's badge. [CN] 我的：行号成为「我的」的角标。
  await miniProgram.reLaunch('/pages/me/index');
  await cylSleep(CYL_SETTLE_MS * 2);
  await miniProgram.pageScrollTo(4000);
  await cylSleep(CYL_SETTLE_MS);
  await cylScreenshot('3-me-feed');
  await cylTapElement('.cyl-feed-row[data-index="5"]', CYL_SETTLE_MS * 2);
  assert.equal((await miniProgram.evaluate(() => getApp().globalData.cylTabBarState)).badges.me, '5');
  assert.equal((await cylCurrentPage()).route, 'pages/pushed/locked');
  await miniProgram.evaluate(() => getApp().cyl_updateTabBarState({ badges: {} }));
  await miniProgram.reLaunch('/pages/home/index');
  await cylSleep(CYL_SETTLE_MS);
});

test('the tabs and the launch sequence match the Objective-C example (docs/ObjC-Example-Parity items 1-6, 29, 55)', async () => {
  await miniProgram.reLaunch('/pages/home/index');
  await cylSleep(CYL_SETTLE_MS);
  await cylSetState({ itemStyle: '', loggedIn: true });
  // [EN] -[MainTabBarController cyl_demo_decorateTabBarController:] runs 1.5 s after launch; run it again here.
  // [CN] 启动 1.5 秒后执行；这里再执行一次。
  await miniProgram.evaluate(() => { getApp().cyl_decorateTabBar(); });
  await cylSleep(1500 + CYL_SETTLE_MS * 2);
  const bar = () => miniProgram.evaluate(() => {
    const pages = getCurrentPages();
    const tabBar = pages[pages.length - 1].getTabBar().selectComponent('#cyl-tab-bar');
    return {
      styleType: tabBar.data.cylStyleType,
      slots: tabBar.data.cylSlots.map((slot) => ({
        key: slot.key,
        selected: Boolean(slot.selected),
        title: slot.item ? slot.item.title : slot.title,
        badge: slot.isPlusButton ? (slot.badge && slot.badge.text) : (slot.showsDot ? '•' : slot.badge),
        badgeItem: slot.badgeItem || null,
        plusBadgeClass: slot.isPlusButton && slot.badge ? slot.badge.className : '',
        cover: Boolean(slot.cover),
      })),
    };
  });
  let state = await bar();
  assert.equal(state.styleType, 'liquidGlass', 'starts on Liquid Glass');
  const byKey = (key) => state.slots.find((slot) => slot.key === key);
  assert.deepEqual(state.slots.map((slot) => slot.key), ['home', 'city', 'plus', 'message', 'CYLMineViewController']);
  assert.deepEqual(state.slots.map((slot) => slot.title), ['Refresh', 'Nearby', 'Post', 'Messages', 'Me']);
  assert.equal(byKey('home').badge, '•');
  assert.equal(byKey('home').badgeItem.animation, 'breathe');
  assert.equal(byKey('home').badgeItem.size, '{11, 11}');
  assert.equal(byKey('home').cover, true, 'the cover over Home');
  assert.equal(byKey('city').badge, '8');
  assert.deepEqual([byKey('city').badgeItem.color, byKey('city').badgeItem.animation], ['#AF52DE', 'scale']);
  assert.deepEqual([byKey('message').badge, byKey('message').badgeItem.animation], ['99+', 'bounce']);
  assert.deepEqual([byKey('CYLMineViewController').badge, byKey('CYLMineViewController').badgeItem.positionAdjustment],
    ['NEW', '{-1, 3}']);
  assert.deepEqual([byKey('plus').badge, byKey('plus').plusBadgeClass], ['1', 'cyl-badge-bounce']);

  // [EN] Item 55: on Liquid Glass a tap that selects a tab turns its badge into a dot of the same color.
  // [CN] 第 55 项：液态玻璃下选中 Tab 的点击把其角标变为同色红点。
  await cylTap('city');
  state = await bar();
  assert.equal(byKey('city').selected, true);
  assert.deepEqual([byKey('city').badge, byKey('city').badgeItem.color], ['•', '#AF52DE']);

  // [EN] Item 29: Messages and Me need login; the tab stays unselected until the alert logs in.
  // [CN] 第 29 项：消息与我的需要登录；在弹窗登录之前该 Tab 不会被选中。
  await cylSetState({ loggedIn: false });
  await cylTap('message');
  state = await bar();
  assert.equal(byKey('message').selected, false, 'Messages needs login');
  await cylSetState({ loggedIn: true });
  await cylClearDecoration();
  await miniProgram.reLaunch('/pages/home/index');
  await cylSleep(CYL_SETTLE_MS);
});

test('the Home navigation bar and the skins match the Objective-C example (docs/ObjC-Example-Parity items 7, 8, 9, 15, 32)', async () => {
  await miniProgram.reLaunch('/pages/home/index');
  await cylSleep(CYL_SETTLE_MS * 2);
  const bar = () => miniProgram.evaluate(() => {
    const pages = getCurrentPages();
    const tabBar = pages[pages.length - 1].getTabBar().selectComponent('#cyl-tab-bar');
    return {
      styleType: tabBar.data.cylStyleType,
      items: tabBar.data.cylSlots.map((slot) => (slot.item ? { title: slot.item.title, image: slot.item.image, selectedImage: slot.item.selectedImage }
        : { title: slot.title, image: slot.image })),
    };
  });

  // [EN] Item 9: the Skin button opens the menu: 17 skins, the check on Default, then "Follow the system Dark Mode".
  // [CN] 第 9 项：换肤按钮打开菜单：17 个皮肤，勾号在默认上，然后是「跟随系统深色模式」。
  await cylTapElement('#cyl-nav-skin');
  let { data } = await cylCurrentPage();
  assert.equal(data.skinMenu.length, 18);
  assert.deepEqual(data.skinMenu.filter((row) => row.checked).map((row) => row.id), ['Default']);
  assert.equal(data.skinMenu[17].id, 'system');
  await cylTapElement('.cyl-menu-row[data-id="Christmas"]');
  ({ data } = await cylCurrentPage());
  assert.equal(data.skinMenu, null, 'a choice closes the menu');
  let state = await bar();
  // [EN] The holiday icons in turn (unselected faded), the last one on the plus button. [CN] 依次使用节日图标（未选中为半透明），最后一个用于 PlusButton。
  assert.match(state.items[1].image, /theme\/christmas\/wrapped_gift_faded\.png$/);
  assert.match(state.items[0].selectedImage, /theme\/christmas\/christmas_tree\.png$/);
  assert.match(state.items[2].image, /theme\/christmas\/star\.png$/);

  // [EN] Items 15 and 32: the skin row names the skin; the list has 17 rows with the check on the current one.
  // [CN] 第 15、32 项：换肤行显示当前皮肤；列表有 17 行，勾号在当前皮肤上。
  const skins = data.sections.find((section) => section.id === 'skins');
  assert.equal(skins.rows.length, 17);
  assert.deepEqual(skins.rows.filter((row) => row.accessory === 'check').map((row) => row.id), ['skin:Christmas']);
  const skinRow = data.sections.reduce((found, section) => found || (section.rows || []).find((row) => row.id === 'skin'), null);
  assert.match(skinRow.subtitle, /Christmas|圣诞节|聖誕節/);

  // [EN] The network skin: "★ " before the titles, icons from the network. [CN] 网络皮肤：标题前加「★ 」，图标来自网络。
  await miniProgram.evaluate(() => { getApp().cyl_setSkin('Network icons'); });
  await cylSleep(CYL_SETTLE_MS);
  state = await bar();
  assert.ok(state.items[1].title.startsWith('★ '), state.items[1].title);
  assert.match(state.items[1].image, /^https:\/\/cdn-icons-png\.flaticon\.com\//);

  // [EN] Item 7: Flat Design builds a new FlatDesign bar, its launch badges again; the skin stays.
  // [CN] 第 7 项：Flat Design 创建新的扁平样式 TabBar，再次出现启动角标；皮肤保持不变。
  await cylTapElement('#cyl-nav-flat', 1500 + CYL_SETTLE_MS * 2);
  state = await bar();
  assert.equal(state.styleType, 'flatDesign');
  assert.ok(state.items[1].title.startsWith('★ '), 'the skin stays');
  let app = await miniProgram.evaluate(() => getApp().globalData.cylTabBarState);
  assert.equal(app.badges.city, '8', 'the launch badges again');
  ({ data } = await cylCurrentPage());
  assert.ok(!/Liquid/.test(data.navigationTitle), 'no " (Liquid)" in FlatDesign');

  // [EN] Item 8: Liquid Glass builds a new Liquid Glass bar. [CN] 第 8 项：Liquid Glass 重新创建液态玻璃 TabBar。
  await cylTapElement('#cyl-nav-liquid', CYL_SETTLE_MS * 2);
  state = await bar();
  assert.equal(state.styleType, 'liquidGlass');
  ({ data } = await cylCurrentPage());
  assert.match(data.navigationTitle, /\(Liquid\)$/);

  // [EN] Following the system: Dark in Dark Mode. [CN] 跟随系统：深色模式下为 Dark。
  await miniProgram.evaluate(() => { getApp().cyl_updateTabBarState({ systemTheme: 'dark' }); getApp().cyl_setSkinFollowsSystem(true); });
  await cylSleep(CYL_SETTLE_MS);
  ({ data } = await cylCurrentPage());
  assert.deepEqual(data.sections.find((section) => section.id === 'skins').rows.filter((row) => row.accessory === 'check').map((row) => row.id), ['skin:Dark']);
  await miniProgram.evaluate(() => { getApp().cyl_setSkinFollowsSystem(false); getApp().cyl_updateTabBarState({ systemTheme: 'light' }); });
  app = await miniProgram.evaluate(() => getApp().globalData.cylTabBarState);
  assert.equal(app.skinFollowsSystem, false);
  await cylClearDecoration();
  await miniProgram.reLaunch('/pages/home/index');
  await cylSleep(CYL_SETTLE_MS);
});

test('the Home rows act with the Objective-C values (docs/ObjC-Example-Parity items 13, 14, 16, 19, 21-26, 28)', async () => {
  await miniProgram.reLaunch('/pages/home/index');
  await cylSleep(CYL_SETTLE_MS * 2);
  // [EN] A new tab bar: the rows start from the configuration's values. [CN] 新的 TabBar：各行从配置中的值开始。
  await miniProgram.evaluate(() => { getApp().cyl_rebuildTabBar('liquidGlass'); });
  await cylClearDecoration();
  const tap = (id, wait) => cylTapElement(`.cyl-home-row[data-id="${id}"]`, wait);
  const row = async (id) => {
    const { data } = await cylCurrentPage();
    return data.sections.reduce((found, section) => found || (section.rows || []).find((candidate) => candidate.id === id), null);
  };
  const bar = () => miniProgram.evaluate(() => {
    const pages = getCurrentPages();
    const tabBar = pages[pages.length - 1].getTabBar().selectComponent('#cyl-tab-bar');
    return {
      style: tabBar.data.cylBarStyle,
      slots: tabBar.data.cylSlots.map((slot) => ({
        key: slot.key,
        selected: Boolean(slot.selected),
        title: slot.item ? slot.item.title : slot.title,
        image: slot.item ? slot.item.image : slot.image,
      })),
    };
  });

  // [EN] Item 13: (0, -3.5) at launch, then 0, -4, 4. [CN] 第 13 项：启动时 (0, -3.5)，然后为 0、-4、4。
  assert.match((await row('titleOffset')).subtitle, /\(0, -3\.5\)/);
  for (const value of ['(0, 0)', '(0, -4)', '(0, 4)', '(0, 0)']) {
    await tap('titleOffset');
    assert.ok((await row('titleOffset')).subtitle.includes(value), value);
  }

  // [EN] Item 14: Original → Dark (#141414 bar) → Centered capsule → Green line (green top line) → Original.
  // [CN] 第 14 项：原始 → 深色（#141414）→ 居中胶囊 → 绿色描边（绿色顶部线）→ 原始。
  await tap('standardAppearance');
  assert.match((await bar()).style, /#141414/);
  await tap('standardAppearance');
  await tap('standardAppearance');
  assert.match((await bar()).style, /border-top-color: #34C759/);
  await tap('standardAppearance');
  assert.doesNotMatch((await bar()).style, /#141414|#34C759/);

  // [EN] Item 16: the four behaviors, by their code names. [CN] 第 16 项：四种行为，显示代码名。
  for (const name of ['OnScrollDown', 'OnScrollUp', 'Never', 'Automatic']) {
    await tap('scrollBehavior');
    assert.ok((await row('scrollBehavior')).subtitle.includes(name), name);
  }

  // [EN] Items 21-26: checkmarks while on, the slot rules, a second tap restores. [CN] 第 21–26 项：开启时带勾号，图标位置规则，再点恢复。
  await tap('downloadNetworkIcon');
  assert.equal((await row('downloadNetworkIcon')).accessory, 'check');
  assert.match((await bar()).slots[0].image, /3132\/31327(32|79)\.png$/);
  await tap('gifIcon');
  assert.equal((await row('downloadNetworkIcon')).accessory, 'none', 'one icon slot');
  assert.match((await bar()).slots[0].image, /cyl_tab_sample_animated\.gif$/);
  await tap('allNetworkIcons');
  assert.equal((await row('gifIcon')).accessory, 'none', 'all icons clear the single icon');
  assert.match((await bar()).slots[1].image, /2099\/2099085\.png$/);
  await tap('allLocalIcons');
  assert.equal((await row('allNetworkIcons')).accessory, 'none', 'network and local exclude each other');
  assert.match((await bar()).slots[0].image, /img_tab_home_[01]\.png$/);
  await tap('allLocalIcons');
  await tap('allTitles');
  assert.ok((await bar()).slots.filter((slot) => slot.key !== 'home').every((slot) => slot.title.startsWith('★ ')));
  await tap('allTitles');
  assert.ok((await bar()).slots.every((slot) => !slot.title.startsWith('★ ')));

  // [EN] Item 19: outside FlatDesign the row is dimmed and an alert explains it. [CN] 第 19 项：非扁平样式下该行变灰并弹窗说明。
  assert.equal((await row('flatBackground')).dimmed, true);

  // [EN] Item 28: the next tab without the plus button, wrapping after the last. [CN] 第 28 项：不含 PlusButton 的下一个 Tab，最后一个之后回到第一个。
  await cylSetState({ loggedIn: true });
  for (const key of ['city', 'message', 'CYLMineViewController']) {
    await miniProgram.switchTab('/pages/home/index');
    await cylSleep(CYL_SETTLE_MS);
    await miniProgram.evaluate((next) => {
      const pages = getCurrentPages();
      const tabs = ['home', 'city', 'message', 'CYLMineViewController'];
      // [EN] The custom tab bar passes the selection to cyl-tab-bar. [CN] 自定义 TabBar 把选中状态传给 cyl-tab-bar。
      pages[pages.length - 1].getTabBar().setData({ selectedIdentifier: tabs[tabs.indexOf(next) - 1] });
    }, key);
    await cylSleep(CYL_SETTLE_MS);
    await tap('selectedIndex', CYL_SETTLE_MS * 2);
    assert.equal((await cylCurrentPage()).route, { city: 'pages/web/index', message: 'pages/message/index', CYLMineViewController: 'pages/me/index' }[key]);
  }
  await miniProgram.switchTab('/pages/home/index');
  await cylSleep(CYL_SETTLE_MS);
  await miniProgram.evaluate(() => {
    const pages = getCurrentPages();
    pages[pages.length - 1].getTabBar().setData({ selectedIdentifier: 'CYLMineViewController' });
  });
  await cylSleep(CYL_SETTLE_MS);
  await tap('selectedIndex');
  assert.equal((await bar()).slots.find((slot) => slot.selected).key, 'home', 'wraps to the first tab');
  await miniProgram.evaluate(() => { getApp().cyl_rebuildTabBar('liquidGlass'); });
  await cylClearDecoration();
  await miniProgram.reLaunch('/pages/home/index');
  await cylSleep(CYL_SETTLE_MS);
});
