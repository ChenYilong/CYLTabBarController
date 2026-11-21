/**
 * [EN] The cyl-lottie playground: the component of cyl-lottie-miniprogram (a sub-dependency of
 *      cyl-tabbar-miniprogram) with its properties, methods and events.
 * [CN] cyl-lottie 演示页：cyl-lottie-miniprogram（cyl-tabbar-miniprogram 的子依赖）的组件，以及它的属性、方法与事件。
 */
const { t } = require('../../utils/cyl_demo_localization');
const cylDemoStrings = require('../../utils/cyl_demo_strings');

const { cylInstalledAnimation, cylAvailableAnimationFiles } = require('../../utils/cyl_demo_configuration');

const CYL_FILES = ['green_lottie_tab_home', 'green_lottie_tab_discover', 'green_lottie_tab_mine'];

/**
 * [EN] With Rive installed, the files and their options (docs/Animated-Item.md, the Rive loop): an icons.riv tab icon (a boolean
 *      input) and house.riv, whose state machine moves only when its NUMBER input `Rooms` changes, so each play sets the
 *      next of 3, 4, 5, 6 (`numberInput`, `values`).
 * [CN] 安装 Rive 时的文件及其选项（docs/Animated-Item.md，Rive 循环）：icons.riv 的一个 Tab 图标（布尔输入），以及 house.riv：其状态机只在 NUMBER 输入
 *      `Rooms` 变化时运动，因此每次播放设置 3、4、5、6 中的下一个（`numberInput`、`values`）。
 */
const CYL_RIVE_FILES = [
  { name: 'icons.riv · CHAT', file: 'icons.riv.bin', fragment: 'artboard=CHAT&stateMachine=CHAT_Interactivity&input=active' },
  { name: 'house.riv · Rooms', file: 'house.riv.bin', fragment: 'stateMachine=State%20Machine%201&numberInput=Rooms&values=3,4,5,6' },
];

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
    // [EN] The files of the installed package: Lottie (cyl-lottie) or, with PAG installed, the PAG icons (cyl-pag).
    // [CN] 已安装包的文件：Lottie（cyl-lottie），或安装 PAG 时的 PAG 图标（cyl-pag）。
    this.cylPAGFiles = cylInstalledAnimation() === 'pag' ? cylAvailableAnimationFiles() : [];
    if (cylInstalledAnimation() === 'rive') {
      const available = cylAvailableAnimationFiles();
      this.cylRiveFiles = CYL_RIVE_FILES.map((entry) => {
        const file = available.find((candidate) => candidate.endsWith(`/${entry.file}`));
        return file ? { name: entry.name, path: `${file}#${entry.fragment}` } : null;
      }).filter(Boolean);
      if (this.cylRiveFiles.length) {
        this.setData({ files: this.cylRiveFiles.map((entry) => entry.name), file: this.cylRiveFiles[0].name, path: this.cylRiveFiles[0].path, isRive: true });
      }
    }
    if (this.cylPAGFiles.length) {
      const names = this.cylPAGFiles.map((file) => file.split('/').pop().replace(/\.bin$/, ''));
      this.setData({ files: names, file: names[0], path: this.cylPAGFiles[0], isPAG: true });
    }
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
    const rive = (this.cylRiveFiles || []).find((entry) => entry.name === file);
    if (rive) {
      this.setData({ file, path: rive.path });
      return;
    }
    const pag = this.cylPAGFiles.find((candidate) => candidate.endsWith(`/${file}.bin`));
    this.setData({ file, path: pag || `/shared/lottie/${file}.json`, isPAG: Boolean(pag) });
  },
  cyl_play() {
    // [EN] cyl-rive's cyl_play only resumes; a play from the start sets the next Rooms value of house.riv.
    // [CN] cyl-rive 的 cyl_play 只是继续播放；从头播放才会设置 house.riv 的下一个 Rooms 值。
    const view = this.cyl_lottie();
    if (this.data.isRive && typeof view.cyl_playFromStart === 'function') {
      view.cyl_playFromStart();
    } else {
      view.cyl_play();
    }
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
  // [EN] Tapping an event row copies it. [CN] 点击事件行复制该事件。
  cyl_copyEvent(event) {
    wx.setClipboardData({ data: String(event.currentTarget.dataset.value) });
  },
  cyl_event(event) {
    const message = event.detail?.message ? `: ${event.detail.message}` : '';
    const events = [`${event.type}${message}`].concat(this.data.events).slice(0, 4);
    this.setData({ events });
  },
});
