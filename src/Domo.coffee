EventEmitter = require('events').EventEmitter
Router = require 'routes'
irc   = require 'irc'
_     = require 'underscore'
_.str = require 'underscore.string'
colors = require 'colors'

class Domo extends EventEmitter
  constructor: (@config) ->
    @router = new Router
    @modules = {}
    @authedClients = []

  error: (msg) ->
    console.log 'Error:'.red, msg.red if @config.debug?

  notify: (msg) ->
    console.log 'Notify:'.green, msg.green

  say: (channel, msg) ->
    @client.say channel, msg

  join: (channel, cb) ->
    @client.join channel, cb

  part: (channel, cb) ->
    @client.part channel, cb

  loadModule: (mod, cb) =>
    try
      module = require(mod)
    catch err
      msg = "Module #{mod} not found"
      @error msg
      return cb?(msg)

    @notify "Loaded module #{mod}"

    if @modules.hasOwnProperty mod
      msg = "Module #{mod} already loaded"
      @error msg
      return cb?(msg)

    @modules[mod] = module
    module.init?(@)
    cb(null)

  stopModule: (mod, cb) =>
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

    @client.addListener 'message', (nick, channel, msg, data) =>
      @emit.apply this, arguments
      @match msg, @formatResult data

    @channels = @client.chans

    return @client

  formatResult: (res) ->
    res.channel = res.args[0]
    res.message = res.args[1]
    res.username = res.user

    res.user = unless @authedClients.hasOwnProperty(res.prefix)
      null
    else
      @authedClients[res.prefix]

    return res

  route: (path, middlewares..., fn) ->
    @router.addRoute path, @wrap(fn, middlewares)

  match: (path, data) ->
    return unless (result = @router.match path)?
    result.fn.call this, _.extend result, data

  wrap: (fn, middlewares) -> () =>
    args = Array.prototype.slice.call(arguments, 0)
    _.reduceRight(middlewares, (memo, item) =>
      next = => memo.apply this, args
      return -> item.apply this, _.flatten([args, next], true)
    , fn).apply this, arguments

  authenticate: (res, next) ->
    return @error "Tried to authenticate. No users configured" unless @config.users?

    user = _.findWhere(@config.users, {username: res.params.username, password: res.params.password})

    unless user?
      @error "User #{res.prefix} tried to authenticate with bad credentials"
      return @say res.channel, "Authentication failed. Bad credentials."

    @say res.channel, "You are already authed." if @authedClients.hasOwnProperty res.prefix

    @authedClients[res.prefix] = user
    @say res.channel, "You are now authed. Hi #{_.str.capitalize(user.username)}"
    next()

module.exports = Domo
