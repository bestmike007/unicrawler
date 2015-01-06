run = (context, config) ->
  selector = config.selector
  if typeof selector isnt 'function' and typeof selector isnt 'string'
    return new Promise((f, r) -> r new Error("Invalid selector #{selector.toString()}"))
  return new Promise((f, r) ->
    context.page.initSizzle()
    value = context.args[config.ref]  if config.value is `undefined` and config.ref isnt `undefined`
    rs = context.page.evaluate((conf) ->
      try
        elements = if typeof conf.selector is 'string' then Sizzle conf.selector else conf.selector()
        return err: new Error("Got nothing from url #{document.location} with selector #{conf.selector}")  if not Array.isArray(elements) or elements.length is 0
        return err: new Error("Element index out of bound from url #{document.location} with selector #{conf.selector}")  if conf.elementIndex isnt `undefined` and conf.elementIndex >= elements.length
        element = elements[conf.elementIndex]
        switch conf.event
          when "type", "enter"
            return err: new Error("Value is not specified to type into element from selector #{conf.selector}")  if !conf.value
            element.value = conf.value
            return result: true
          else
            event = document.createEvent("HTMLEvents")
            event.initEvent conf.event, true, true
            element.dispatchEvent event
            return result: true
      catch e
        return err: e
    , 
      selector: selector
      elementIndex: config.elementIndex or 0
      event: config.event
      value: value
    )
    if rs.err then r new Error rs.err.message else f context
  )

module.exports =
  run: run