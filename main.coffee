phantom.injectJs './premise.coffee'
Loader = require './loader'

if $args.test
  require('./test-helper').run()
else if $args.config
  factory = require './webpage-factory'
  executor = require './executor'
  p = if $args.config.match /^https?:\/\//
        Loader.download_json($args.config)
      else if $args.config.match /^[\/\.]/
        Promise.resolve(require($args.config))
      else
        Promise.resolve(require('./' + $args.config))
  p.then((config) ->
    page = factory.createPage($args.profile)
    executor.run page, config, $args, (result) ->
      logger.info JSON.stringify result
      page.close()
      phantom.exit 0
  )
else if $args.file
  if $args.file.match /^https?:\/\//
    Loader.require_remote($args.file)
  else if $args.file.match /^[\/\.]/
    phantom.injectJs $args.file
  else
    phantom.injectJs './' + $args.file
else if $args.endpoint
  phantom.injectJs './client.coffee'
else
  logger.info "View https://github.com/bestmike007/unicrawler for usage."
  phantom.exit 0
