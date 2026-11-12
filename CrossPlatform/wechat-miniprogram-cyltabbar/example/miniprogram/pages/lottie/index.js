/**
 * [EN] The cyl-lottie playground: the component of cyl-lottie-miniprogram (a sub-dependency of
 *      cyl-tabbar-miniprogram) with its properties, methods and events.
 * [CN] cyl-lottie 演示页：cyl-lottie-miniprogram（cyl-tabbar-miniprogram 的子依赖）的组件，以及它的属性、方法与事件。
 */
const { t } = require('../../utils/cyl_demo_localization');
const cylDemoStrings = require('../../utils/cyl_demo_strings');

const { cylAvailablePAGFiles } = require('../../utils/cyl_demo_configuration');

const CYL_FILES = ['green_lottie_tab_home', 'green_lottie_tab_discover', 'green_lottie_tab_mine'];

Page({
  data: {
    texts: {},
    files: CYL_FILES,
    file: CYL_FILES[0],
    path: `/shared/lottie/${CYL_FILES[0]}.json`,
    loop: true,
    speed: 1,
    speeds: [0.5, 1, 2],
    fit: 'contain',
    fits: ['contain', 'cover', 'fill'],
    colors: null,
    events: [],
  },

  onLoad() {
    // [EN] The PAG file (cyl-pag) joins the list when it was downloaded. [CN] 下载了 PAG 文件时加入列表（cyl-pag）。
    this.cylPAGFiles = cylAvailablePAGFiles();
    this.setData({ files: CYL_FILES.concat(this.cylPAGFiles.map((file) => file.split('/').pop().replace(/\.bin$/, ''))) });
    const texts = {};
    Object.keys(cylDemoStrings.en).forEach((key) => {
      texts[key] = t(key);
    });
    this.setData({ texts });
  },

  cyl_lottie() {
    return this.selectComponent('#cyl-playground');
  },
  cyl_file(event) {
    const file = event.currentTarget.dataset.value;
    const pag = this.cylPAGFiles.find((candidate) => candidate.endsWith(`/${file}.bin`));
    this.setData({ file, path: pag || `/shared/lottie/${file}.json`, isPAG: Boolean(pag) });
  },
  cyl_play() {
    this.cyl_lottie().cyl_play();
  },
  cyl_pause() {
    this.cyl_lottie().cyl_pause();
  },
  cyl_stop() {
    this.cyl_lottie().cyl_stop();
  },
  cyl_speed(event) {
    this.setData({ speed: Number(event.currentTarget.dataset.value) });
  },
  cyl_fit(event) {
    this.setData({ fit: event.currentTarget.dataset.value });
  },
  cyl_loop(event) {
    this.setData({ loop: event.detail.value });
  },
  cyl_recolor(event) {
    this.setData({ colors: event.detail.value ? { '**': '#FF3B30' } : null });
  },
  cyl_event(event) {
    const message = event.detail && event.detail.message ? `: ${event.detail.message}` : '';
    const events = [`${event.type}${message}`].concat(this.data.events).slice(0, 4);
    this.setData({ events });
  },
});
