# web page factory: create web page with profile
phantom.injectJs './premise.coffee'
WebPage = require("webpage")

# 1. load system profile
SYS_PROFILE = 
  XSSAuditingEnabled: false
  javascriptCanCloseWindows: false
  javascriptCanOpenWindows: false
  javascriptEnabled: true
  loadImages: false
  localToRemoteUrlAccessEnabled: false

# 2. load user profile
USER_PROFILE =
  loadImages: false
  disableScripts: false
  disableCss: true
  userAgent: "Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36"
  webSecurityEnabled: true
  resourceTimeout: 30000
  screenWidth: 1024
  screenHeight: 768

# 3. apply custom profile
HTML_ONLY_PROFILE =
  disableScripts: true
HEAVY_PROFILE =
  disableCss: false
  loadImages: true

# configurable configurations
CONFIGURABLE = {}
for k, v of USER_PROFILE
  CONFIGURABLE[k] = true

ALIAS =
  full: HEAVY_PROFILE
  html_only: HTML_ONLY_PROFILE
  min: HTML_ONLY_PROFILE

USER_AGENTS = [USER_PROFILE.userAgent]

me = module.exports = {}

me.createPage = (profile = 'default') ->
  profile = ALIAS[profile] if typeof(profile) == 'string'
  profile = profile || {}
  profile.userAgent = USER_AGENTS[Math.floor(Math.random() * USER_AGENTS.length)] if !profile.userAgent
  page = WebPage.create()
  for k, v of SYS_PROFILE
    page.settings[k] = v
  for k, v of USER_PROFILE
    page.settings[k] = v
  for k, v of profile
    page.settings[k] = v if CONFIGURABLE[k]
  page.viewportSize =
    width: profile.screenWidth || 1024
    height: profile.screenHeight || 768
  page.onConfirm = (msg) ->
    logger.info "Unexpected confirm dialog with message #{msg}, pressing cancel..."
    return false
  page.onAlert = (msg) ->
    logger.debug "Alert message: #{msg}"
    return
  page.onError = (msg) ->
    logger.debug "Browser script error: #{msg}"
  page.onConsoleMessage = (msg) ->
    return if msg.indexOf('Unsafe JavaScript attempt to access frame') == 0
    logger.debug "Browser console: " + msg
    return

  currentUrl = "about:blank"
  page.onInitialized = ->
    page.lastActive = new Date()
    currentUrl = page.evaluate ->
      location.toString()
    if page.onDocumentReady && typeof page.onDocumentReady is 'function'
      logger.debug "Document ready for #{currentUrl}"
      page.onDocumentReady()
  page.onNavigationRequested = (url, type, willNavigate, main) ->
    currentUrl = null  if willNavigate && main
  page.onResourceRequested = (info, req) ->
    try
      if currentUrl && !page.settings.loadImages && page.settings.disableCss && page.settings.disableScripts
        req.abort()
        return
      url = info.url
      url = url.substring(0, url.indexOf("?"))  if url.indexOf("?") > 0
      ext = url.substring(url.lastIndexOf(".") + 1, url.length).toLocaleLowerCase()
      if (page.settings.disableCss and ext is "css") or (page.settings.disableScripts and ext is "js")
        req.abort()
        return
      logger.debug "Requesting: " + info.url
      return
    catch e
      logger.warn e

  page.initSizzle = ->
    loaded = page.evaluate ->
      return document && typeof(document.createElement) == 'function'
    injected = page.evaluate -> window.Sizzle
    page.injectJs('./lib/sizzle.js')  if loaded && !injected

  page.waitFor = (selector, timeout, cb) ->
    (cb = timeout; timeout = 10) if arguments.length == 2 and typeof(timeout) == 'function'
    return if typeof cb != 'function'
    timeout = 10 if timeout < 0 || isNaN timeout
    timeout *= 10
    pass = ->
      page.initSizzle()
      return page.evaluate (selector) ->
        return selector() if typeof(selector) == 'function'
        Sizzle && Sizzle(selector).length > 0
      , selector
    if pass()
      setTimeout -> cb true
      return
    i = setInterval ->
      timeout--
      if pass()
        clearInterval i
        cb true
        return
      if timeout <= 0
        clearInterval i
        cb false
    , 100
    return

  pageInitCallback = null
  page.requestUrl = (url, data, callback) ->
    (callback = data; data = null) if arguments.length == 2 and typeof(data) == 'function'
    pageInitCallback(new Error("Page load canceled"))  if pageInitCallback and typeof(pageInitCallback) == 'function'
    pageInitCallback = callback
    i = setTimeout ->
      page.onDocumentReady()  if page.onDocumentReady
    , 10000
    page.onDocumentReady = ->
      clearTimeout i
      delete page.onDocumentReady
      pageInitCallback true if pageInitCallback
      pageInitCallback = null
    if typeof data == 'object'
      _d = []
      for k, v of data
        _d.push "#{k}=#{v}"
      data = _d.join("&")

    if data
      page.open url, 'POST', data
    else
      page.open url

  return page

# auto load latest user agents.
# http://bestmike007.com/uploads/user-agents.json
(->
  return  if USER_AGENTS.length > 1
  url = 'http://bestmike007.com/uploads/user-agents.json'
  page = me.createPage('min')
  page.onDocumentReady = ->
    return if page.url isnt url
    uaList = page.evaluate -> document.getElementsByTagName('pre')[0].innerHTML
    page.close()
    try
      userAgents = JSON.parse uaList
      USER_AGENTS = userAgents if Array.isArray(userAgents) && userAgents.length > 0
      logger.debug "#{USER_AGENTS.length} user agent strings loaded: #{JSON.stringify USER_AGENTS}"
    catch e
      logger.warn "Unable to load user agent strings from #{url}"
  page.open url
)()