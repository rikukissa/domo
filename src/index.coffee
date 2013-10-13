colors = require 'colors'
irc    = require 'irc'
_      = require 'underscore'
util   = require 'util'

class module.exports extends irc.Client
  constructor: ->
    @middlewares = []
    @modules = {}

    super

    @on 'error', (event) -> @error JSON.stringify event.command.toUpperCase()

    @load module for module in @opt.modules if @opt.modules?

  connect: ->
    @info "Connecting to #{@opt.server}"

    super

    @once 'registered', -> @info "Connected to #{@opt.server}"

  log: -> util.log arg, colors: true for arg in arguments

  info: ->
    for arg in arguments
      util.log 'Info: '.green + util.inspect arg, colors: true

  warn: ->
    for arg in arguments
      util.log 'Warn: '.yellow + util.inspect arg, colors: true

  error: ->
    for arg in arguments
      util.log 'Error: '.red + util.inspect arg, colors: true

  load: (mod, cb) =>
    try
      module = require(mod)
    catch err
      msg = if err.code is 'MODULE_NOT_FOUND'
        "Module #{mod} not found"
      else
        "Module #{mod} cannot be loaded"

      @error msg
      return cb?(msg)

    if @modules.hasOwnProperty mod
      msg = "Module #{mod} already loaded"
      @error msg
      return cb?(msg)

    @info "Loaded module #{mod}"

    module = new Module(@) if typeof Module is 'function'

    @modules[mod] = module

    module.init?(@)

    cb? null

  stop: (mod, cb) =>
    unless @modules.hasOwnProperty mod
      msg = "Module #{mod} not loaded"
      @error msg
      return cb?(msg)

    @modules[mod].destruct?()
    delete require.cache[require.resolve(mod)]
    delete @modules[mod]

    @info "Stopped module #{mod}"

    cb? null

  addListener: (event, middlewares..., fn) ->
    super event, @wrap fn, middlewares

  on: -> @addListener arguments...

  once: (event, middlewares..., fn) -> super event, @wrap fn, middlewares

  wrap: (fn, middlewares) -> (args...) =>
    _.reduceRight(@middlewares.concat(middlewares), (memo, item) =>
      next = => memo.apply @, args
      return -> item.apply @, [args..., next]
    , fn).apply @, arguments

  use: -> @middlewares.push arguments...
