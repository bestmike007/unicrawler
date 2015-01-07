# Run this config: phantomjs main.coffee --config=examples/user-agents

module.exports = [
  type: 'request'
  url: 'http://www.useragentstring.com/pages/Chrome/'
,
  type: 'waitFor'
  selector: 'div#liste ul li a'
  #timeout: 30
,
  selector: 'div#liste ul li a'
  extract: 'text'
  name: 'userAgents'
  resultType: 'list'
,
  (args, result) ->
    result.userAgents = result.userAgents[0...20]
    return
]