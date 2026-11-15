#!/usr/bin/env node
/**
 * [EN] Copies what the example shares with the other examples from Example-Shared/Configurations into
 *      miniprogram/shared/, because a mini program cannot read files outside its own folder:
 *      - configuration.js: cyl_tabbar_configuration.json as a CommonJS module;
 *      - localization.js: the ConfigurationDemo tables of every language (Localization/<language>.lproj);
 *      - skins/2.1.0/<theme>/*.png: the skin images of the manifest (Manifests/cyl_tabbar_manifest.json);
 *      - demo_list.js: the demo list of the Objective-C example (Example-Shared/DemoList/demo-list.json, shared with the
 *        React Native and Flutter examples) with its translations in the example's languages, made by
 *        scripts/sync-example-shared.py from the library's string tables; the icons are left out (5.4 MB);
 *      - symbols.js: the "system:<name>" image routes of the configuration per skin, resolved to those images with the
 *        manifest's fallback chain (theme + state, theme normal, default theme + state, default normal).
 *      Run it after changing Example-Shared: `node scripts/cyl_sync_shared.js`; `--check` exits 1 when a copy is out
 *      of date.
 * [CN] 把示例与其他示例共用的内容从 Example-Shared/Configurations 复制到 miniprogram/shared/，因为小程序无法读取自身
 *      目录以外的文件：
 *      - configuration.js：cyl_tabbar_configuration.json 转为 CommonJS 模块；
 *      - localization.js：所有语言的 ConfigurationDemo 表（Localization/<语言>.lproj）；
 *      - skins/2.1.0/<皮肤>/*.png：清单（Manifests/cyl_tabbar_manifest.json）中的皮肤图片；
 *      - demo_list.js：Objective-C 示例的演示列表（Example-Shared/DemoList/demo-list.json，与 React Native、Flutter 示例
 *        共用），以及示例各语言的翻译，由 scripts/sync-example-shared.py 根据库的字符串表生成；不含图标（5.4 MB）；
 *      - symbols.js：配置中 "system:<名称>" 图片路由在每个皮肤下对应的图片，按清单的回退顺序解析（皮肤 + 状态、皮肤
 *        normal、默认皮肤 + 状态、默认 normal）。
 *      修改 Example-Shared 后运行：`node scripts/cyl_sync_shared.js`；`--check` 在副本过期时以 1 退出。
 */
const fs = require('fs');
const path = require('path');

const CYL_COMPONENT_ROOT = path.resolve(__dirname, '..');
const CYL_REPOSITORY_ROOT = path.resolve(CYL_COMPONENT_ROOT, '..', '..', '..');
const CYL_SOURCE = path.join(CYL_REPOSITORY_ROOT, 'Example-Shared', 'Configurations');
const CYL_TARGET = path.join(CYL_COMPONENT_ROOT, 'miniprogram', 'shared');
const CYL_PACKAGE_PATH = '/shared';
const CYL_DEFAULT_THEME = 'light';

/**
 * [EN] SF Symbol names of the shared configuration -> manifest asset keys; ".fill" is the selected state.
 * [CN] 共用配置中的 SF Symbol 名称 -> 清单资源键；".fill" 表示选中状态。
 */
const CYL_SYMBOL_ASSETS = {
  house: 'home',
  message: 'message',
  safari: 'discover',
  person: 'me',
  'plus.circle': 'plus',
};

/**
 * [EN] The example's tab icons come from its one animation package (scripts/cyl_animation_choice.js): the package lists
 *      them in "cylExampleResources" of its package.json (folder, source folder in this repository, files), and only
 *      that package's icons are copied, to shared/<folder>. A mini program code package leaves out .pag and .riv
 *      files, so those copies end in .bin. PAG files are not distributed with the repository: they are downloaded by
 *      the package's "download" command; missing files are skipped and the example falls back to images.
 * [CN] 示例的 Tab 图标来自它唯一的动画包（scripts/cyl_animation_choice.js）：该包在 package.json 的
 *      "cylExampleResources" 中列出它们（目录、本仓库中的来源目录、文件），只复制这个包的图标，到 shared/<目录>。
 *      小程序代码包不包含 .pag、.riv 与 .svga 文件，因此这些副本以 .bin 结尾。本仓库不分发 PAG 文件：由包的 "download"
 *      命令下载；缺少的文件会被跳过，示例改用图片。
 */
