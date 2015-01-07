# Run this file: phantomjs main.coffee --file=examples/run-file.coffee

factory = require './webpage-factory'
executor = require './executor'

new Promise((f, r)->
  r "??"
).then(->
  logger.info "OK"
, ->
  logger.info "Error"
).then(->
  logger.info "Finally"
)

logger.info new Date
page = factory.createPage()

config = [
  selector: 'body'
  extract: 'text'
  name: 'data'
]

executor.run page, config, url: 'http://bestmike007.com/uploads/user-agents.json', (result) ->
  logger.info JSON.stringify(result)
  logger.info new Date
  page.close()  
  phantom.exit()