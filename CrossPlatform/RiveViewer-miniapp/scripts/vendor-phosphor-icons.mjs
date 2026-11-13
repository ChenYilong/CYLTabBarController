import fs from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const sourceRoot = path.join(root, 'node_modules/@phosphor-icons/core/assets/bold')
const targetRoot = path.join(root, 'assets/icons')

const icons = [
  ['arrow-left.svg', 'arrow-left', '#d8dde5'],
  ['arrow-right.svg', 'arrow-right', '#d8dde5'],
  ['arrows-in-simple.svg', 'arrows-in-simple', '#aeb7c3'],
  ['arrows-in-simple-active.svg', 'arrows-in-simple', '#f2c94c'],
  ['arrows-out-simple.svg', 'arrows-out-simple', '#aeb7c3'],
  ['arrows-out-simple-active.svg', 'arrows-out-simple', '#f2c94c'],
  ['chevron-down.svg', 'caret-down', '#96a2b2'],
  ['copy-simple.svg', 'copy-simple', '#f2c94c'],
  ['download.svg', 'download-simple', '#f2c94c'],
  ['gauge.svg', 'gauge', '#f2c94c'],
  ['player-pause.svg', 'pause', '#d8dde5'],
  ['player-play.svg', 'play', '#d8dde5'],
  ['plus.svg', 'plus', '#17130a'],
  ['restore.svg', 'arrow-counter-clockwise', '#17130a'],
  ['caret-left.svg', 'caret-left', '#f2f0e8'],
  ['house.svg', 'house', '#f2f0e8'],
  ['circle-notch.svg', 'circle-notch', '#aeb7c3'],
]

await fs.mkdir(targetRoot, { recursive: true })

const miniIcons = process.argv.includes("--h5-only") ? [] : icons
for (const [targetName, sourceName, color] of miniIcons) {
  const sourcePath = path.join(sourceRoot, `${sourceName}-bold.svg`)
  const targetPath = path.join(targetRoot, targetName)
  const source = await fs.readFile(sourcePath, 'utf8')
  const output = source
    .replace(
      'fill="currentColor"',
      `fill="${color}" stroke="${color}" stroke-width="8" stroke-linejoin="round" data-icon-family="phosphor" data-icon-name="${sourceName}" data-icon-weight="bold" data-icon-optical-stroke="8"`
    )
    .trim()
  await fs.writeFile(targetPath, `${output}\n`)
}

console.log(`Vendored ${miniIcons.length} Mini Program Phosphor Bold icons.`)

const h5TargetRoot = path.join(root, "h5/public/rive-viewer/icons")
const h5Icons = ['archive', 'arrow-counter-clockwise', 'arrow-left', 'arrow-right', 'arrow-square-out', 'arrows-in-simple', 'arrows-out-simple', 'caret-down', 'chat-circle-dots', 'check', 'cloud-arrow-up', 'cloud-check', 'cloud-x', 'copy-simple', 'desktop', 'download-simple', 'gauge', 'keyboard', 'link-simple', 'pause', 'pencil-simple', 'play', 'plus', 'share-network', 'speaker-high', 'speaker-slash', 'trash', 'wechat-logo', 'x']
await fs.mkdir(h5TargetRoot, { recursive: true })
for (const name of h5Icons) {
  const source = await fs.readFile(path.join(sourceRoot, `${name}-bold.svg`), 'utf8')
  const output = source.replace('fill="currentColor"', `fill="#000" data-icon-family="phosphor" data-icon-name="${name}" data-icon-weight="bold"`).trim()
  await fs.writeFile(path.join(h5TargetRoot, `${name}.svg`), `${output}\n`)
}
console.log(`Vendored ${h5Icons.length} H5 Phosphor Bold icons.`)
