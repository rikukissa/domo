_       = require 'underscore'
fs      = require 'fs'
Sandbox = require 'sandbox'

pack = JSON.parse fs.readFileSync('./package.json')

class Commands
  constructor: (@connection) ->
    @cache = []
    @modules = []

    _.each @connection.globalConfig.modules, @loadModule

    @actions =
      'auth ': (nick, channel, msg, info) ->
        [username, password] = msg.split ' '

        unless @connection.auth username, password, info.prefix
          console.log "#{info.prefix} failed to authenticate with #{username}:#{password}"       
          return @connection.client.say nick, "Incorrect username or password" 
        return @connection.client.say nick, "You are now authed"

      'join ': (nick, channel, msg, info) ->
        return unless @connection.authenticate(info.prefix)

        for channel in msg.split ' '
          do (channel) =>
            if @connection.serverConfig.channels.indexOf(channel) == -1
              @connection.serverConfig.channels.push channel 

            @connection.client.join(channel, =>
              console.log "#{Date.now()}: Joined channel #{channel}"
            ) 

      'part ': (nick, channel, msg, info) ->
        return unless @connection.authenticate(info.prefix)

        for channel in msg.split ' '
          do (channel) =>
            if (index = @connection.serverConfig.channels.indexOf(channel)) > -1
              @connection.serverConfig.channels.splice index, 1

            @connection.client.part(channel, =>
              console.log "#{Date.now()}: Left channel #{channel}"
            ) 
      'save$': (nick, channel, msg, info) ->
        return unless @connection.authenticate(info.prefix)
        @connection.saveConfig()
      
      'load ': (nick, channel, msg, info) ->
        return unless @connection.authenticate(info.prefix)
        if @loadModule msg
          @connection.client.say channel, "Module #{msg} loaded :)"
        else
          @connection.client.say channel, "Couldn't load module #{msg}"

      'stop ': (nick, channel, msg, info) ->
        return unless @connection.authenticate(info.prefix)
        if @stopModule msg
          @connection.client.say channel, "Module #{msg} stopped"
        else
          @connection.client.say channel, "Couldn't find module #{msg}"

      # Globals
      'domo$': (nick, channel, msg, info) ->
        console.log (chan for chan in @connection.client.chans)
        @connection.client.say channel, """
          h :) v#{pack.version} 
          Current channels: #{(chan for chan of @connection.client.chans).join(', ')}

          I live here: https://github.com/rikukissa/node-ircbot
          """

  stopModule: (mod) =>
    try
      module = require(mod) 
    catch err
      console.log err
      return false
    if (index = @connection.globalConfig.modules.indexOf(mod)) > -1
      @connection.globalConfig.modules.splice index, 1    
    @modules.splice @modules.indexOf(module), 1
    true

  loadModule: (mod) =>
    try
      module = require(mod) 
    catch err
      console.log err
      return false

    if @connection.globalConfig.modules.indexOf(mod) == -1
      @connection.globalConfig.modules.push mod 

    console.log "#{Date.now()}: Loaded module #{mod}"
    
    if @modules.indexOf module
      @modules.push module 
      return true
    
    return false

  fetch: (nick, channel, msg, message) =>
    @cache.unshift arguments
    if @cache.length > (@connection.globalConfig.cacheLength || @connection.globalConfig.cacheLength)
      @cache.pop()

    for action, func of @actions 
      regex = new RegExp('^!' + action, 'i')
      continue unless regex.test msg
      arguments[2] = arguments[2].replace regex, ''
      return func.apply(this, arguments) 

    for module in @modules
      regex = new RegExp('^!' + module.match, 'i')
      continue unless regex.test msg
      arguments[2] = arguments[2].replace regex, ''
      module.onMessage.apply(this, arguments) if module.onMessage?

module.exports = Commands