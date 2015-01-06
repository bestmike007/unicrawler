run = (context, config) ->
  unless typeof config.name is "string"
    return new Promise((f, r) -> r new Error("Name (type of string) expected for extract operation!"))
  # validate attr & formatter
  if config.extract is "attr" and typeof config.attr is "undefined"
    return new Promise((f, r) -> r new Error("Attribute key is not defined for selector: " + config.selector))
  if typeof config.format is "undefined"
    config.format = (v) -> v
  unless typeof config.format is "function"
    return new Promise((f, r) -> r new Error("Expected formatter: " + config.format.toString()))
  # validate selector & query elements
  selector = config.selector
  if typeof selector isnt 'function' and typeof selector isnt 'string'
    return new Promise((f, r) -> r new Error("Invalid selector #{selector.toString()}"))
  # validate element index
  if config.resultType is "list"
    delete config.elementIndex
  else
    config.elementIndex = config.elementIndex or 0
  unless typeof config.elementIndex is "undefined"
    elementIndex = config.elementIndex
    elementIndex = parseInt elementIndex  if typeof elementIndex is "string" and elementIndex.match(/^\d+$/i)
    unless typeof elementIndex is "number"
      return new Promise((f, r) -> r new Error("Expected value for elementIndex: " + elementIndex.toString()))
  if config.ignore_not_found is `undefined`
    config.ignore_not_found = config.resultType is 'list'

  return new Promise((f, r) ->
    context.log "Extracting for `#{config.name}` from url `#{context.page.url}` with config: #{JSON.stringify config}"
    context.page.initSizzle()

    rs = context.page.evaluate((conf) ->
      try
        conf.format = eval "(#{conf.format})"
        # perform extract operation
        getValue = (el) ->
          switch conf.extract
            when "text"
              return conf.format el.textContent
            when "html"
              return conf.format el.innerHTML
            when "outerHtml"
              return conf.format el.outerHTML
            when "attr"
              return conf.format el.getAttribute(conf.attr)
            else
              throw new Error("Unknown extract type: " + conf.extract)
        elements = if typeof conf.selector is "string" then Sizzle conf.selector else conf.selector()
        if not Array.isArray(elements) or elements.length is 0
          if conf.ignore_not_found
            return result: if conf.listResult then [] else null
          return err: new Error("Got nothing from url #{document.location} with selector #{conf.selector}")
        if conf.elementIndex isnt `undefined` and conf.elementIndex >= elements.length
          if conf.ignore_not_found
            return result: if conf.listResult then [] else null
          return err: new Error("Element index out of bound from url #{document.location} with selector #{conf.selector}")
        elements = [elements[conf.elementIndex]]  if conf.elementIndex isnt `undefined`
        if conf.listResult
          rs = []
          for _el in elements
            rs.push getValue _el
          return result: rs
        else
          return result: getValue elements[0]
      catch e
        return err: e
    ,
      selector: selector
      elementIndex: elementIndex
      listResult: config.resultType is "list"
      extract: config.extract
      attr: config.attr
      ignore_not_found: config.ignore_not_found
      format: config.format.toString()
    )
    if rs.err
      return r new Error rs.err.message
    rs = rs.result
    if config.merge
      result = []
      if typeof context.result[config.name] isnt "undefined"
        Array::push.apply result, (if Array.isArray(context.result[config.name]) then context.result[config.name] else [context.result[config.name]])
      if typeof rs isnt "undefined"
        Array::push.apply result, (if Array.isArray(rs) then rs else [rs])  
      context.result[config.name] = result
    else
      context.result[config.name] = rs
    context.log "End extracting `#{config.name}`."
    f context
  )

module.exports = run: run