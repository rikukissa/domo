Q = require 'q'
_ = require 'underscore'
_.str = require 'underscore.string'
pkg = require './package'

module.exports = ->
  init: ->
    @route '!domo', (res) ->
      res.send """
        h :) v#{pkg.version}
        Current channels: #{(chan for chan of @channels).join(', ')}
        #{pkg.repository.url}
        """
    @route '!auth :username :password', @authenticate, (res) ->
      res.send "You are now authed. Hi #{_.str.capitalize(res.user.username)}!"

    @route '!join *', @requiresUser, (res) ->
      channels = res.splats[0].split(' ').map (channel) ->
        channel = "##{channel}" unless channel[0] is '#'
        channel.replace ':', ' '

      @join channels
      .catch @error

    @route '!part *', @requiresUser, (res) ->
      channels = res.splats[0].split(' ').map (channel) ->
        channel = "##{channel}" unless channel[0] is '#'
        channel

      @part channels
      .catch @error

    @route '!load *', @requiresUser, (res) ->
      modules = res.splats[0].split(' ')
      for module in modules
        do (module) ->

          @load module, (err) ->
            if err?
              errorMsg = if err.code is 'MODULE_NOT_FOUND'
                "Module #{moduleName} not found"
              else
                "Module #{moduleName} cannot be loaded"
              return res.send errorMsg

            res.send "Module '#{module}' loaded!"

    @route '!stop :module', @requiresUser, (res) ->
      modules = res.splats[0].split(' ')
      for module in modules
        do (module) ->
          @stop module, (err) ->
            return res.send err.message if err?
            res.send "Module '#{module}' stopped!"

    @route '!reload', @requiresUser, (res) ->
      _.flatten(_.map @modules, (module, moduleName) =>
        [
          Q.nfcall(@stop, moduleName),
          Q.nfcall(@load, moduleName)
        ]
      ).reduce(Q.when, Q())

        .then =>
          res.send "Reloaded modules #{_.keys(@modules).join(', ')}!"

        .catch (e) =>
          @error e.message
          res.send "Couldn't reload all modules"
