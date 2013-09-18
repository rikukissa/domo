fs = require 'fs'

pack = JSON.parse fs.readFileSync('./package.json')


class Controller
  register: (domo) ->
    domo.route '!domo', (res) ->
      domo.say res.channel, """
        h :) v#{pack.version}
        Current channels: #{(chan for chan of domo.channels).join(', ')}
        I live here: #{pack.repository.url}
        """
    domo.route '!auth :username :password', domo.authenticate, (res) ->

    domo.route '!join :channel', (res) ->
      domo.join res.params.channel

    domo.route '!join :channel :password', (res) ->
      domo.join res.params.channel + ' ' + res.params.password

    domo.route '!part :channel', (res) ->
      domo.part res.params.channel

    domo.route '!load :module', (res) ->
      domo.loadModule res.params.module, (err) ->
        domo.say res.channel, err if err?

    domo.route '!stop :module', (res) ->
      domo.stopModule res.params.module, (err) ->
        domo.say res.channel, err if err?


module.exports = Controller
