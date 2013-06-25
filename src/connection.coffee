_        = require 'underscore'
fs       = require 'fs'
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
      console.log 'error: ', message if globalConfig.debug
    
    @client.addListener 'registered', () =>
      console.log 'Connected to server ' + @serverConfig.address        
      @client.addListener 'message', @commands.fetch

  authenticate: (prefix) =>
    return @authedUsers.indexOf(prefix) > -1
  
  auth: (username, password, address) ->
    @globalConfig.users = @globalConfig.users || []
    @serverConfig.users = @serverConfig.users || []

    availableUsers = @globalConfig.users.concat @serverConfig.users

    return false if @authedUsers.indexOf(address) > -1

    for user in availableUsers
      if user.username == username && user.password == password
        return @authedUsers.push address 

    return false
  
  saveConfig: ->
    fs.writeFile './config.json', JSON.stringify(@globalConfig, null, 2), (err) ->
      return console.log err if err?
  

module.exports = Connection