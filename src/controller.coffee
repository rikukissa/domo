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

module.exports = Controller
