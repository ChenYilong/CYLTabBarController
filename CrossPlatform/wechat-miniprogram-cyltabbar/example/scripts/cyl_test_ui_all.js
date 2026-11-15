/**
 * [EN] Runs the UI tests once for every animation library the example can install (Lottie, PAG, Rive, GIF), so each
 *      library is checked for the same bugs (e.g. a second layer of tab icons while a page scrolls). It installs the
 *      library with `cyl_setup.js --animation=<name>`, starts the tests, and ends with the default (Lottie) installed.
 *      Each run reloads WeChat DevTools with `cli auto` and connects to its automation port (CYL_AUTO_PORT, default 9420;
 *      CYL_DEVTOOLS_CLI names another command line tool).
 *      Usage: `npm run test-ui-all` (or `npm run test-ui-all -- rive pag` for some of them).
 * [CN] 对示例可安装的每个动画库（Lottie、PAG、Rive、GIF）各运行一次 UI 测试，使每个库都接受同样的检查（例如页面滚动时
 *      Tab 图标出现第二个图层）。先用 `cyl_setup.js --animation=<名称>` 安装该库，再运行测试，最后恢复默认的 Lottie。
 *      每次运行都用 `cli auto` 重新加载开发者工具，并连接其自动化端口（CYL_AUTO_PORT，默认 9420；CYL_DEVTOOLS_CLI 指定其他命令行工具）。
 *      用法：`npm run test-ui-all`（或 `npm run test-ui-all -- rive pag` 只测其中几个）。
 */
const { spawnSync } = require('node:child_process');
const path = require('node:path');

const CYL_ROOT = path.resolve(__dirname, '..');
const CYL_CLI = require('./cyl_devtools_cli').cylDevtoolsCli();
const CYL_PORT = process.env.CYL_AUTO_PORT || '9420';
const CYL_ALL = ['lottie', 'pag', 'rive', 'gif'];
const names = process.argv.slice(2).length > 0 ? process.argv.slice(2) : CYL_ALL;
const results = [];

function cylRun(command, args, env) {
  // [EN] Windows runs a .bat / .cmd only through a shell (Node 18.20+), so quote its arguments.
  // [CN] Windows 只能通过 shell 运行 .bat / .cmd（Node 18.20+），因此给参数加引号。
  const shell = process.platform === 'win32' && /\.(bat|cmd)$/i.test(command);
  const quote = (text) => (shell ? `"${text}"` : text);
  return spawnSync(quote(command), args.map(quote), {
    cwd: CYL_ROOT, stdio: 'inherit', shell, env: Object.assign({}, process.env, env),
  }).status;
}

for (const name of names) {
  if (!CYL_ALL.includes(name)) {
    console.error(`Unknown animation "${name}"; one of ${CYL_ALL.join(', ')}.`);
    process.exit(2);
  }
  console.log(`\n=== UI tests with ${name} icons ===`);
  let setup = cylRun('node', ['scripts/cyl_setup.js', `--animation=${name}`]);
  if (setup === 0) {
    // [EN] The code package of this library must fit the 2 MB WeChat allows. [CN] 该库的代码包必须不超过微信允许的 2 MB。
    setup = cylRun('node', ['scripts/cyl_check_package_size.js', '--check']);
  }
  // [EN] `cli auto` makes DevTools load the files just installed, and opens the automation port the tests connect to.
  // [CN] `cli auto` 让开发者工具加载刚安装的文件，并打开测试所连接的自动化端口。
  const reload = setup === 0 ? cylRun(CYL_CLI, ['auto', '--project', CYL_ROOT, '--auto-port', CYL_PORT]) : setup;
  if (reload === 0) {
    // [EN] No `sleep` command on Windows. [CN] Windows 没有 `sleep` 命令。
    Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 12000);
  }
  const tests = reload === 0
    ? cylRun('node', ['--test', '--test-timeout=360000', 'test-ui/cyl_tab_bar.ui.test.js'], { CYL_AUTOMATOR_WS: `ws://127.0.0.1:${CYL_PORT}` })
    : reload;
  results.push({ name, status: tests === 0 ? 'pass' : 'FAIL' });
}
if (names.join() !== 'lottie') {
  cylRun('node', ['scripts/cyl_setup.js', '--animation=lottie']);
}
console.log('\n' + results.map((result) => `${result.name}: ${result.status}`).join('\n'));
process.exit(results.every((result) => result.status === 'pass') ? 0 : 1);
