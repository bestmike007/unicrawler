# Run this config: phantomjs --output-encoding=gbk main.coffee --config=examples/taobao-searchbox

module.exports = [
  {
    type: "request"
    url: (args) -> "http://suggest.taobao.com/sug?code=utf-8&q=#{args.seed}&k=1&area=c2c&bucketid=3"
  }
  {
    selector: "pre"
    extract: "text"
    name: "words"
    format: (v) -> JSON.parse(v)
  }
]