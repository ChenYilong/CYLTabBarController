const STORAGE_KEY = 'rive-preview-library-v1'
const COVER_STORAGE_KEY = 'rive-preview-covers-v1'
const HIDDEN_BUILTIN_STORAGE_KEY = 'rive-preview-hidden-builtins-v1'
const LIBRARY_DIR = `${wx.env.USER_DATA_PATH}/rive-library`
const BUNDLED_FILE_READERS = {
  'assets/samples/guide.riv': () => require('../assets/samples/guide'),
  'assets/samples/question.riv': () => require('../assets/samples/question')
}

const BUILTIN_FILES = [
  {
    id: 'sample-guide',
    name: '引导页动画750_1160.riv',
    path: 'assets/samples/guide.riv',
    cover: '',
    size: 34019,
    source: '内置测试文件',
    builtin: true,
    createdAt: 1785254400000,
    summary: '750 × 1660 · jojo-machine',
    metadata: {
      artboard: '叫叫',
      animations: ['idle', 'in'],
      stateMachine: 'jojo-machine',
      inputs: ['in', 'idle']
    }
  },
  {
    id: 'sample-question',
    name: '题目动画_1.riv',
    path: 'assets/samples/question.riv',
    cover: '',
    size: 40310,
    source: '内置测试文件',
    builtin: true,
    createdAt: 1785254400000,
    summary: '148 × 148 · jojo-machine',
    metadata: {
      artboard: '叫叫',
      animations: ['idle', 'in'],
      stateMachine: 'jojo-machine',
      inputs: ['idle', 'in']
    }
  }
]

function readUserFiles() {
  const stored = wx.getStorageSync(STORAGE_KEY)
  return Array.isArray(stored) ? stored : []
}

function writeUserFiles(files) {
  wx.setStorageSync(STORAGE_KEY, files)
}

function readCoverCache() {
  const stored = wx.getStorageSync(COVER_STORAGE_KEY)
  return stored && typeof stored === 'object' && !Array.isArray(stored) ? stored : {}
}

function writeCoverCache(covers) {
  wx.setStorageSync(COVER_STORAGE_KEY, covers)
}

function readHiddenBuiltinIds() {
  const stored = wx.getStorageSync(HIDDEN_BUILTIN_STORAGE_KEY)
  return Array.isArray(stored) ? stored.filter((id) => typeof id === 'string') : []
}

function writeHiddenBuiltinIds(ids) {
  wx.setStorageSync(HIDDEN_BUILTIN_STORAGE_KEY, [...new Set(ids)])
}

function formatSize(bytes) {
  if (!Number.isFinite(bytes)) return '大小未知'
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(bytes < 10 * 1024 ? 1 : 0)} KB`
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`
}

function formatDate(timestamp) {
  const date = new Date(timestamp)
  const pad = (value) => String(value).padStart(2, '0')
  return `${date.getFullYear()}.${pad(date.getMonth() + 1)}.${pad(date.getDate())}`
}

function resolveExistingCover(file, coverCache) {
  const cover = coverCache[file.id] || file.cover || ''
  if (!cover) return ''
  try {
    wx.getFileSystemManager().accessSync(cover)
    return cover
  } catch (error) {
    return ''
  }
}

function decorate(file, coverCache = readCoverCache()) {
  return {
    ...file,
    cover: resolveExistingCover(file, coverCache),
    displaySize: formatSize(file.size),
    displayDate: file.builtin ? '测试文件' : formatDate(file.createdAt),
    summary: file.summary || '等待解析参数'
  }
}

function getAllFiles() {
  const coverCache = readCoverCache()
  const hiddenBuiltinIds = new Set(readHiddenBuiltinIds())
  const visibleBuiltins = BUILTIN_FILES.filter((file) => !hiddenBuiltinIds.has(file.id))
  return [...visibleBuiltins, ...readUserFiles()].map((file) => decorate(file, coverCache))
}

function getFileById(id) {
  return getAllFiles().find((file) => file.id === id)
}

function ensureLibraryDir() {
  return new Promise((resolve, reject) => {
    const fs = wx.getFileSystemManager()
    fs.mkdir({
      dirPath: LIBRARY_DIR,
      recursive: true,
      success: resolve,
      fail(error) {
        if (String(error.errMsg || '').includes('file already exists')) {
          resolve()
          return
        }
        reject(error)
      }
    })
  })
}

