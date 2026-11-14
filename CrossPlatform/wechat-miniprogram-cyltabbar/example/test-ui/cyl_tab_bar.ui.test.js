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
        windowTop: wx.getWindowInfo().screenHeight - wx.getWindowInfo().windowHeight,
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
  const before = await miniProgram.screenshot();
  for (const top of [300, 1380]) {
    await miniProgram.pageScrollTo(top);
    await cylSleep(CYL_SETTLE_MS * 1.5);
    const after = await miniProgram.screenshot();
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
  const during = await miniProgram.screenshot();
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
    await cylSetState({ hiddenIdentifiers: ['discover'] });
    let bar = await cylTabBar();
    assert.deepEqual(bar.slots.filter((slot) => !slot.isPlusButton).map((slot) => slot.key), ['home', 'message', 'me']);
    assert.equal(bar.slots.filter((slot) => slot.isPlusButton).length, 1, 'the plus button stays');
    assert.deepEqual(bar.slots.filter((slot) => slot.selected).map((slot) => slot.key), ['home']);
    // [EN] A hidden selected tab falls back to the first shown one. [CN] 被隐藏的选中 Tab 回退到第一个显示的 Tab。
    await cylSetState({ hiddenIdentifiers: ['home'] });
    bar = await cylTabBar();
    assert.deepEqual(bar.slots.filter((slot) => slot.selected).map((slot) => slot.key), ['message']);
    await cylSetState({ hiddenIdentifiers: [] });
    bar = await cylTabBar();
    assert.deepEqual(bar.slots.filter((slot) => !slot.isPlusButton).map((slot) => slot.key), ['home', 'message', 'discover', 'me']);

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
    const baseline = await miniProgram.screenshot();
    for (const jump of [300, 1380, 700]) {
      await miniProgram.pageScrollTo(jump);
      await cylSleep(900);
      cylCompare(baseline, await miniProgram.screenshot(), `from its look at the top after a jump to ${jump}`);
    }
    await miniProgram.pageScrollTo(0);
    await cylSleep(900);
    for (const target of [1500, 0]) {
      await miniProgram.evaluate((top) => { wx.pageScrollTo({ scrollTop: top, duration: 3000 }); }, target);
      const frames = [];
      for (let index = 0; index < 5; index += 1) {
        await cylSleep(450);
        frames.push(await miniProgram.screenshot());
      }
      await cylSleep(2200);
      const rest = await miniProgram.screenshot();
      frames.forEach((frame, index) => cylCompare(frame, rest, `from its resting look in frame ${index} of the scroll to ${target}`));
    }
  } finally {
    await miniProgram.pageScrollTo(0);
    await cylSetState({ itemStyle: '', themeIdentifier: '' });
  }
});
