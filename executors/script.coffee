run = (context, config) ->
  if typeof config.func isnt 'function'
    return new Promise((f, r) -> 
      context.log "Executing script #{(config.func || '').toString()}"
      r new Error('We need a function to execute.')
    )
  return new Promise((f, r) ->
    context.log "Executing browser script: #{config.func.toString()}"
    context.page.initSizzle()
    rs = context.page.evaluate((conf) ->
      try
        (eval "(#{conf.func})") conf.args, conf.result
        return result: conf.result
      catch e
        return err: e
    , 
      args: context.args
      result: context.result
      func: config.func.toString()
    )
    if rs.err
      r rs.err
    else
      context.result = rs.result
      f context
  )

module.exports =
  run: run