run = (context, config) ->
  new Promise (f, r) ->
    context.log "Waiting for element `#{config.selector}`, timeout #{config.tries || 10} seconds."
    context.page.waitFor config.selector, config.tries || 10, (success) ->
      if success
        f(context)
      else
        context.page.render "screen.png"
        if config.fallback
          if typeof config.fallback is 'boolean'
            f context
          else
            promise.run_any(context, config.fallback).then(f, r)
        else
          r new Error("Unable to find #{config.selector}.")

module.exports =
  run: run