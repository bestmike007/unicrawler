loader = require './loader'

test "Download raw data", ->
  loader.download("http://checkip.dyndns.org/").then((data) ->
    expect(data).to match(/Current IP Address: (\d+\.){3}\d+/)
  )

test "download using post scheme", ->
  loader.request("http://www.iplocation.net/", 'query=8.8.8.8&submit=Query').then((data) ->
    expect(data).to match(/Geolocation for <b><font color='green'>8.8.8.8<\/font>/)
  )