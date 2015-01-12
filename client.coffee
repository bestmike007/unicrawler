phantom.injectJs './premise.coffee'

factory = require './webpage-factory'
executor = require './executor'

###
The client program communicate with server and pull tasks to execute
Features:
  1. Load and cache task config
  2. Blocking detection and task rejection
  3. Task execution
  4. Submit result
Execution:
  1. Load process config
    + CrawlerName
    + IP Address
    + Worker count
    + Worker ID (Use a start timestamp to identify each worker)
    + Endpoint Url
  2. Start task config loader with cache
  3. Start task agent with blocking detection feature
  4. Start workers
Worker loop:
  1. Fetch a crawler task
    + id: task identity
    + config_name: Task config name
    + args: Task arguments
  2. Load task config from task config loader
    + steps: Execution steps
    + block_detection: Blocking detection logic
  3. Execute task steps with args
  4. Test if the crawler is blocked by target website
  5. Submit result
###

system = require 'system'
crawler_name = $args.name || (if system.os.name is 'windows' then system.env['COMPUTERNAME'] else null)
worker_count = Math.max($args.worker || 1, 1) || 1
endpoint = $args.endpoint
workers = []

ConfigLoader = (->
  cached = {}
  page = null
  loadConfig = (config_name) ->
    # use page to load config
    new Promise (f, r) ->
      if !page or page.counts > 100
        page.close()  if page
        page = factory.createPage('min')
        page.counts = 0
      page.counts++
      config = [
        type: 'request'
        url: endpoint
        data: {
          op: 'config'
          config_name: config_name
        }
      ,
        type: 'waitFor'
        selector: 'pre'
      ,
        selector: 'pre'
        extract: 'html'
        name: 'config'
      ]
      executor.run page, config, {}, (result) ->
        try
          return r result.error  if result.error
          _conf = helpers.parseConfig(result.config)
          if _conf.block_detection == '' or !_conf.block_detection
            delete _conf.block_detection
          else
            _conf.block_detection = helpers.parseConfig "function(args, result) { #{_conf.block_detection} }"
          f _conf
        catch e
          logger.error "Fail to parse config, error: #{e}, data: #{JSON.stringify result}"
          f null
  queue = []
  handle = ->
    return  if queue.length == 0
    request = queue.shift()
    if cached[request.config_name] and (new Date - cached[request.config_name].load_at) <= 60000
      setTimeout -> request.f cached[request.config_name].config
      setTimeout -> handle()
      return
    loadConfig(request.config_name).then((config)->
      cached[request.config_name] =
        load_at: new Date
        config: config
      setTimeout -> request.f config
      setTimeout -> handle()
    , (err) ->
      setTimeout -> request.r err
      setTimeout -> handle()
    )
    return
  me =
    getConfig: (config_name) ->
      delete cached[config_name]  if cached[config_name] and (new Date - cached[config_name].load_at) > 60000
      return Promise.resolve cached[config_name].config  if cached[config_name]
      return new Promise (f, r) ->
        idle = queue.length == 0
        queue.push (
          f: f
          r: r
          config_name: config_name
        )
        if idle
          setTimeout -> handle()
    clear: ->
      cached = {}

  return me
)()