function ensureLibraryDirSync() {
  const fs = wx.getFileSystemManager()
  try {
    fs.accessSync(LIBRARY_DIR)
  } catch (error) {
    try {
      fs.mkdirSync(LIBRARY_DIR, true)
    } catch (mkdirError) {
      if (!String(mkdirError.errMsg || '').includes('file already exists')) {
        throw mkdirError
      }
    }
  }
}

function readFile(path, encoding) {
  const readBundledFile = BUNDLED_FILE_READERS[path]
  if (readBundledFile) {
    const base64 = readBundledFile()
    return Promise.resolve(encoding === 'base64' ? base64 : wx.base64ToArrayBuffer(base64))
  }

  return new Promise((resolve, reject) => {
    wx.getFileSystemManager().readFile({
      filePath: path,
      encoding,
      success: (result) => resolve(result.data),
      fail: reject
    })
  })
}

async function readFileWithProgress(path, options = {}) {
  const {
    expectedSize = 0,
    chunkSize = 1024 * 1024,
    onProgress = () => {},
    shouldContinue = () => true
  } = options
  const readBundledFile = BUNDLED_FILE_READERS[path]
  if (readBundledFile) {
    const data = wx.base64ToArrayBuffer(readBundledFile())
    onProgress({ loaded: data.byteLength, total: data.byteLength, ratio: 1 })
    return data
  }

  const measuredSize = await getFileSize(path)
  const total = measuredSize || Number(expectedSize)
  if (!total || total <= chunkSize) {
    const data = await readFile(path)
    onProgress({ loaded: data.byteLength, total: data.byteLength, ratio: 1 })
    return data
  }

  const output = new Uint8Array(total)
  const fs = wx.getFileSystemManager()
  let loaded = 0
  while (loaded < total) {
    if (!shouldContinue()) {
      const error = new Error('文件读取已取消')
      error.code = 'RIVE_LOAD_CANCELLED'
      throw error
    }
    const length = Math.min(chunkSize, total - loaded)
    const data = await new Promise((resolve, reject) => {
      fs.readFile({
        filePath: path,
        position: loaded,
        length,
        success: (result) => resolve(result.data),
        fail: reject
      })
    })
    const bytes = new Uint8Array(data)
    if (!bytes.byteLength) throw new Error('文件读取提前结束')
    output.set(bytes, loaded)
    loaded += bytes.byteLength
    onProgress({
      loaded,
      total,
      ratio: Math.min(1, loaded / total)
    })
  }
  return output.buffer
}

function writeFile(path, data) {
  return new Promise((resolve, reject) => {
    wx.getFileSystemManager().writeFile({
      filePath: path,
      data,
      success: resolve,
      fail: reject
    })
  })
}

function copyFile(sourcePath, destinationPath) {
  return new Promise((resolve, reject) => {
    wx.getFileSystemManager().copyFile({
      srcPath: sourcePath,
      destPath: destinationPath,
      success: resolve,
      fail: reject
    })
  })
}

function readFileHead(path, length = 8) {
  return new Promise((resolve, reject) => {
    wx.getFileSystemManager().readFile({
      filePath: path,
      position: 0,
      length,
      success: (result) => resolve(result.data),
      fail: reject
    })
  })
}

function getFileSize(path) {
  return new Promise((resolve) => {
    wx.getFileSystemManager().stat({
      path,
      success: (result) => resolve(Number(result.stats?.size) || 0),
      fail: () => resolve(0)
    })
  })
}

function unlink(path) {
  return new Promise((resolve, reject) => {
    wx.getFileSystemManager().unlink({
      filePath: path,
      success: resolve,
      fail: reject
    })
  })
}

async function unlinkIfPresent(path) {
  if (!path) return
  try {
    await unlink(path)
  } catch (error) {
    if (!String(error.errMsg || '').includes('no such file')) throw error
  }
}

function makeId() {
  return `rive-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`
}