const { CYL_ANIMATIONS, cylChosenAnimation } = require('./cyl_animation_choice');

/**
 * [EN] The languages of the example's own texts (utils/cyl_demo_strings.js); English is the source of demo-list.json.
 * [CN] 示例自身文字的语言（utils/cyl_demo_strings.js）；demo-list.json 以英文为源。
 */
const CYL_DEMO_LIST_LANGUAGES = ['zh-Hans', 'zh-Hant'];

function cylRunPython(execFileSync, args) {
  // [EN] macOS / Linux have python3; Windows often has only `python` or the `py` launcher, and its `python3` may be
  //      the Microsoft Store stub, which fails. UTF-8 output keeps the Chinese strings intact on Windows consoles.
  // [CN] macOS / Linux 有 python3；Windows 往往只有 `python` 或 `py` 启动器，其 `python3` 可能是会失败的应用商店占位程序。
  //      强制 UTF-8 输出，避免 Windows 控制台编码损坏中文。
  const candidates = [['python3', []], ['python', []], ['py', ['-3']]];
  const env = Object.assign({}, process.env, { PYTHONIOENCODING: 'utf-8', PYTHONUTF8: '1' });
  let lastError;
  for (const [command, prefix] of candidates) {
    try {
      return execFileSync(command, prefix.concat(args), { encoding: 'utf8', env, stdio: ['ignore', 'pipe', 'pipe'] });
    } catch (error) {
      lastError = error;
    }
  }
  throw new Error(`Python 3 is required to read scripts/sync-example-shared.py (tried python3, python, py -3): ${lastError && lastError.message}`);
}

/**
 * [EN] demo_list.js: the sections and badge samples of demo-list.json, and {language: {English: translation}} for
 *      its titles and subtitles, from strings_source() of scripts/sync-example-shared.py (one translator for every
 *      example).
 * [CN] demo_list.js：demo-list.json 的 section 与角标样例，以及其标题、副标题的 {语言: {英文: 译文}}，取自
 *      scripts/sync-example-shared.py 的 strings_source()（所有示例共用一个翻译器）。
 */
function cylDemoListSource() {
  const { execFileSync } = require('child_process');
  const list = JSON.parse(fs.readFileSync(path.join(CYL_REPOSITORY_ROOT, 'Example-Shared', 'DemoList', 'demo-list.json'), 'utf8'));
  const script = 'import importlib.util, sys\n'
    + 'spec = importlib.util.spec_from_file_location("cyl_sync", sys.argv[1])\n'
    + 'module = importlib.util.module_from_spec(spec)\n'
    + 'spec.loader.exec_module(module)\n'
    + 'sys.stdout.write(module.strings_source())\n';
  const all = JSON.parse(cylRunPython(execFileSync, ['-c', script,
    path.join(CYL_REPOSITORY_ROOT, 'scripts', 'sync-example-shared.py')]));
  const texts = new Set();
  const walk = (node) => {
    if (Array.isArray(node)) {
      node.forEach(walk);
    } else if (node && typeof node === 'object') {
      Object.keys(node).forEach((key) => {
        if ((key === 'title' || key === 'subtitle') && typeof node[key] === 'string') {
          texts.add(node[key]);
        } else {
          walk(node[key]);
        }
      });
    }
  };
  walk(list);
  const strings = {};
  CYL_DEMO_LIST_LANGUAGES.forEach((language) => {
    strings[language] = {};
    Object.keys(all[language] || {}).sort((a, b) => String(a).localeCompare(String(b))).filter((text) => texts.has(text)).forEach((text) => {
      strings[language][text] = all[language][text];
    });
  });
  const demoList = { sections: list.sections, badgeSamples: list.badgeSamples, strings };
  return `${CYL_GENERATED_NOTE.replace('Example-Shared/Configurations', 'Example-Shared/DemoList')}module.exports = ${JSON.stringify(demoList, null, 1)};\n`;
}

