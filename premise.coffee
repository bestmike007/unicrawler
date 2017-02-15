# premises for executing this client
# things to override js default behavior

if !window.Promise
  phantom.injectJs './lib/es5-shim.min.js'
  phantom.injectJs './lib/promise-4.0.0.js'
  system = require 'system'
  fs = require('fs')
  window.include = (file) ->
    phantom.injectJs fs.absolute("#{phantom.libraryPath}/#{file}")

  window.$args = (->
    options = {}
    for arg in system.args
      continue if !arg.indexOf('--') == 0
      arg = arg.substring(2)
      (options[arg] = true; continue) if arg.indexOf('=') == -1
      kv = arg.split '=', 1
      options[kv[0]] = arg.substr(kv[0].length + 1)
    options
  )()

  $args.logger ||= "console-logger"
  phantom.injectJs "./logger/#{$args.logger}.coffee"

  phantom.onError = (msg, err)->
    logger.warn "Uncatched error: #{JSON.stringify msg}, Stack: #{JSON.stringify err}"

  window.helpers = require './helpers'

  if fs.isFile("./config.coffee")
    phantom.injectJs "./config.coffee"
