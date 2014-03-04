Q = require 'q'
_ = require 'underscore'
_.str = require 'underscore.string'
pkg = require './package'

module.exports =
  init: (domo) ->
    domo.route '!domo', (res) ->
      domo.say res.channel, """
        h :) v#{pkg.version}
        Current channels: #{(chan for chan of domo.channels).join(', ')}
        #{pkg.repository.url}
        """
    domo.route '!auth :username :password', domo.authenticate, (res) ->
      domo.say res.nick, "You are now authed. Hi #{_.str.capitalize(res.user.username)}!"

    domo.route '!join :channel', domo.requiresUser, (res) ->
      domo.join res.params.channel

    domo.route '!join :channel :password', domo.requiresUser, (res) ->
      domo.join res.params.channel + ' ' + res.params.password

    domo.route '!part :channel', domo.requiresUser, (res) ->
      domo.part res.params.channel

    domo.route '!load :module', domo.requiresUser, (res) ->
      domo.load res.params.module, (err) ->
        return domo.say res.channel, err if err?
        domo.say res.channel, "Module '#{res.params.module}' loaded!"

    domo.route '!stop :module', domo.requiresUser, (res) ->
      domo.stop res.params.module, (err) ->
        domo.say res.channel, err if err?
        domo.say res.channel, "Module '#{res.params.module}' stopped!"

    domo.route '!reload', domo.requiresUser, (res) ->
      _.flatten(_.map domo.modules, (module, moduleName) ->
        [
          Q.nfcall(domo.stop, moduleName),
          Q.nfcall(domo.load, moduleName)
        ]
      ).reduce(Q.when, Q())
        .then ->
          domo.say res.channel, "Reloaded modules #{_.keys(domo.modules).join(', ')}!"
        .catch (e) ->
          domo.error e.message
          domo.say res.channel, "Couldn't reload all modules"
