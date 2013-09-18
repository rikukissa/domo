fs    = require 'fs'
_     = require 'underscore'
_.str = require 'underscore.string'

pack = JSON.parse fs.readFileSync('./package.json')

requiresUser = (res, next) ->
  unless res.user?
    @say res.channel, "This route is for users only"
    return @error "User #{res.prefix} tried to use '#{res.route}' route"
  next()

class Controller
  register: (domo) ->
    domo.route '!domo', (res) ->
      domo.say res.channel, """
        h :) v#{pack.version}
        Current channels: #{(chan for chan of domo.channels).join(', ')}
        I live here: #{pack.repository.url}
        """
    domo.route '!auth :username :password', domo.authenticate, (res) ->
      domo.say res.channel, "You are now authed. Hi #{_.str.capitalize(res.user.username)}!"

    domo.route '!join :channel', requiresUser, (res) ->
      domo.join res.params.channel

    domo.route '!join :channel :password', requiresUser, (res) ->
      domo.join res.params.channel + ' ' + res.params.password

    domo.route '!part :channel', requiresUser, (res) ->
      domo.part res.params.channel

    domo.route '!load :module', requiresUser, (res) ->
      domo.loadModule res.params.module, (err) ->
        return domo.say res.channel, err if err?
        domo.say res.channel, "Module '#{res.params.module}' loaded!"

    domo.route '!stop :module', requiresUser, (res) ->
      domo.stopModule res.params.module, (err) ->
        domo.say res.channel, err if err?
        domo.say res.channel, "Module '#{res.params.module}' stopped!"


module.exports = Controller
