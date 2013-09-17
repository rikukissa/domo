EventEmitter = require('events').EventEmitter
Router = require 'routes'
irc = require 'irc'
_ = require 'underscore'

class Domo extends EventEmitter
  constructor: (@config) ->
    @router = new Router
    @modules = {}

  error: (msg) ->
    console.log 'Error:', msg if @config.debug?

  notify: (msg) ->
    console.log 'Notify:', msg

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

  formatResult: (resObj) ->
    resObj.channel = resObj.args[0]
    resObj.message = resObj.args[1]
    resObj

  wrap: (fn, middlewares) -> () ->
    args = Array.prototype.slice.call(arguments, 0)
    _.reduceRight(middlewares, (memo, item) ->
      next = -> memo.apply this, args
      return -> item.apply this, _.flatten([args, next], true)
    , fn).apply this, arguments

  route: (path, middlewares..., fn) ->
    @router.addRoute path, () =>
      @wrap(fn, middlewares).apply this, arguments

  match: (path, data) ->
    return unless (result = @router.match path)?

    result.fn.call this, _.extend result, data

Domo::TestMiddle = (res, next) -> next()

Domo::RequiresUser = (next) ->
  return (res) =>
    return next() if res.user?
    @say res.channel, "User required for this action"

module.exports = Domo
