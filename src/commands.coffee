_       = require 'underscore'
Sandbox = require 'sandbox'

class Commands
  constructor: (@connection) ->
    @cache = []
    @actions =
      authenticate: (nick, channel, msg, info) ->
        [username, password] = msg.split ' '

        unless @connection.authenticate username, password, info.prefix
          return @connection.client.say nick, "Incorrect username or password"        
        return @connection.client.say nick, "You are now authed"

      join: (nick, channel, msg) ->
        console.log arguments
        @connection.client.join(channel,=>
          console.log "#{Date.now()}: Joined channel #{channel}"
        ) for channel in msg.split ' '

      part: (nick, channel, msg) ->
        @connection.client.part(channel, =>
          console.log "#{Date.now()}: Left channel #{channel}"
        ) for channel in msg.split ' '

      eval: (nick, channel, msg) ->
        new Sandbox().run msg, (output) => 
          @connection.client.say channel, output.result

  fetch: (nick, channel, msg, message) =>
    @cache.unshift arguments
    if @cache.length > (@connection.globalConfig.cacheLength || @connection.globalConfig.cacheLength)
      @cache.pop()

    for action, func of @actions 
      regex = new RegExp('^!' + action + ' ')
      continue unless regex.test msg
      arguments[2] = arguments[2].replace regex, ''
      return func.apply(this, arguments) 

module.exports = Commands