const CYL_GENERATED_NOTE = '// Generated by scripts/cyl_sync_shared.js from Example-Shared/Configurations; do not edit by hand.\n';

/**
 * [EN] A .strings file as a dictionary.
 * [CN] 把 .strings 文件转为字典。
 */
function cylReadStrings(file) {
  const table = {};
  const pattern = /^"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)";/gm;
  const text = fs.readFileSync(file, 'utf8');
  let match = pattern.exec(text);
  while (match) {
    table[JSON.parse(`"${match[1]}"`)] = JSON.parse(`"${match[2]}"`);
    match = pattern.exec(text);
  }
  return table;
}

/**
 * [EN] The manifest asset for a key, theme and state, following the manifest's fallback chain.
 * [CN] 按清单的回退顺序，取出某个键、皮肤与状态对应的清单资源。
 */
function cylFindAsset(assets, key, theme, state) {
  const candidates = [
    [theme, state],
    [theme, 'normal'],
    [CYL_DEFAULT_THEME, state],
    [CYL_DEFAULT_THEME, 'normal'],
  ];
  for (const [candidateTheme, candidateState] of candidates) {
    const asset = assets.find((entry) => entry.key === key && entry.theme === candidateTheme
      && entry.state === candidateState);
    if (asset) {
      return asset;
    }
  }
  return null;
}

/**
 * [EN] Every generated file: relative path -> Buffer.
 * [CN] 所有生成的文件：相对路径 -> Buffer。
 */
/**
 * [EN] The languages of the Objective-C example's language picker that the example has no table of (CYLLocalization.swift:
 *      en, zh-Hans, hi, es, ar), for the example's texts (miniprogram/utils/cyl_demo_strings.js) and the demo list: each
 *      English text is looked up in the library's English table, and the same key gives the text in the other language.
 *      "{name}" parts are "%@" in the library (in order). A text the library does not have stays English.
 * [CN] Objective-C 示例语言选择器中示例尚无字符串表的语言（CYLLocalization.swift：en、zh-Hans、hi、es、ar），用于示例文字
 *      （miniprogram/utils/cyl_demo_strings.js）与演示列表：每个英文文字在库的英文表中查找，用同一个键取得另一种语言的文字。
 *      「{name}」部分在库中为「%@」（按顺序）。库中没有的文字保持英文。
 */
const CYL_MORE_LANGUAGES = ['hi', 'es', 'ar'];

function cylMoreStrings() {
  const bundle = path.join(CYL_REPOSITORY_ROOT, 'CYLTabBarController', 'Resources', 'CYLTabBarController.bundle');
  const read = (language) => cylReadStrings(path.join(bundle, `${language}.lproj`, 'CYLTabBarController.strings'));
  const english = read('en');
  const keyByText = {};
  Object.keys(english).forEach((key) => {
    const text = english[key].replace(/%(\d+\$)?@/g, '%@');
    if (!(text in keyByText)) {
      keyByText[text] = key;
    }
  });
  const texts = new Set(Object.keys(require(path.join(CYL_COMPONENT_ROOT, 'miniprogram', 'utils', 'cyl_demo_strings.js')).en));
  const demoList = JSON.parse(fs.readFileSync(path.join(CYL_REPOSITORY_ROOT, 'Example-Shared', 'DemoList', 'demo-list.json'), 'utf8'));
  const collect = (value) => {
    if (Array.isArray(value)) {
      value.forEach(collect);
    } else if (value && typeof value === 'object') {
      ['title', 'subtitle'].forEach((field) => {
        if (typeof value[field] === 'string' && value[field]) {
          texts.add(value[field]);
        }
      });
      Object.keys(value).filter((key) => key !== 'strings').forEach((key) => collect(value[key]));
    }
  };
  collect(demoList);
  const tables = {};
  CYL_MORE_LANGUAGES.forEach((language) => {
    const translated = read(language);
    const table = {};
    Array.from(texts).sort((a, b) => String(a).localeCompare(String(b))).forEach((text) => {
      const names = text.match(/\{\w+\}/g) || [];
      const key = keyByText[text.replace(/\{\w+\}/g, '%@')];
      if (!key || translated[key] === undefined) {
        return;
      }
      let index = 0;
      table[text] = translated[key].replace(/%(\d+)\$@|%@/g, (match, position) => {
        const name = position ? names[Number(position) - 1] : names[index];
        index += 1;
        return name || match;
      });
    });
    tables[language] = table;
  });
  return tables;
}