TaskAgent = (->
  acl = {} # key: rule, value: due to
  submitted = 0
  queue = []
  page = null
  handle = () ->
    return  if queue.length == 0
    request = queue.shift()
    r = (err) ->
      setTimeout -> request.r err
      while queue.length > 0
        (->
          req = queue.shift()
          setTimeout -> req.r err
        )()
    f = (task) ->
      if task isnt null
        setTimeout -> request.f task
        setTimeout -> handle()
        return
      setTimeout -> request.f null
      while queue.length > 0
        (->
          req = queue.shift()
          setTimeout -> req.f null
        )()
    # post endpoint, args: { op: 'get', crawler: crawler_name, worker: worker_id, acl: acl.keys.join(' ') }
    if !page or page.counts > 100
      page.close()  if page
      page = factory.createPage('min')
      page.counts = 0
    page.counts++
    _acl = []
    for k, v of acl
      if (new Date() - v) > 0
        delete acl[k]
        continue
      _acl.push k
    
    config = [
      type: 'request'
      url: endpoint
      data: {
        op: 'get'
        crawler: crawler_name
        worker: request.worker_id
        acl: _acl.join(' ')
        v: $args.version
      }
    ,
      type: 'waitFor'
      selector: 'pre'
    ,
      selector: 'pre'
      extract: 'html'
      name: 'task'
    ]
    executor.run page, config, {}, (result) ->
      try
        return r result.error  if result.error
        task = helpers.parseConfig(result.task)
        return f null  if task is null
        task.args = helpers.parseConfig task.args  if typeof task.args is 'string'
        if !task.config_name
          setTimeout -> r new Error "Got invalid task: #{JSON.stringify task}"
          return
        f task
      catch e
        setTimeout -> r new Error "Fail to parse task, error: #{e}, data: #{JSON.stringify result}"
  me =
    getTask: (worker_id) ->
      # post endpoint, args: { op: 'get', crawler: crawler_name, worker: worker_id, acl: acl.keys.join(' ') }
      new Promise (f, r) ->
        idle = queue.length == 0
        queue.push (
          f: f
          r: r
          worker_id: worker_id
        )
        if idle
          setTimeout -> handle()

    submitResult: (worker_id, task_id, status, result) ->
      # due to memory leak issues of phantomjs. Restart the client every 1,000 tasks.
      submitted++
      if submitted > 1000
        for worker in workers
          worker.stop()
        return
      # post endpoint, args: { op: 'submit', crawler: crawler_name, worker: worker_id, task_id: task_id, status: status, result: JSON.stringify(result) }
      new Promise (f, r) ->
        _page = factory.createPage('min')
        _acl = []
        for k, v of acl
          _acl.push k
        
        config = [
          type: 'request'
          url: endpoint
          data: {
            op: 'submit'
            crawler: crawler_name
            worker: worker_id
            task_id: task_id
            status: status
            result: JSON.stringify result
          }
        ,
          type: 'waitFor'
          selector: 'pre'
        ,
          selector: 'pre'
          extract: 'html'
          name: 'task'
        ]
        executor.run _page, config, {}, (result) ->
          try
            _page.close()
            return r result.error  if result.error
            f helpers.parseConfig(result.task)
          catch e
            logger.error "Fail to parse submit result, error: #{e}, data: #{JSON.stringify result}"
            f null

    block: (config_name, till) ->
      acl['-' + config_name] = till
      Promise.resolve(config_name)
  return me
)()

startWorker = () ->
  worker_id = new Date().getTime() * 100 + parseInt(Math.random() * 100)
  running = false
  worker = null
  execute = ->
    context = {}
    running = true
    worker = TaskAgent.getTask(worker_id).then((task) ->
      context.task = task
      if !task
        return new Promise (f) ->
          logger.debug "No more tasks, waiting..."
          setTimeout ->
            f null
          , 1000
      task.args.client_ip = task.client_ip
      logger.debug "Loaded task: #{JSON.stringify task}"
      ConfigLoader.getConfig(task.config_name)
    ).then((config) ->
      context.config = config
      if config is null and context.task isnt null
        return Promise.resolve error: "Config `#{context.task.config_name}` not found."
      return Promise.resolve(null)  if config is null
      logger.debug "Loaded config: #{JSON.stringify config}"
      context.page = factory.createPage(config.profile)
      new Promise (f) ->
        if context.config.execution_interval > 0
          TaskAgent.block context.task.config_name, new Date(new Date().getTime() + context.config.execution_interval)
        executor.run context.page, helpers.parseConfig(config.steps), context.task.args, f
    ).then((result) ->
      return Promise.resolve(null)  if result is null
      try
        if context.config && typeof context.config.block_detection is 'function' && context.config.block_detection context.task.args, result
          TaskAgent.block context.task.config_name, new Date(new Date().getTime() + 1000 * context.config.recover)
          context.result_status = 'blocked'
        else
          context.result_status = if result.error then 'error' else 'success'
      catch e
        context.result_status = 'error'
        result.warn = "Unable to execute block detection, error: #{e}"
      TaskAgent.submitResult worker_id, context.task.id, context.result_status, result 
    ).then(->
      context.page.close()  if context.page
      worker = null
      running = false
    , (err) ->
      logger.error "Fail to execute task, error: #{err}. Context: #{JSON.stringify context}"
      context.page.close()  if context.page
      setTimeout ->
        worker = null
        running = false
      , 1000
    )
  i = setInterval ->
    return if running
    execute()
  , 100
  me =
    stop: ->
      clearInterval i
      i = null
    stopped: ->
      i is null && worker is null
  return me

if !endpoint
  logger.error "Endpoint is not specified."
  phantom.exit -1

new Promise((f) ->
  if !crawler_name && system.os.name is 'linux'
    process = require "child_process"
    process.execFile 'hostname', [], null, (err, stdout) ->
      crawler_name = stdout.toString().trim()
      if !crawler_name
        logger.error "Please specify your crawler name."
        phantom.exit()
      crawler_name = escape crawler_name
      f true
  else
    crawler_name = escape crawler_name
    f true
).then(->
  logger.debug "Starting crawler #{crawler_name} for #{worker_count} worker(s)."
  for i in [0...worker_count]
    workers.push startWorker()
, (err) -> logger.error err)

setInterval ->
  alive = false
  for worker in workers
    alive = true  if !worker.stopped()
  if !alive
    phantom.exit(0)
, 1000