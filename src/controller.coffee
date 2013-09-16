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
    domo.route '!join :channel :password?', (res) ->
      res.params.channel += " #{res.params.password}" if res.params.password?
      domo.join res.params.channel

    domo.route '!part :channel', (res) ->
      domo.part res.params.channel

    domo.route '!load :module', (res) ->
      domo.loadModule res.params.module

    domo.route '!stop :module', (res) ->
      domo.stopModule res.params.module

module.exports = Controller
