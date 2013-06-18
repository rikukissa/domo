
_   = require 'underscore'
fs  = require 'fs'
irc = require 'irc'

class Application
  constructor: () ->
    console.log 'IRCbot loaded'
    @config = JSON.parse fs.readFileSync('./config.json')
    
    @users = []
    @connections = []

  connect: () ->
    console.log 'Now connecting to servers..'
    for server in @config.servers
      conn = new Connection @, server
      @connections.push conn

class Connection
  constructor: (@app, @config) ->
    console.log 'Connecting to ' + @config.address
        
    @client = new irc.Client @config.address, @app.config.nick,
      channels: @config.channels
      userName: @app.config.userName
      realName: @app.config.realName
    
    @loadModules()

    @client.addListener 'error', (message) ->
      console.log 'error: ', message
    
    @client.addListener 'registered', () =>
      console.log 'Connected to server ' + @config.address        
      @client.addListener 'message', (from, to, message, text) =>
        
        # Loop through modules
        for mod in @modules
          if mod.command == '*'
            mod.func.apply(this, arguments)
            continue

          # Check if it's a command
          if /^!/.test message
            arg = message.split ' '
            command = arg[0].replace '!', ''
            arg.splice 0, 1
            if mod.command == command
              args = [arguments]
              args = args.concat arg
              mod.func.apply(this, args)
  
  loadModules: ->
    @modules = _.map @app.config.modules, (mod) =>
      m = require(__dirname + '/modules/' + mod)
      console.log m
      return m[mod] 

  checkAuth: (nick, callback) ->
    @client.whois nick, (data) =>
      user = data.user + '@' + data.host
      if @app.users.indexOf(user) > -1
        if callback?
          callback true
      else
        if callback?
          callback false

App = new Application()
App.connect()