/**
 * [EN] A click as a mono 16-bit 22.05 kHz WAV: a sine of `frequency` Hz that decays over `seconds`.
 * [CN] 单声道 16 位 22.05 kHz WAV 格式的点击声：`frequency` Hz 的正弦波，在 `seconds` 秒内衰减。
 */
function cylClickWAV(frequency, seconds) {
  const rate = 22050;
  const count = Math.round(rate * seconds);
  const data = Buffer.alloc(count * 2);
  for (let index = 0; index < count; index += 1) {
    const time = index / rate;
    const envelope = Math.exp(-time / (seconds / 5));
    data.writeInt16LE(Math.round(Math.sin(2 * Math.PI * frequency * time) * envelope * 0.6 * 32767), index * 2);
  }
  const header = Buffer.alloc(44);
  header.write('RIFF', 0, 'ascii');
  header.writeUInt32LE(36 + data.length, 4);
  header.write('WAVEfmt ', 8, 'ascii');
  header.writeUInt32LE(16, 16);
  header.writeUInt16LE(1, 20);
  header.writeUInt16LE(1, 22);
  header.writeUInt32LE(rate, 24);
  header.writeUInt32LE(rate * 2, 28);
  header.writeUInt16LE(2, 32);
  header.writeUInt16LE(16, 34);
  header.write('data', 36, 'ascii');
  header.writeUInt32LE(data.length, 40);
  return Buffer.concat([header, data]);
}

/**
 * [EN] A palette PNG (color type 3) drawn at `alpha`: every palette entry's transparency (the tRNS chunk, added when
 *      missing) times `alpha`. Only the chunks change, so it needs no image library.
 * [CN] 以 `alpha` 绘制的调色板 PNG（颜色类型 3）：每个调色板项的透明度（tRNS 块，缺失时添加）乘以 `alpha`。只修改块，
 *      因此不需要图片库。
 */
function cylFadedPalettePNG(image, alpha) {
  if (image[25] !== 3) {
    throw new Error('cylFadedPalettePNG: not a palette PNG');
  }
  const crcTable = Array.from({ length: 256 }, (unused, n) => {
    let c = n;
    for (let k = 0; k < 8; k += 1) {
      c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    }
    return c >>> 0;
  });
  const crc = (buffer) => {
    let c = 0xffffffff;
    for (const byte of buffer) {
      c = crcTable[(c ^ byte) & 0xff] ^ (c >>> 8);
    }
    return (c ^ 0xffffffff) >>> 0;
  };
  const chunk = (type, data) => {
    const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
    const length = Buffer.alloc(4);
    length.writeUInt32BE(data.length);
    const sum = Buffer.alloc(4);
    sum.writeUInt32BE(crc(body));
    return Buffer.concat([length, body, sum]);
  };
  const parts = [image.subarray(0, 8)];
  let entries = 0;
  let transparency = null;
  const chunks = [];
  for (let offset = 8; offset < image.length;) {
    const length = image.readUInt32BE(offset);
    const type = image.toString('ascii', offset + 4, offset + 8);
    const data = image.subarray(offset + 8, offset + 8 + length);
    chunks.push({ type, data });
    if (type === 'PLTE') {
      entries = length / 3;
    } else if (type === 'tRNS') {
      transparency = data;
    }
    offset += 12 + length;
  }
  const faded = Buffer.alloc(entries);
  for (let index = 0; index < entries; index += 1) {
    const original = transparency && index < transparency.length ? transparency[index] : 255;
    faded[index] = Math.round(original * alpha);
  }
  chunks.forEach(({ type, data }) => {
    if (type === 'tRNS') {
      return;
    }
    if (type === 'IDAT' && !parts.some((part) => part.cylTransparency)) {
      const transparencyChunk = chunk('tRNS', faded);
      transparencyChunk.cylTransparency = true;
      parts.push(transparencyChunk);
    }
    parts.push(chunk(type, data));
  });
  return Buffer.concat(parts);
}

