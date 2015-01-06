# premises for executing this client
# things to override js default behavior

if !window.Promise
  phantom.injectJs './lib/es5-shim.min.js'
  phantom.injectJs './lib/promise-4.0.0.js'
  system = require 'system'

  window.$args = (->
    options = {}
    for arg in system.args
      continue if !arg.indexOf('--') == 0
      arg = arg.substring(2)
      (options[arg] = true; continue) if arg.indexOf('=') == -1
      kv = arg.split '=', 2
      options[kv[0]] = kv[1]
    options
  )()

  $args.logger ||= "console-logger"
  phantom.injectJs "./logger/#{$args.logger}.coffee"

  phantom.onError = (msg, err)->
    logger.warn "Uncatched error: #{JSON.stringify msg}, Stack: #{JSON.stringify err}"

  window.helpers = require './helpers'
