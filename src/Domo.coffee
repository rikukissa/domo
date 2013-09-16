EventEmitter = require('events').EventEmitter
Router = require 'routes'
irc = require 'irc'
_ = require 'underscore'

class Domo extends EventEmitter
  constructor: (@config) ->
    @router = new Router

  error: (msg) ->
    console.log 'Error:', msg if @config.debug?

  notify: (msg) ->
    console.log 'Notify:', msg

  say: (channel, msg) ->
    @client.say channel, msg

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
  route: (path, fn) ->
    @router.addRoute path, fn

  match: (path, data) ->
    return unless (result = @router.match path)?
    result.fn.call this, _.extend result, data



module.exports = Domo
