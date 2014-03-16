Q = require 'q'
_ = require 'underscore'
_.str = require 'underscore.string'
pkg = require './package'

module.exports = ->
  init: ->
    @route '!domo', (res) ->
      @say res.channel, """
        h :) v#{pkg.version}
        Current channels: #{(chan for chan of @channels).join(', ')}
        #{pkg.repository.url}
        """
    @route '!auth :username :password', @authenticate, (res) ->
      @say res.nick, "You are now authed. Hi #{_.str.capitalize(res.user.username)}!"

    @route '!join :channel', @requiresUser, (res) ->
      @join res.params.channel

    @route '!join :channel :password', @requiresUser, (res) ->
      @join res.params.channel + ' ' + res.params.password

    @route '!part :channel', @requiresUser, (res) ->
      @part res.params.channel

    @route '!load :module', @requiresUser, (res) ->
      @load res.params.module, (err) ->
        return @say res.channel, err if err?
        @say res.channel, "Module '#{res.params.module}' loaded!"

    @route '!stop :module', @requiresUser, (res) ->
      @stop res.params.module, (err) ->
        return @say res.channel, err if err?
        @say res.channel, "Module '#{res.params.module}' stopped!"

    @route '!reload', @requiresUser, (res) ->
      _.flatten(_.map @modules, (module, moduleName) =>
        [
          Q.nfcall(@stop, moduleName),
          Q.nfcall(@load, moduleName)
        ]
      ).reduce(Q.when, Q())

        .then =>
          @say res.channel, "Reloaded modules #{_.keys(@modules).join(', ')}!"

        .catch (e) =>
          @error e.message
          @say res.channel, "Couldn't reload all modules"
