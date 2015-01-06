# use ECMAScript 6.0 Promises to stream line execution.
phantom.injectJs './premise.coffee'

###
Use executor.run(page, task_config, task_params, callback) to run a task, where:

- page: preconfigured web page object
- task_config: task configuration to run the task, array of objects/functions or bare object or function
- task_params: an object holds dynamic parameters for this task type, includes:
  - debug: debug mode or not, default: false
  - headers: custom headers to include in every HTTP request
  - cookies: an array of cookie object
  - url: initial url if provided
  - other custom params for task execution
- callback: the callback function to handle result after execution: callback(result) where:
  - result: an object to hold all results key-value pairs, in which:
    - error: the error message (override if previous execution stores an error key) if error occurs
    - debug: debug messages, e.g. execution logs, browser console errors, etc.
###
me = module.exports =
  run: (page, task_config, task_params = {}, callback) ->
    context =
      page: page
      args: task_params
      result: {}
      debug: !!task_params.debug
    context.result.debug = [] if context.debug
    context.log = (msg) ->
      logger.debug msg
      context.result.debug.push(msg) if context.debug
      return msg
    cb = ->
      Promise.resolve(context).then(->
        context.result.client_ip ||= context.args.client_ip
        if context.args.hook
          if typeof context.args.hook is 'function'
            config = context.args.hook(context.args, context.result)
          else if typeof context.args.hook is 'string' && context.args.hook.indexOf('function') == 0
            config = eval("(#{context.args.hook})")(context.args, context.result)
          else
            config = (
              url: context.args.hook
              data: JSON.stringify context.result
            )
          config.type = "request"
          return promise.run_any context, config
        return Promise.resolve(context)
      ).then(->
        if typeof callback == 'function'
          setTimeout -> callback(context.result)
      , (err) ->
        logger.debug "Error sending hook request: #{err}"
        if typeof callback == 'function'
          setTimeout -> callback(context.result)
      )
    # set headers & cookies
    ###
    customHeaders = { "Key" : "Value" }
    ###
    page.settings.customHeaders = task_params.headers  if task_params.headers
    # TODO: The cookie jar behavior is not clear?

    # execute task_config
    p = Promise.resolve(0).then(->
      return if context.args.url
        promise.run_any(context, { url: context.args.url, type: 'request' })
      else
        Promise.resolve(context)
    ).then(->
      return promise.run_any context, task_config
    ).then(->
      cb()
    , (err) ->
      context.result.error = err
      cb()
    )
    return

promise = me.promise =
  run_any: (context, step) ->
    return Promise.resolve(context)  if !step
    return promise.run_function(context, step)  if typeof(step) == 'function'
    return promise.run_object(context, step)  unless Array.isArray(step)
    return new Promise((f, r) ->
      p = Promise.resolve(context)
      for _step in step
        ((step) ->
          p = p.then ->
            promise.run_any context, step
        )(_step)
      p = p.then(->
          f context
        , (err) ->
          r err
      )
    )
  run_object: (context, step) ->
    # step.type ||= "extract" # default type is extract.
    # sub_executor = null
    try
      return require("./executors/#{step.type || "extract"}").run(context, step)
    catch e
      return new Promise((f, r) ->
        r new Error("Invalid config type #{step.type} or failed to execute, error message: #{e.toString()}\n#{e.stack}")
      )

  run_function: (context, step) ->
    return new Promise((f, r) ->
      context.log "Executing #{step.toString()}"
      try
        steps = step(context.args, context.result, context.page.url)
      catch e
        logger.debug e
      return f(context)  if !steps
      promise.run_any(context, steps).then(->
        f context
      , (err) ->
        r err
      )
    )