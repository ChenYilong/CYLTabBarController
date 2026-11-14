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
 *      小程序代码包不包含 .pag 与 .riv 文件，因此这些副本以 .bin 结尾。本仓库不分发 PAG 文件：由包的 "download"
 *      命令下载；缺少的文件会被跳过，示例改用图片。
 */
const { CYL_ANIMATIONS, cylChosenAnimation } = require('./cyl_animation_choice');

/**
 * [EN] The languages of the example's own texts (utils/cyl_demo_strings.js); English is the source of demo-list.json.
 * [CN] 示例自身文字的语言（utils/cyl_demo_strings.js）；demo-list.json 以英文为源。
 */
const CYL_DEMO_LIST_LANGUAGES = ['zh-Hans', 'zh-Hant'];

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
  const all = JSON.parse(execFileSync('python3', ['-c', script,
    path.join(CYL_REPOSITORY_ROOT, 'scripts', 'sync-example-shared.py')], { encoding: 'utf8' }));
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
    Object.keys(all[language] || {}).sort().filter((text) => texts.has(text)).forEach((text) => {
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

  const themes = Array.from(new Set(assets.map((asset) => asset.theme))).sort();
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
  files['symbols.js'] = Buffer.from(`${CYL_GENERATED_NOTE}module.exports = ${JSON.stringify(symbolsByTheme, null, 2)};\n`);

  const choice = cylChosenAnimation(process.argv, false);
  const animation = CYL_ANIMATIONS[choice];
  const animationFolder = path.resolve(CYL_COMPONENT_ROOT, animation.folder);
  const resources = JSON.parse(fs.readFileSync(path.join(animationFolder, 'package.json'), 'utf8')).cylExampleResources;
  const resourceSource = path.join(CYL_REPOSITORY_ROOT, resources.source);
  const packageName = (name) => (/\.(pag|riv)$/.test(name) ? `${name}.bin` : name);
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
function cylMain() {
  const check = process.argv.includes('--check');
  const files = cylGeneratedFiles();
  const stale = [];
  Object.keys(files).sort().forEach((relativePath) => {
    const target = path.join(CYL_TARGET, relativePath);
    const current = fs.existsSync(target) ? fs.readFileSync(target) : null;
    if (current && current.equals(files[relativePath])) {
      return;
    }
    stale.push(relativePath);
    if (!check) {
      fs.mkdirSync(path.dirname(target), { recursive: true });
      fs.writeFileSync(target, files[relativePath]);
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
