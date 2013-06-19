_        = require 'underscore'
irc      = require 'irc'
Commands = require('./commands')

class Connection
  constructor: (@globalConfig, @serverConfig) ->
    console.log 'Connecting to ' + @serverConfig.address
    
    [serverConfig, globalConfig] = [@serverConfig, @globalConfig]
    
    @authedUsers = []

    @client = new irc.Client serverConfig.address, serverConfig.nick || globalConfig.nick,
      channels: serverConfig.channels || globalConfig.channels
      userName: serverConfig.userName || globalConfig.userName
      realName: serverConfig.realName || globalConfig.realName
    
    @commands = new Commands @

    @client.addListener 'error', (message) ->
      console.log 'error: ', message
    
    @client.addListener 'registered', () =>
      console.log 'Connected to server ' + @serverConfig.address        
      @client.addListener 'message', @commands.fetch

    @loadModules()

  authenticate: (username, password, address) ->
    @globalConfig.users = @globalConfig.users || []
    @serverConfig.users = @serverConfig.users || []

    availableUsers = @globalConfig.users.concat @serverConfig.users

    for user in availableUsers
      if user.username == username && user.password == password
        return @authedUsers.push address 

    return false

  loadModules: ->
    @modules = _.map @globalConfig.modules, (mod) =>
      return require(__dirname + '/modules/' + mod)


module.exports = Connection