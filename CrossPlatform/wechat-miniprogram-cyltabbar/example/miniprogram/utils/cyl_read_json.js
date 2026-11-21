/**
 * [EN] Reads a JSON file of the code package (a mini program cannot require .json files); {} when it fails.
 * [CN] 读取代码包内的 JSON 文件（小程序不能 require .json 文件）；失败时返回 {}。
 */
function cylReadJSON(path) {
  try {
    return JSON.parse(wx.getFileSystemManager().readFileSync(path, 'utf8'));
  } catch (error) {
    console.error(`cyl example: reading ${path} failed: ${error.message || error.errMsg}`);
    return {};
  }
}

module.exports = { cylReadJSON };
