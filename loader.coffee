phantom.injectJs './premise.coffee'
fs = require 'fs'
WebPage = require("webpage")

raw_download = (url) ->
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
    page.evaluate (url) ->
      xhr = new XMLHttpRequest()
      xhr.overrideMimeType("text/plain; charset=x-user-defined")
      xhr.timeout = 30
      xhr.open "GET", url, true
      xhr.onload = (e) ->
        callPhantom null, e.currentTarget.response
      xhr.onerror = (e) ->
        callPhantom e
      xhr.ontimeout = ->
        callPhantom "timeout"
      xhr.send()
    , url
  )

save_data = (p, filename) ->
  if filename
    p = p.then (data) ->
      fs.write(filename, data, 'wb')
      Promise.resolve data
  return p

Loader =
  download: (url, filename) ->
    p = raw_download(url)
    save_data p, filename
  download_json: (url, filename) ->
    p = raw_download(url).then (data) ->
      Promise.resolve JSON.parse(data)
    save_data p, filename
  download_base64: (url, filename) ->
    p = raw_download(url).then (data) ->
      Promise.resolve helpers.base64Encode(data)
    save_data p, filename
  require_remote: (url) ->
    raw_download(url).then (data) ->
      eval data
      Promise.resolve data

module.exports = Loader
