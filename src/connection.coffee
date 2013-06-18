_        = require 'underscore'
irc      = require 'irc'
Commands = require('./commands')

class Connection
  constructor: (@globalConfig, @serverConfig) ->
    console.log 'Connecting to ' + @serverConfig.address
    
    [serverConfig, globalConfig] = [@serverConfig, @globalConfig]

    @client = new irc.Client serverConfig.address, serverConfig.nick || globalConfig.nick,
      channels: serverConfig.channels || globalConfig.channels
      userName: serverConfig.userName || globalConfig.userName
      realName: serverConfig.realName || globalConfig.realName
    
    @commands = new Commands @client 

    @client.addListener 'error', (message) ->
      console.log 'error: ', message
    
    @client.addListener 'registered', () =>
      console.log 'Connected to server ' + @serverConfig.address        

      @client.addListener 'message', @commands.fetch

    @loadModules()
  
  loadModules: ->
    @modules = _.map @globalConfig.modules, (mod) =>
      return require(__dirname + '/modules/' + mod)


module.exports = Connection