const CYL_OBJC_TAB_BAR_IMAGES = ['home_normal', 'home_highlight', 'fishpond_normal', 'fishpond_highlight', 'message_normal',
  'message_highlight', 'message_normal_night', 'account_normal', 'account_highlight', 'post_normal', 'post_highlight',
  'home_select_cover'];

function cylGeneratedFiles() {
  const files = {};
  const configuration = JSON.parse(fs.readFileSync(path.join(CYL_SOURCE, 'cyl_tabbar_configuration.json'), 'utf8'));
  files['configuration.js'] = Buffer.from(`${CYL_GENERATED_NOTE}module.exports = ${JSON.stringify(configuration, null, 2)};\n`);

  const localization = {};
  const tableName = configuration.CYLTabBarControllerLocalization.CYLTabBarLocalizationTableName;
  fs.readdirSync(path.join(CYL_SOURCE, 'Localization')).sort().forEach((folder) => {
    const file = path.join(CYL_SOURCE, 'Localization', folder, `${tableName}.strings`);
    if (folder.endsWith('.lproj') && fs.existsSync(file)) {
      localization[folder.replace(/\.lproj$/, '')] = cylReadStrings(file);
    }
  });
  files['localization.js'] = Buffer.from(`${CYL_GENERATED_NOTE}module.exports = ${JSON.stringify(localization, null, 2)};\n`);

  const manifest = JSON.parse(fs.readFileSync(path.join(CYL_SOURCE, 'Manifests', 'cyl_tabbar_manifest.json'), 'utf8'));
  const assets = manifest.assets.list;
  const skinFolder = path.join('skins', manifest.version);
  const skinSource = path.resolve(path.join(CYL_SOURCE, 'Manifests'), manifest.assets.baseRoute);
  assets.forEach((asset) => {
    files[path.join(skinFolder, asset.path)] = fs.readFileSync(path.join(skinSource, asset.path));
  });

  const themes = Array.from(new Set(assets.map((asset) => asset.theme))).sort((a, b) => String(a).localeCompare(String(b)));
  const symbolsByTheme = {};
  themes.forEach((theme) => {
    const symbols = {};
    Object.keys(CYL_SYMBOL_ASSETS).forEach((name) => {
      [[name, 'normal'], [`${name}.fill`, 'selected']].forEach(([symbol, state]) => {
        const asset = cylFindAsset(assets, CYL_SYMBOL_ASSETS[name], theme, state);
        if (asset) {
          symbols[symbol] = `${CYL_PACKAGE_PATH}/${skinFolder}/${asset.path}`.split(path.sep).join('/');
        }
      });
    });
    symbolsByTheme[theme] = symbols;
  });
  symbolsByTheme.default = symbolsByTheme[CYL_DEFAULT_THEME];
  files['demo_list.js'] = Buffer.from(cylDemoListSource());
  files['strings_more.js'] = Buffer.from(`${CYL_GENERATED_NOTE}module.exports = ${JSON.stringify(cylMoreStrings(), null, 2)};\n`);
  files['symbols.js'] = Buffer.from(`${CYL_GENERATED_NOTE}module.exports = ${JSON.stringify(symbolsByTheme, null, 2)};\n`);

  // [EN] The Objective-C example's tab bar images (Example/Images.xcassets/TabBarIcon, @3x), which the example's tab bar
  //      uses as +[MainTabBarController tabBarItemsAttributesForTabBar] does (docs/ObjC-Example-Parity).
  // [CN] Objective-C 示例的 TabBar 图片（Example/Images.xcassets/TabBarIcon，@3x），示例 TabBar 与
  //      +[MainTabBarController tabBarItemsAttributesForTabBar] 一样使用它们（docs/ObjC-Example-Parity）。
  const tabBarIcons = path.join(CYL_REPOSITORY_ROOT, 'Example', 'Images.xcassets', 'TabBarIcon');
  CYL_OBJC_TAB_BAR_IMAGES.forEach((name) => {
    const folder = name === 'home_select_cover' ? '' : name.split('_')[0];
    files[path.join('objc', `${name}.png`)] = fs.readFileSync(path.join(tabBarIcons, folder, `${name}.imageset`, `${name}@3x.png`));
  });

  // [EN] The holiday skins' icons (Example-Shared/Configurations/Skins/1.0.0, read by UIViewController+CYLThemeSettings),
  //      each with a copy at 45% opacity: the unselected look (`faded(_:)`), docs/ObjC-Example-Parity items 9 and 32.
  // [CN] 节日皮肤的图标（Example-Shared/Configurations/Skins/1.0.0，由 UIViewController+CYLThemeSettings 读取），每个另有
  //      45% 不透明度的副本：未选中样式（`faded(_:)`），docs/ObjC-Example-Parity 第 9、32 项。
  const themeIcons = path.join(CYL_SOURCE, 'Skins', '1.0.0');
  fs.readdirSync(themeIcons).filter((folder) => fs.statSync(path.join(themeIcons, folder)).isDirectory()).sort()
    .forEach((folder) => {
      fs.readdirSync(path.join(themeIcons, folder)).filter((name) => name.endsWith('@3x.png')).sort().forEach((name) => {
        const image = fs.readFileSync(path.join(themeIcons, folder, name));
        const base = name.replace('@3x.png', '');
        files[path.join('theme', folder, `${base}.png`)] = image;
        files[path.join('theme', folder, `${base}_faded.png`)] = cylFadedPalettePNG(image, 0.45);
      });
    });
  files[path.join('theme', 'cyl_theme_icons_LICENSE.txt')] = fs.readFileSync(path.join(CYL_SOURCE, 'Skins', 'cyl_theme_icons_LICENSE.txt'));

  // [EN] The Home rows "Change all local icons" and "GIF icon" (UIViewController+CYLTabBarItemUpdate.swift): the example's
  //      img_tab_home / img_tab_message images and the library's animated GIF (docs/ObjC-Example-Parity items 24, 25).
  // [CN] 首页「批量使用本地图标」与「GIF 动图图标」行（UIViewController+CYLTabBarItemUpdate.swift）：示例的 img_tab_home /
  //      img_tab_message 图片与库的 GIF 动图（docs/ObjC-Example-Parity 第 24、25 项）。
  const lottieResources = path.join(CYL_REPOSITORY_ROOT, 'Example', 'Classes', 'Other', 'LottieResources');
  ['img_tab_home_0', 'img_tab_home_1', 'img_tab_message_0', 'img_tab_message_1'].forEach((name) => {
    files[path.join('objc', `${name}.png`)] = fs.readFileSync(path.join(lottieResources, `${name}.png`));
  });
  // [EN] The tap sounds of the Home row "Tab tap sound and haptics" (item 33): a short click (the default click) and a
  //      lower tock (the custom sound file, as /System/Library/Audio/UISounds/Tock.caf), made here as 16-bit WAV.
  // [CN] 首页「Tab 点击声音与触感反馈」行（第 33 项）的点击声：短促的 click（默认点击声）与较低的 tock（自定义音频文件，对应
  //      /System/Library/Audio/UISounds/Tock.caf），在此生成 16 位 WAV。
  files[path.join('sounds', 'cyl_tap_click.wav')] = cylClickWAV(1800, 0.025);
  files[path.join('sounds', 'cyl_tap_tock.wav')] = cylClickWAV(650, 0.045);
  files[path.join('objc', 'cyl_tab_sample_animated.gif')] = fs.readFileSync(path.join(CYL_REPOSITORY_ROOT, 'CYLTabBarController',
    'Resources', 'CYLTabBarController.bundle', 'cyl_tab_sample_animated.gif'));

  const choice = cylChosenAnimation(process.argv, false);
  const animation = CYL_ANIMATIONS[choice];
  const animationFolder = path.resolve(CYL_COMPONENT_ROOT, animation.folder);
  const resources = JSON.parse(fs.readFileSync(path.join(animationFolder, 'package.json'), 'utf8')).cylExampleResources;
  const resourceSource = path.join(CYL_REPOSITORY_ROOT, resources.source);
  const packageName = (name) => (/\.(pag|riv|svga)$/.test(name) ? `${name}.bin` : name);
  const icons = [];
  resources.files.filter((name) => fs.existsSync(path.join(resourceSource, name))).forEach((name) => {
    files[path.join(resources.folder, packageName(name))] = fs.readFileSync(path.join(resourceSource, name));
    if (!/\.txt$|LICENSE/.test(name)) {
      icons.push(`${CYL_PACKAGE_PATH}/${resources.folder}/${packageName(name)}`);
    }
  });
  const animations = { installed: choice, files: icons };
  files['animations.js'] = Buffer.from(`${CYL_GENERATED_NOTE}module.exports = ${JSON.stringify(animations, null, 2)};\n`);
  return files;
}

