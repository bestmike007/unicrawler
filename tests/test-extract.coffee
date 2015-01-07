
factory = require './webpage-factory'
executor = require './executor'

test "Get json file", ->
  run_executor(
      selector: 'body'
      extract: 'text'
      name: 'data'
    , url: 'http://bestmike007.com/uploads/user-agents.json', 'min', (result) ->
      list = JSON.parse(result.data)
      expect(list instanceof Array).to be true
    )

test "Get github repo name", ->
  run_executor(
      selector: '.js-current-repository'
      extract: 'text'
      name: 'repo'
    , url: 'https://github.com/bestmike007/unicrawler', 'min', (result) ->
      expect(result.repo).to eq 'unicrawler'
    )

test "Get project page fork me on github image attribute", ->
  run_executor([
      type: 'waitFor'
      selector: 'a[href="https://github.com/bestmike007/unicrawler"] img'
      tries: 3
    ,
      selector: 'a[href="https://github.com/bestmike007/unicrawler"] img'
      extract: 'attr'
      attr: 'alt'
      name: 'attr'
    ], url: 'http://bestmike007.com/unicrawler/', (result) ->
      expect(result.attr).to eq 'Fork me on GitHub'
    )