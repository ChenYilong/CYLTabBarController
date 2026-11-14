module.exports = {
  root: true,
  parser: "babel-eslint",
  parserOptions: {
    ecmaVersion: 2018,
    sourceType: 'module'
  },
  env: {
    es6: true,
    node: true
  },
  extends: [
    "eslint:recommended"
  ],
  globals: {
    'XMLHttpRequest': true,
    'window': true,
    'document': true,
    'navigator': true,
    'wx': true
  },
  rules: {
    'no-console': process.env.NODE_ENV !== 'production' ? 0 : 2,
    'no-useless-escape': 0,
    'no-empty': 0
  }
}