function safeFilename(name) {
  const base = String(name || '未命名.riv').replace(/[\\/:*?"<>|]/g, '_')
  return base.toLowerCase().endsWith('.riv') ? base : `${base}.riv`
}

async function validateRiveFile(filePath, name) {
  if (!String(name || filePath).toLowerCase().endsWith('.riv')) {
    throw new Error('请选择 .riv 文件')
  }
  const header = await readFileHead(filePath)
  const bytes = new Uint8Array(header)
  if (
    bytes.length < 8 ||
    bytes[0] !== 0x52 ||
    bytes[1] !== 0x49 ||
    bytes[2] !== 0x56 ||
    bytes[3] !== 0x45
  ) {
    throw new Error('文件不是有效的 Rive 格式')
  }
  return true
}

async function importTempFile(tempFile, source) {
  const result = await importTempFiles([tempFile], source)
  if (!result.imported.length) {
    throw new Error(result.failures[0]?.message || '文件未能导入')
  }
  return result.imported[0]
}

async function importTempFiles(tempFiles, source, onProgress = () => {}) {
  const candidates = Array.isArray(tempFiles) ? tempFiles.filter(Boolean) : []
  if (!candidates.length) return { imported: [], failures: [] }
  await ensureLibraryDir()
  const imported = []
  const failures = []

  for (let index = 0; index < candidates.length; index += 1) {
    const tempFile = candidates[index]
    onProgress({ current: index + 1, total: candidates.length, file: tempFile })
    let destination = ''
    try {
      if (!tempFile.path) throw new Error('文件路径不可读取')
      await validateRiveFile(tempFile.path, tempFile.name)
      const id = makeId()
      const name = safeFilename(tempFile.name)
      destination = `${LIBRARY_DIR}/${id}.riv`
      await copyFile(tempFile.path, destination)
      const size = Number(tempFile.size) || await getFileSize(destination)
      imported.push({
        id,
        name,
        path: destination,
        cover: '',
        size,
        source,
        builtin: false,
        createdAt: Date.now() + index,
        summary: '本地文件 · 打开后解析'
      })
    } catch (error) {
      if (destination) await unlinkIfPresent(destination).catch(() => {})
      failures.push({
        name: tempFile.name || '未命名文件',
        message: error.message || error.errMsg || '文件不可读取'
      })
    }
  }

  if (imported.length) writeUserFiles([...imported, ...readUserFiles()])
  return {
    imported: imported.map((file) => decorate(file)),
    failures
  }
}

function prepareShareFileSync(id) {
  const file = getFileById(id)
  if (!file) throw new Error('找不到文件')
  if (!file.builtin) return file

  ensureLibraryDirSync()
  const sharePath = `${LIBRARY_DIR}/share-${id}.riv`
  const fs = wx.getFileSystemManager()
  try {
    fs.accessSync(sharePath)
  } catch (error) {
    const base64 = BUNDLED_FILE_READERS[file.path]?.()
    if (!base64) throw new Error('无法读取内置文件')
    fs.writeFileSync(sharePath, wx.base64ToArrayBuffer(base64))
  }
  return {
    ...file,
    path: sharePath
  }
}

async function removeFile(id) {
  const builtinFile = BUILTIN_FILES.find((item) => item.id === id)
  if (builtinFile) {
    const covers = readCoverCache()
    await unlinkIfPresent(covers[id] || builtinFile.cover)
    delete covers[id]
    writeCoverCache(covers)
    writeHiddenBuiltinIds([...readHiddenBuiltinIds(), id])
    return
  }

  const file = readUserFiles().find((item) => item.id === id)
  if (!file) return
  await unlinkIfPresent(file.path)
  const covers = readCoverCache()
  await unlinkIfPresent(covers[id] || file.cover)
  delete covers[id]
  writeCoverCache(covers)
  writeUserFiles(readUserFiles().filter((item) => item.id !== id))
}

async function saveCover(id, tempFilePath) {
  if (!id || !tempFilePath) throw new Error('缩略图数据不完整')
  await ensureLibraryDir()
  const destination = `${LIBRARY_DIR}/cover-${id}.png`
  const covers = readCoverCache()
  const previousPath = covers[id]
  const data = await readFile(tempFilePath)
  await unlinkIfPresent(destination)
  await writeFile(destination, data)
  covers[id] = destination
  writeCoverCache(covers)
  if (previousPath && previousPath !== destination) {
    await unlinkIfPresent(previousPath)
  }
  return destination
}

function updateMetadata(id, metadata) {
  const files = readUserFiles()
  const index = files.findIndex((file) => file.id === id)
  if (index < 0) return
  files[index] = {
    ...files[index],
    metadata,
    summary: metadata.summary || files[index].summary
  }
  writeUserFiles(files)
}

module.exports = {
  BUILTIN_FILES,
  LIBRARY_DIR,
  formatDate,
  formatSize,
  getAllFiles,
  getFileById,
  importTempFile,
  importTempFiles,
  prepareShareFileSync,
  readFile,
  readFileWithProgress,
  removeFile,
  saveCover,
  updateMetadata,
  validateRiveFile
}
