phantom.injectJs './premise.coffee'
WebPage = require("webpage")

toUtf8 = (str, cb) ->
  utf8page = WebPage.create()
  utf8page.onCallback = (err, data) ->
    setTimeout -> utf8page.close()
    cb data
  utf8page.evaluate (str) ->
    document.head.innerHTML = '<meta http-equiv="Content-Type" content="text/html; charset=gbk" />'
    script = document.createElement('script')
    script.src = "data:text/javascript;charset=gbk,callPhantom(null, '#{str}');"
    document.body.appendChild(script)
  , escape(str)

atob_utf8 = (str) ->
  toUtf8(atob(str))

parseConfig = (conf) ->
  (new Function("var Object,Array,Function,Number,Math,ArrayBuffer,Boolean,DataView,Date,Error,EvalError,Float32Array,Float64Array,Infinity,Intl,InternalError,Int16Array,Int32Array,Int8Array,Iterator,JSON,NaN,RangeError,ReferenceError,RegExp,StopIteration,String,SyntaxError,TypeError,Uint16Array,Uint32Array,Uint8Array,Uint8ClampedArray,URIError,#{Object.keys(global).join(",")};return #{conf}"))()

base64Encode = (str) ->
  CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  out = ""
  i = 0
  len = str.length
  c1 = undefined
  c2 = undefined
  c3 = undefined
  while i < len
    c1 = str.charCodeAt(i++) & 0xff
    if i is len
      out += CHARS.charAt(c1 >> 2)
      out += CHARS.charAt((c1 & 0x3) << 4)
      out += "=="
      break
    c2 = str.charCodeAt(i++)
    if i is len
      out += CHARS.charAt(c1 >> 2)
      out += CHARS.charAt(((c1 & 0x3) << 4) | ((c2 & 0xf0) >> 4))
      out += CHARS.charAt((c2 & 0xf) << 2)
      out += "="
      break
    c3 = str.charCodeAt(i++)
    out += CHARS.charAt(c1 >> 2)
    out += CHARS.charAt(((c1 & 0x3) << 4) | ((c2 & 0xf0) >> 4))
    out += CHARS.charAt(((c2 & 0xf) << 2) | ((c3 & 0xc0) >> 6))
    out += CHARS.charAt(c3 & 0x3f)
  out

module.exports =
  atob: atob_utf8
  atob_utf8: atob_utf8
  parseConfig: parseConfig
  base64Encode: base64Encode
  toUtf8: toUtf8