/**
 * [EN] Writes the files, or with --check reports the ones that differ and exits 1.
 * [CN] 写入文件；带 --check 时报告不一致的文件并以 1 退出。
 */
function cylSameContent(current, expected) {
  // [EN] Text that differs only by CRLF (a Windows checkout with core.autocrlf) is the same; binary files (with NUL
  //      bytes, e.g. images) must match byte for byte.
  // [CN] 仅 CRLF 不同的文本（Windows 上 core.autocrlf 检出）视为相同；二进制文件（含 NUL 字节，如图片）须逐字节一致。
  const buffer = Buffer.isBuffer(expected) ? expected : Buffer.from(expected);
  if (current.equals(buffer)) {
    return true;
  }
  if (current.includes(0) || buffer.includes(0)) {
    return false;
  }
  return current.toString('utf8').replace(/\r\n/g, '\n') === buffer.toString('utf8').replace(/\r\n/g, '\n');
}

function cylKeepLineEnds(current, expected) {
  // [EN] A text file that had CRLF line ends (a Windows checkout) keeps them, so git sees no change of line ends.
  // [CN] 原为 CRLF 行尾的文本文件（Windows 检出）保留 CRLF，使 git 不会看到行尾变化。
  const buffer = Buffer.isBuffer(expected) ? expected : Buffer.from(expected);
  if (!current || current.includes(0) || buffer.includes(0) || !current.includes('\r\n')) {
    return buffer;
  }
  return Buffer.from(buffer.toString('utf8').replace(/\r?\n/g, '\r\n'), 'utf8');
}

