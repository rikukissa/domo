_            = require 'underscore'
fs           = require 'fs'
irc          = require 'irc'
colors       = require 'colors'
Router       = require 'routes'
EventEmitter = require('events').EventEmitter

class Domo extends EventEmitter

  responseConstructor = (res, next) ->
    res.channel = res.args[0]
    res.message = res.args[1]
    res.username = res.user

    res.user = unless @authedClients.hasOwnProperty(res.prefix)
      null
    else
      @authedClients[res.prefix]

    next()

  messaging = require './lib/messaging'

  constructor: (@config) ->
    @router = new Router
    @modules = {}
    @authedClients = []
    @middlewares = []
    @config = @config || {}
    @routes = {}

    @use _.bind responseConstructor, this
    @load module for module in @config.modules if @config.modules?

  error: messaging.error
  notify: messaging.notify
  warn: messaging.warn
  say: messaging.say

  join: (channel, cb) ->
    @client.join channel, =>
      cb.apply this, arguments if cb?

  part: (channel, cb) ->
    @client.part channel, =>
      cb.apply this, arguments if cb?

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

    @notify "Loaded module #{mod}"

    module = new Module(@) if typeof Module is 'function'

    @modules[mod] = module

    # DEPRECATED
    if module.init?
      @warn "Module #{mod} uses deprecated 'init' method. Init/destruct methods are deprecated since 0.2"
      module.init(@)

    unless module.routes?
      return cb?(null)

    # Register module routes

    # Array syntax
    if _.isArray module.routes
      for route in module.routes
        @route route.path, route.handler
      return cb?(null)

    # Object syntax
    @route path, fn for path, fn of module.routes

    cb?(null)

  stop: (mod, cb) =>
    unless @modules.hasOwnProperty mod
      msg = "Module #{mod} not loaded"
      @error msg
      return cb?(msg)

    delete require.cache[require.resolve(mod)]

    module = @modules[mod]

    delete @modules[mod]

    end = =>
      @notify "Stopped module #{mod}"
      cb?(null)

    unless module.routes?
      return end()

    # Delete array style routes
    if _.isArray module.routes
      @destroyRoute route.path, route.handler for route in module.routes
      return end()

    # Delete object style routes
    @destroyRoute path, fn for path, fn of module.routes

    return cb?(null)

  connect: ->
    @notify "Connecting to server #{@config.address}."
    @client = new irc.Client @config.address, @config.nick, @config

    @client.addListener 'error', (msg) =>
      @error msg
      @emit.apply this, arguments

    @client.addListener 'registered', =>
      @notify "Connected to server #{@config.address}.\n\tChannels joined: #{@config.channels.join(', ')}"
      @emit.apply this, ['registered'].concat arguments

    @client.addListener 'message', (nick, channel, msg, res) =>
      @emit.apply this, arguments
      @matchRoutes msg, res

    @channels = @client.chans

    return @client

  disconnect: ->
    @client.disconnect()

  route: (path, middlewares..., fn) ->
    @routes[path] ?= []
    @routes[path].push
      fn: fn
      middlewares: middlewares

    @router.addRoute path, fn

  destroyRoute: (path, fn) ->

    # Destroy from router
    route = _.find @router.routes, (route) ->
      route.src is path and route.fn is fn

    index = @router.routes.indexOf route

    @router.routes.splice index, 1

    # Destroy from domo's routes
    routeItem = _.find @routes[path], (route) ->
      route.fn is fn

    itemIndex = @routes[path].indexOf routeItem

    @routes[path].splice itemIndex, 1

  matchRoutes: (path, data) ->
    return unless (result = @router.match path)?

    @routes[result.route].forEach (route) =>
      chain = @wrap route.fn, route.middlewares
      chain.call this, _.extend result, data

  wrap: (fn, middlewares) -> () =>
    args = Array.prototype.slice.call(arguments, 0)
    _.reduceRight(@middlewares.concat(middlewares), (memo, item) =>
      next = => memo.apply this, args
      return -> item.apply this, _.flatten([args, next], true)
    , fn).apply this, arguments

  use: (mw) ->
    if typeof mw is 'object'
      return mw.init(this)

    @middlewares.push mw


  authenticate: (res, next) ->
    return @error "Tried to authenticate. No users configured" unless @config.users?
    return @say res.nick, "You are already authed." if @authedClients.hasOwnProperty res.prefix

    user = res.user = _.findWhere(@config.users, {username: res.params.username, password: res.params.password})

    unless user?
      @error "User #{res.prefix} tried to authenticate with bad credentials"
      return @say res.nick, "Authentication failed. Bad credentials."

    @authedClients[res.prefix] = user

    next()

  requiresUser: (res, next) ->
    unless res.user?
      return @error "User #{res.prefix} tried to use '#{res.route}' route"
    next()

  basicRoutes: require './lib/basic-routes'

module.exports = Domo
