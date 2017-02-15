loader = require './loader'

test "Download raw data", ->
  loader.download("https://raw.githubusercontent.com/bestmike007/bestmike007.github.io/master/CNAME").then((data) ->
    expect(data).to match(/^bestmike007\.com/)
  )

test "download using post scheme", ->
  loader.request("http://www.ipligence.com/geolocation", 'ip=8.8.8.8').then((data) ->
    expect(data).to match(/Your IP address is 8.8.8.8/)
  )
