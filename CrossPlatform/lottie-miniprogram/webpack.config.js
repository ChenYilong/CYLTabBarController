const path = require('node:path')
const webpack = require('webpack')
const fs = require('node:fs')
const CopyPlugin = require('copy-webpack-plugin')

module.exports = {
  entry: './src/index.js',
  output: {
    libraryTarget: 'commonjs',
    filename: 'index.js',
    path: path.resolve(__dirname, 'miniprogram_dist'),
  },
  devtool: '',
  module: {
    rules: [{
      test: /\.js$/i,
      use: [{
        loader: 'babel-loader',
        options: {
          presets: ['@babel/preset-env'],
          plugins: ['@babel/plugin-proposal-class-properties'],
          sourceType: 'unambiguous',
        },
      }, {
        loader: 'string-replace-loader',
        options: {
          multiple: [{
            search: '/* __LOTTIE_CANVAS__ */',
            replace: fs.readFileSync('./node_modules/lottie-web/build/player/lottie_light_canvas.js', {encoding: 'utf8'}),
          }, {
            // [EN] The UMD header uses `globalThis` first; in a mini program the result must go to `window` (`this`).
            // [CN] UMD 头部优先使用 `globalThis`；在小程序中结果必须写到 `window`（`this`）。
            search: "typeof globalThis !== 'undefined' ? globalThis : global || self",
            replace: 'global || self',
          }, {
            search: '__[STANDALONE]__',
            replace: '',
          }]
        },
      }, 'eslint-loader'],
      exclude: /node_modules/
    }]
  },
  amd: false,
  plugins: [
    new webpack.DefinePlugin({
      'define': {}
    }),
    new webpack.optimize.ModuleConcatenationPlugin(),
    new CopyPlugin({
      patterns: [
        { 
          from: path.resolve(__dirname, 'src', 'index.d.ts'), 
          to: path.resolve(__dirname, 'miniprogram_dist', 'index.d.ts')
        },
        {
          // [EN] The license travels with the built package (docs/License-Notices.md). [CN] 协议文件随构建产物发布（docs/License-Notices.md）。
          from: path.resolve(__dirname, 'LICENSE'),
          to: path.resolve(__dirname, 'miniprogram_dist', 'LICENSE')
        },
        {
          // [EN] The cyl-lottie component, copied as is (it requires ../index.js). [CN] cyl-lottie 组件，原样复制（它引用 ../index.js）。
          from: path.resolve(__dirname, 'src', 'cyl-lottie'),
          to: path.resolve(__dirname, 'miniprogram_dist', 'cyl-lottie'),
          globOptions: {ignore: ['**/._*']},
        },
      ],
    }),
  ],
}
