run = (context, config) ->
  return new Promse((f, r) ->
    page = context.page
    switch config.event
      when "mouseup", "mousedown", "mousemove", "doubleclick", "click"
        page.sendEvent config.event, config.mouseX, config.mouseY
      when "keyup", "keypress", "keydown"
        if page.event.key[config.key] is `undefined`
          return r new Error("Unknown keyboard key value: " + config.key)
        mask = 0
        mask = mask | 0x02000000  if config.modifiers.indexOf("Shift") >= 0
        mask = mask | 0x04000000  if config.modifiers.indexOf("Ctrl") >= 0
        mask = mask | 0x08000000  if config.modifiers.indexOf("Alt") >= 0
        page.sendEvent config.event, page.event.key[config.key], null, null, mask
      else
        return r new Error("Unknown interaction type: " + config.event)
    f context
  )

module.exports = run: run