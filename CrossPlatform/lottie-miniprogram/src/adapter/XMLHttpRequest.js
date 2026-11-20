const _url = new WeakMap()
const _method = new WeakMap()
const _requestHeader = new WeakMap()
const _responseHeader = new WeakMap()
const _requestTask = new WeakMap()

function _triggerEvent(type, ...args) {
  if (typeof this[`on${type}`] === 'function') {
    this[`on${type}`](...args)
  }
}

function _changeReadyState(readyState) {
  this.readyState = readyState
  _triggerEvent.call(this, 'readystatechange')
}

export default class XMLHttpRequest {
  // Not supported: the HEADERS_RECEIVED and LOADING states cannot be simulated. 没法模拟 HEADERS_RECEIVED 和 LOADING 两个状态
  static UNSEND = 0
  static OPENED = 1
  static HEADERS_RECEIVED = 2
  static LOADING = 3
  static DONE = 4

  /*
   * Known limit: these events belong on XMLHttpRequestEventTarget.prototype. 这一批事件应该是在 XMLHttpRequestEventTarget.prototype 上面的
   */
  onabort = null
  onerror = null
  onload = null
  onloadstart = null
  onprogress = null
  ontimeout = null
  onloadend = null

  onreadystatechange = null
  readyState = 0
  response = null
  responseText = null
  responseType = ''
  responseXML = null
  status = 0
  statusText = ''
  upload = {}
  withCredentials = false

  constructor() {
    _requestHeader.set(this, {
      'content-type': 'application/x-www-form-urlencoded'
    })
    _responseHeader.set(this, {})
  }

  abort() {
    const myRequestTask =  _requestTask.get(this)

    if (myRequestTask) {
      myRequestTask.abort()
    }
  }

  getAllResponseHeaders() {
    const responseHeader = _responseHeader.get(this)

    return Object.keys(responseHeader).map((header) => {
      return `${header}: ${responseHeader[header]}`
    }).join('\n')
  }

  getResponseHeader(header) {
    return _responseHeader.get(this)[header]
  }

  open(method, url/* async, user, password 这几个参数在小程序内不支持*/) {
    _method.set(this, method)
    _url.set(this, url)
    _changeReadyState.call(this, XMLHttpRequest.OPENED)
  }

  overrideMimeType() {
    // [EN] Not supported by wx.request: the response type is not overridden. [CN] wx.request 不支持：不覆盖响应类型。
  }

  send(data = '') {
    if (this.readyState !== XMLHttpRequest.OPENED) {
      throw new Error("Failed to execute 'send' on 'XMLHttpRequest': The object's state must be OPENED.")
    } else {
      // [EN] Kept so abort() can cancel the request (it read a task that was never stored).
      // [CN] 保存请求任务，abort() 才能取消请求（此前读取的任务从未被保存）。
      _requestTask.set(this, wx.request({
        data,
        url: _url.get(this),
        method: _method.get(this),
        header: _requestHeader.get(this),
        // responseType: this.responseType,
        success: ({ data, statusCode, header }) => {
          if (typeof data !== 'string' && !(data instanceof ArrayBuffer)) {
            try {
              data = JSON.stringify(data)
            } catch (e) {
            }
          }

          this.status = statusCode
          _responseHeader.set(this, header)
          _triggerEvent.call(this, 'loadstart')
          _changeReadyState.call(this, XMLHttpRequest.HEADERS_RECEIVED)
          _changeReadyState.call(this, XMLHttpRequest.LOADING)

          this.response = data

          if (data instanceof ArrayBuffer) {
            this.responseText = ''
            const bytes = new Uint8Array(data)
            const len = bytes.byteLength

            for (let i = 0; i < len; i++) {
              this.responseText += String.fromCodePoint(bytes[i])
            }
          } else {
            this.responseText = data
          }
          _changeReadyState.call(this, XMLHttpRequest.DONE)
          _triggerEvent.call(this, 'load')
          _triggerEvent.call(this, 'loadend')
        },
        fail: ({ errMsg }) => {
          // Known limit: a deviation from the specification. 规范错误
          if (errMsg.includes('abort')) {
            _triggerEvent.call(this, 'abort')
          } else {
            _triggerEvent.call(this, 'error', errMsg)
          }
          _triggerEvent.call(this, 'loadend')
        }
      }))
    }
  }

  setRequestHeader(header, value) {
    const myHeader = _requestHeader.get(this)

    myHeader[header] = value
    _requestHeader.set(this, myHeader)
  }
}
