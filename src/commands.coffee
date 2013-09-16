_       = require 'underscore'
fs      = require 'fs'
Sandbox = require 'sandbox'

pack = JSON.parse fs.readFileSync('./package.json')

class Commands
  constructor: (@connection) ->
    @cache = []
    @modules = {}

    _.each @connection.globalConfig.modules, (module) => do (module) =>
        @loadModule module, (err) ->
          console.log err if err?

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

      'nick ': (nick, channel, msg, info) ->
        return unless @connection.authenticate(info.prefix)
        @setNick msg, (err, newNick) =>
          @connection.client.say channel, "Couldn't change my nickname to #{msg}!" if err?

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
        @loadModule msg, (err) =>
          console.log err
          return @connection.client.say channel, err if err?
          @connection.client.say channel, "Module #{msg} loaded :)"

      'stop ': (nick, channel, msg, info) ->
        return unless @connection.authenticate(info.prefix)
        @stopModule msg, (err) =>
          return @connection.client.say channel, err if err?
          @connection.client.say channel, "Module #{msg} detached"

      # Globals
      'domo$': (nick, channel, msg, info) ->
        console.log (chan for chan in @connection.client.chans)
        @connection.client.say channel, """
          h :) v#{pack.version}
          Current channels: #{(chan for chan of @connection.client.chans).join(', ')}

          I live here: #{pack.repository.url}
          """

  setNick: (nick, callback) ->
    return callback 'Nickname is already set' if @connection.client.nick is nick

    success = (oldNick, newNick, channels)=>
      @connection.client.removeListener 'error', error
      @connection.client.nick = newNick
      callback?(null, newNick)

    error = (err) =>
      @connection.client.removeListener 'nick', success
      callback?(err)

    @connection.client.once 'nick', success
    @connection.client.once 'error', error
    @connection.client.send 'NICK', nick

  stopModule: (mod, cb) =>
    return cb?("Module #{mod} not loaded") unless @modules.hasOwnProperty mod

    if (index = @connection.globalConfig.modules.indexOf(mod)) > -1
      @connection.globalConfig.modules.splice index, 1

    delete require.cache[require.resolve(mod)]
    delete @modules[mod]

    console.log "#{Date.now()}: Stopped module #{mod}"
    return cb?(null)

  loadModule: (mod, cb) =>
    try
      module = require(mod)
    catch err
      return cb?("Module #{mod} not found")

    # Add module to config
    if @connection.globalConfig.modules.indexOf(mod) is -1
      @connection.globalConfig.modules.push mod

    console.log "#{Date.now()}: Loaded module #{mod}"

    return cb?("Module #{mod} already loaded") if @modules.hasOwnProperty mod

    @modules[mod] = module
    module.init?(@connection)
    cb(null)

  fetch: (nick, channel, msg, message) =>
    @cache.unshift arguments
    if @cache.length > (@connection.globalConfig.cacheLength || @connection.globalConfig.cacheLength)
      @cache.pop()

    for action, func of @actions
      regex = new RegExp('^!' + action, 'i')
      continue unless regex.test msg
      arguments[2] = arguments[2].replace regex, ''
      return func.apply(this, arguments)

    for name, module of @modules
      continue unless module.match? or not module.onMessage?
      regex = new RegExp('^' + module.match, 'i')
      continue unless regex.test msg
      arguments[2] = arguments[2].replace regex, ''
      module.onMessage.apply(this, arguments) if module.onMessage?

module.exports = Commands
