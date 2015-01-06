phantom.injectJs './premise.coffee'

Loader = require './loader'

Loader.download("http://bestmike007.com/uploads/user-agents.json").then((str) ->
  logger.info str
  phantom.exit 0
, (err) ->
  logger.error err
)