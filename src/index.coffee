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
      I live here: #{pack.repository.url}
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

    @use @constructRes

    registerDefaultRoutes @

    @load module for module in @config.modules if @config.modules?

  error: (msg) ->
    console.log 'Error:'.red, msg.red if @config.debug?

  notify: (msg) ->
    console.log 'Notify:'.green, msg.green

  say: (channel, msg) =>
    @client.say channel, msg

  join: (channel, cb) ->
    @client.join channel, cb

  part: (channel, cb) ->
    @client.part channel, cb

  load: (mod, cb) =>
    try
      module = require(mod)
    catch err
      msg = "Module #{mod} not found"
      @error msg
      return cb?(msg)

    if @modules.hasOwnProperty mod
      msg = "Module #{mod} already loaded"
      @error msg
      return cb?(msg)

    @notify "Loaded module #{mod}"

    @modules[mod] = module
    module.init?(@)
    cb?(null)

  stop: (mod, cb) =>
    unless @modules.hasOwnProperty mod
      msg = "Module #{mod} not loaded"
      @error msg
      return cb?(msg)

    delete require.cache[require.resolve(mod)]
    delete @modules[mod]

    @notify "Stopped module #{mod}"

    return cb?(null)

  connect: ->
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
