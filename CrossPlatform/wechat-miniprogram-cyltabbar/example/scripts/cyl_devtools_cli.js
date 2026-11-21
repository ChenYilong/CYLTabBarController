/**
 * [EN] The command line tool of WeChat DevTools on this machine: CYL_DEVTOOLS_CLI, or the default install path of
 *      macOS or Windows.
 * [CN] 本机微信开发者工具的命令行工具：CYL_DEVTOOLS_CLI，或 macOS、Windows 的默认安装路径。
 */
const path = require('node:path');

function cylDevtoolsCli() {
  if (process.env.CYL_DEVTOOLS_CLI) {
    return process.env.CYL_DEVTOOLS_CLI;
  }
  if (process.platform === 'win32') {
    const programFiles = process.env['ProgramFiles(x86)'] || String.raw`C:\Program Files (x86)`;
    return path.join(programFiles, 'Tencent', '微信web开发者工具', 'cli.bat');
  }
  return '/Applications/wechatwebdevtools.app/Contents/MacOS/cli';
}

module.exports = { cylDevtoolsCli };
