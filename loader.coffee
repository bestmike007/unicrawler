phantom.injectJs './premise.coffee'
fs = require 'fs'
WebPage = require("webpage")

raw_download = (url, data) ->
  new Promise((f, r) ->
    page = WebPage.create()
    page.settings.webSecurityEnabled = false
    i = setTimeout ->
      page.close()
      r "timeout"
    , 10000
    page.onCallback = (err, data) ->
      page.close()
      clearTimeout i
      if err then r err else f data
    page.open "about:blank"
    page.evaluate (req) ->
      xhr = new XMLHttpRequest()
      xhr.overrideMimeType("text/plain; charset=x-user-defined")
      xhr.timeout = 30
      xhr.open (if req.data then "POST" else "GET"), req.url, true
      xhr.onload = (e) ->
        callPhantom null, e.currentTarget.response
      xhr.onerror = (e) ->
        callPhantom e
      xhr.ontimeout = ->
        callPhantom "timeout"
      if req.data
        xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded")
        xhr.setRequestHeader("Content-length", req.data.length)
        xhr.setRequestHeader("Connection", "close")
      xhr.send(req.data)
    , {
      url: url
      data: data
    }
  )

save_data = (p, filename) ->
  if filename
    p = p.then (data) ->
      fs.write(filename, data, 'wb')
      Promise.resolve data
  return p

Loader =
  request: raw_download
  download: (url, filename) ->
    save_data raw_download(url), filename
  download_json: (url, filename) ->
    Loader.download(url, filename).then (data) ->
      Promise.resolve JSON.parse(data)
  download_base64: (url, filename) ->
    Loader.download(url, filename).then (data) ->
      Promise.resolve helpers.base64Encode(data)
  require_remote: (url) ->
    raw_download(url).then (data) ->
      new Promise((f) ->
        eval data
        f data
      )

module.exports = Loader
