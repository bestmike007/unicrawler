open_url: (context, url) ->
  return promise.post context, url
post: (context, url, data) ->
  if url is `undefined`
    return new Promise((f, r) ->
      r(new Error("You must specify the url."))
    )
  return new Promise((f, r) ->
    url = url(context.args, context.result)  if typeof url is 'function'
    if data then context.log "Sending data to url #{url} with data #{JSON.stringify data}" else context.log "Opening #{url}"
    context.page.requestUrl url, data, (rs) ->
      if rs instanceof Error then r rs else f context
  )

run = (context, config) ->
  return if config.data is `undefined` then open_url(context, config.url) else post(context, config.url, config.data)

module.exports =
  run: run