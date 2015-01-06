# Run this config: phantomjs --output-encoding=gbk main.coffee --config=examples/ip138-config --ip=8.8.8.8

module.exports = [
  {
    type: "request"
    url: (args) ->
      "http://www.ip138.com/ips138.asp?ip=" + args.ip + "&action=2"
  }
  {
    type: "waitFor"
    selector: "h1"
  }
  {
    selector: "h1"
    extract: "text"
    name: "ip"
  }
  {
    selector: ".ul1 li"
    extract: "text"
    name: "addr"
    resultType: "list"
  }
  (args, result) ->
    result.ip = result.ip.substring(result.ip.indexOf(":") + 1)
    return
]