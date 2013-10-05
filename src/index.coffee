fs           = require 'fs'
irc          = require 'irc'
colors       = require 'colors'
Router       = require 'routes'
EventEmitter = require('events').EventEmitter
_            = require 'underscore'
_.str        = require 'underscore.string'

pack = JSON.parse fs.readFileSync "#{__dirname}/package.json"

registerDefaultRoutes = (domo) ->
  domo.route '!domo', (res) ->
    domo.say res.channel, """
      h :) v#{pack.version}
      Current channels: #{(chan for chan of domo.channels).join(', ')}
      #{pack.repository.url}
      """
  domo.route '!auth :username :password', domo.authenticate, (res) ->
    domo.say res.channel, "You are now authed. Hi #{_.str.capitalize(res.user.username)}!"

  domo.route '!join :channel', domo.requiresUser, (res) ->
    domo.join res.params.channel

  domo.route '!join :channel :password', domo.requiresUser, (res) ->
    domo.join res.params.channel + ' ' + res.params.password

  domo.route '!part :channel', domo.requiresUser, (res) ->
    domo.part res.params.channel

  domo.route '!load :module', domo.requiresUser, (res) ->
    domo.load res.params.module, (err) ->
      return domo.say res.channel, err if err?
      domo.say res.channel, "Module '#{res.params.module}' loaded!"

  domo.route '!stop :module', domo.requiresUser, (res) ->
    domo.stop res.params.module, (err) ->
      domo.say res.channel, err if err?
      domo.say res.channel, "Module '#{res.params.module}' stopped!"


class Domo extends EventEmitter
  constructor: (@config) ->
    @router = new Router
    @modules = {}
    @authedClients = []
    @middlewares = []
    @config = @config || {}
    @use @constructRes

    registerDefaultRoutes @

    @load module for module in @config.modules if @config.modules?

  log: -> console.log arguments
  info: -> console.info 'Info:'.green, (msg.green for msg in arguments)...
  warn: -> console.warn 'Warn:'.yellow, (msg.yellow for msg in arguments)...
  error: -> console.error 'Error:'.red, (msg.red for msg in arguments)... if @config.debug

  say: -> @irc.say arguments

  join: (channel, cb) ->
    @irc.join channel, =>
      cb.apply @, arguments if cb?

  part: (channel, cb) ->
    @irc.part channel, =>
      cb.apply @, arguments if cb?

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

    cb?(null)

  stop: (mod, cb) =>
    unless @modules.hasOwnProperty mod
      msg = "Module #{mod} not loaded"
      @error msg
      return cb?(msg)

    @modules[mod].destruct?()
    delete require.cache[require.resolve(mod)]
    delete @modules[mod]

    @info "Stopped module #{mod}"

    return cb?(null)

  connect: ->
    @info "Connecting to server #{@config.address}."

    @irc = new irc.Client @config.address, @config.nick, @config

    @channels = @irc.chans

    @on 'error', @error

    @on 'registered', =>
      @info "Connected to server #{@config.address}.\n\tChannels joined: #{@config.channels.join(', ')}"

    @on 'message', (nick, channel, msg, res) =>
      @match msg, res

    return @irc


  route: (path, middlewares..., fn) ->
    @router.addRoute path, @wrap(fn, middlewares)

  on: (event, middlewares..., fn) ->
    @irc.addListener event, @wrap(fn, middlewares, false)
    super

  match: (path, data) ->
    return unless (result = @router.match path)?
    result.fn.call @, _.extend result, data

  wrap: (fn, middlewares, useRegisted = true) -> () =>
    args = Array.prototype.slice.call(arguments, 0)

    combinedMiddlewares =
      if useRegisted
        @middlewares.concat(middlewares)
      else
        middlewares

    _.reduceRight(combinedMiddlewares, (memo, item) =>
      next = => memo.apply @, args
      return -> item.apply @, _.flatten([args, next], true)
    , fn).apply @, arguments

  use: -> @middlewares.push arguments

  constructRes: (res, next) ->
    res.channel = res.args[0]
    res.message = res.args[1]
    res.username = res.user

    res.user = unless @authedClients.hasOwnProperty(res.prefix)
      null
    else
      @authedClients[res.prefix]

    next()

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

module.exports = Domo
