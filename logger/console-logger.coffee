window.logger = (->
  p = (level, msgs) ->
    _args = ["[#{level}]\t"]
    for msg in msgs
      _args.push if typeof msg == 'function' then msg() else msg
    console.log.apply console, _args
  l = ->
    l.info.apply l, arguments
  l.debug = ->
    return  if !$args.debug
    _args = [new Date().toString()]
    for m in arguments
      _args.push m
    p "DEBUG", _args
  l.info = ->
    p "INFO", arguments
  l.error = ->
    p "ERROR", arguments
  l.warn = ->
    p "WARN", arguments
  return l
)()
