/**
 * [EN] The teardown demo (iOS CYLDemoTeardown / CYLDemoReleaseRow, Android DemoTeardown, HarmonyOS DemoTeardown;
 *      docs/Lifecycle-Library.md, step 21): the Home row "Release the tab bar controller (in 3 s)" arms a dealloc callback on every
 *      loaded tab bar (the cyl-dealloc-block-executor port: `cylLifecycle.registry.addDeallocCallback`), counts down 3 s, then
 *      wx.reLaunch destroys the tab pages and their custom tab bars (`detached` runs the bars' teardown blocks). The released page
 *      shows "dealloc callbacks ran: N / M", the library's own evidence that the tab bars were released. State lives in this module,
 *      which outlives the pages.
 * [CN] 销毁演示（iOS 的 CYLDemoTeardown / CYLDemoReleaseRow、Android 与 HarmonyOS 的 DemoTeardown；docs/Lifecycle-Library.md，第 21 步）：
 *      首页行「Release the tab bar controller (in 3 s)」在每个已加载的 TabBar 上登记 dealloc 回调（cyl-dealloc-block-executor 的移植：
 *      `cylLifecycle.registry.addDeallocCallback`），倒计时 3 秒，然后 wx.reLaunch 销毁 Tab 页面及其自定义 TabBar（`detached` 运行 TabBar
 *      的销毁块）。释放后的页面显示「dealloc callbacks ran: N / M」，这是库本身给出的「TabBar 已释放」的证据。状态保存在本模块中，
 *      它的生命周期长于页面。
 */
const { t } = require('./cyl_demo_localization');

const CYL_TEARDOWN_KEY = 'cyl.demo.teardown';
const CYL_TEARDOWN_SECONDS = 3;

const state = { armed: [], ran: [], listeners: [], remaining: 0, timer: null };

/** [EN] `%d` and `%@` filled in order, as the iOS format strings. [CN] 按顺序填入 `%d` 与 `%@`，与 iOS 格式字符串相同。 */
function cylFill(text, values) {
  let index = 0;
  return text.replace(/%(\d+\$)?[d@]/g, (match, position) => {
    const value = values[position ? Number(position.slice(0, -1)) - 1 : index++];
    return value === undefined ? match : String(value);
  });
}

/** [EN] Registers a dealloc callback on a tab bar, named `name` in the report; false when it has no lifecycle. [CN] 在 TabBar 上登记 dealloc 回调，报告中名为 `name`；没有生命周期时返回 false。 */
function cylArm(bar, name) {
  const lifecycle = bar ? bar.cylLifecycle : null;
  if (!lifecycle || lifecycle.isDetached) {
    return false;
  }
  state.armed.push(name);
  lifecycle.registry.addDeallocCallback(() => cylRecord(name), { key: CYL_TEARDOWN_KEY });
  return true;
}

/** [EN] A dealloc callback ran. [CN] 一个 dealloc 回调已执行。 */
function cylRecord(name) {
  state.ran.push(name);
  state.listeners.slice().forEach((listener) => listener());
}

function cylReset() {
  clearInterval(state.timer);
  state.timer = null;
  state.armed = [];
  state.ran = [];
  state.remaining = 0;
}

function cylAddListener(listener) {
  state.listeners.push(listener);
}

function cylRemoveListener(listener) {
  state.listeners = state.listeners.filter((item) => item !== listener);
}

/** [EN] "dealloc callbacks ran: 1 / 1 (pages/home/index)". [CN] 「dealloc callbacks ran: 1 / 1 (pages/home/index)」。 */
function cylSummary() {
  return state.ran.length === 0
    ? cylFill(t('dealloc callbacks ran: %d / %d'), [state.ran.length, state.armed.length])
    : cylFill(t('dealloc callbacks ran: %d / %d (%@)'), [state.ran.length, state.armed.length, state.ran.join(', ')]);
}

/** [EN] The status line of the row. [CN] 该行的状态文字。 */
function cylStatus() {
  return state.remaining > 0 ? cylFill(t('teardown: releasing in %d s'), [state.remaining]) : t('teardown: not run');
}

/**
 * [EN] Starts the countdown: arms the bars (`bars`: [{ bar, name }]), calls `onTick` every second and `release` at zero. Does nothing while
 *      a countdown runs or when no bar could be armed.
 * [CN] 开始倒计时：登记各 TabBar（`bars`：[{ bar, name }]），每秒调用 `onTick`，到零时调用 `release`。倒计时进行中或没有 TabBar 可登记时不做任何事。
 */
function cylStart(bars, onTick, release) {
  if (state.remaining > 0) {
    return false;
  }
  cylReset();
  bars.forEach((entry) => cylArm(entry.bar, entry.name));
  if (state.armed.length === 0) {
    return false;
  }
  state.remaining = CYL_TEARDOWN_SECONDS;
  onTick();
  state.timer = setInterval(() => {
    state.remaining -= 1;
    if (state.remaining > 0) {
      onTick();
      return;
    }
    clearInterval(state.timer);
    state.timer = null;
    release();
  }, 1000);
  return true;
}

module.exports = {
  cylArm, cylRecord, cylReset, cylAddListener, cylRemoveListener, cylSummary, cylStatus, cylStart, cylFill,
  cylRemaining: () => state.remaining,
  cylArmedCount: () => state.armed.length,
  cylRanCount: () => state.ran.length,
};
