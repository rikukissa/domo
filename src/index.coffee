Q            = require 'q'
fs           = require 'fs'
irc          = require 'irc'
async        = require 'async'
colors       = require 'colors'
Router       = require 'routes'
EventEmitter = require('events').EventEmitter
_            = require 'underscore'
_.str        = require 'underscore.string'


pack = require '../package.json'

registerDefaultRoutes = (domo) ->
  domo.route '!domo', (res) ->
    domo.say res.channel, """
      h :) v#{pack.version}
      Current channels: #{(chan for chan of domo.channels).join(', ')}
      #{pack.repository.url}
      """
  domo.route '!auth :username :password', domo.authenticate, (res) ->
    domo.say res.nick, "You are now authed. Hi #{_.str.capitalize(res.user.username)}!"

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

  domo.route '!reload', domo.requiresUser, (res) ->
    _.flatten(_.map domo.modules, (module, moduleName) ->
      [
        Q.nfcall(domo.stop, moduleName),
        Q.nfcall(domo.load, moduleName)
      ]
    ).reduce(Q.when, Q())
      .then ->
        domo.say res.channel, "Reloaded modules #{_.keys(domo.modules).join(', ')}!"
      .catch (e) ->
        domo.error e.message
        domo.say res.channel, "Couldn't reload all modules"


  domo.route '!reload :module', domo.requiresUser, (res) ->
    [
      Q.nfcall(domo.stop, res.params.module),
      Q.nfcall(domo.load, res.params.module)
    ].reduce(Q.when, Q())
      .then ->
        domo.say res.channel, "Module '#{res.params.module}' reloaded!"
      .catch (e) ->
        domo.error e.message
        domo.say res.channel, "Couldn't reload module '#{res.params.module}'"


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
      @match msg, res

    @channels = @client.chans

    return @client


  route: (path, middlewares..., fn) ->
    @router.addRoute path, @wrap(fn, middlewares)

  match: (path, data) ->
    return unless (result = @router.match path)?
    result.fn.call this, _.extend result, data

  wrap: (fn, middlewares) -> () =>
    args = Array.prototype.slice.call(arguments, 0)
    _.reduceRight(@middlewares.concat(middlewares), (memo, item) =>
      next = => memo.apply this, args
      return -> item.apply this, _.flatten([args, next], true)
    , fn).apply this, arguments

  use: (mw) ->
    @middlewares.push mw

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
