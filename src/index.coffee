_            = require 'underscore'
fs           = require 'fs'
irc          = require 'irc'
async        = require 'async'
colors       = require 'colors'
Router       = require 'routes'
EventEmitter = require('events').EventEmitter

responseConstructor = (res, next) ->
  res.channel = res.args[0]
  res.message = res.args[1]
  res.username = res.user

  res.user = unless @authedClients.hasOwnProperty(res.prefix)
    null
  else
    @authedClients[res.prefix]

  next()


class Domo extends EventEmitter
  constructor: (@config) ->
    @router = new Router
    @modules = {}
    @authedClients = []
    @middlewares = []
    @config = @config || {}
    @routes = []

    @use _.bind responseConstructor, this
    @load module for module in @config.modules if @config.modules?

  error: (msgs...) ->
    console.log 'Error:'.red, msgs.join('\n').red if @config.debug?

  notify: (msg) ->
    console.log 'Notify:'.green, msg.green

  say: (channel, msg) =>
    @client.say channel, msg

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

    module.init?(@)

    cb?(null)

  stop: (mod, cb) =>
    unless @modules.hasOwnProperty mod
      msg = "Module #{mod} not loaded"
      @error msg
      return cb?(msg)

    @modules[mod].destruct?()
    delete require.cache[require.resolve(mod)]
    delete @modules[mod]

    @notify "Stopped module #{mod}"

    return cb?(null)

  connect: ->
    @notify "Connecting to server #{@config.address}."
    @client = new irc.Client @config.address, @config.nick, @config

    @client.addListener 'error', (msg) =>
      @error msg
      @emit.apply this, arguments

    @client.addListener 'registered', =>
      @notify "Connected to server #{@config.address}.\n\tChannels joined: #{@config.channels.join(', ')}"
      @emit.apply this, arguments

    @client.addListener 'message', (nick, channel, msg, res) =>
      @emit.apply this, arguments
      @matchRoute msg, res

    @channels = @client.chans

    return @client


  route: (path, middlewares..., fn) ->
    @routes[path] ?= []
    @routes[path].push
      fn: fn
      middlewares: middlewares

    @router.addRoute path, fn

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
    return @say res.channel, "You are already authed." if @authedClients.hasOwnProperty res.prefix

    user = res.user = _.findWhere(@config.users, {username: res.params.username, password: res.params.password})

    unless user?
      @error "User #{res.prefix} tried to authenticate with bad credentials"
      return @say res.channel, "Authentication failed. Bad credentials."

    @authedClients[res.prefix] = user

    next()

  requiresUser: (res, next) ->
    unless res.user?
      return @error "User #{res.prefix} tried to use '#{res.route}' route"
    next()

  basicRoutes: require './lib/basic-routes'

module.exports = Domo
