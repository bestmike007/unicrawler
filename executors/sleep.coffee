run = (context, config) ->
  new Promise((f) ->
    ms = parseInt(config.ms or config.time)
    context.log "Sleep for #{ms}ms."
    setTimeout ->
      f context
    , ms
  )

module.exports = run: run