function cylMain() {
  const check = process.argv.includes('--check');
  const files = cylGeneratedFiles();
  const stale = [];
  Object.keys(files).sort((a, b) => String(a).localeCompare(String(b))).forEach((relativePath) => {
    const target = path.join(CYL_TARGET, relativePath);
    const current = fs.existsSync(target) ? fs.readFileSync(target) : null;
    if (current && cylSameContent(current, files[relativePath])) {
      return;
    }
    stale.push(relativePath);
    if (!check) {
      fs.mkdirSync(path.dirname(target), { recursive: true });
      fs.writeFileSync(target, cylKeepLineEnds(current, files[relativePath]));
    }
  });
  // [EN] Icons of the animation packages not chosen are removed. [CN] 删除未选择的动画包的图标。
  const kept = new Set(Object.keys(files).map((file) => file.split(path.sep)[0]));
  const folders = Object.values(CYL_ANIMATIONS).map(({ folder }) => JSON.parse(fs.readFileSync(
    path.join(path.resolve(CYL_COMPONENT_ROOT, folder), 'package.json'), 'utf8')).cylExampleResources.folder);
  folders.filter((folder) => !kept.has(folder) && fs.existsSync(path.join(CYL_TARGET, folder))).forEach((folder) => {
    stale.push(`${folder}/ (removed)`);
    if (!check) {
      fs.rmSync(path.join(CYL_TARGET, folder), { recursive: true, force: true });
    }
  });
  if (check && stale.length > 0) {
    console.error(`Out of date, run node scripts/cyl_sync_shared.js:\n  ${stale.join('\n  ')}`);
    process.exit(1);
  }
  console.log(check ? 'miniprogram/shared is up to date.' : `Updated ${stale.length} file(s) in miniprogram/shared.`);
}

cylMain();
