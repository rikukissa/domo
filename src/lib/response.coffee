_ = require 'underscore'

class Response
  constructor: (@client, res) ->

    res.channel = res.args[0]
    res.message = res.args[1]
    res.username = res.user

    res.pm = res.channel is @client.client?.nick
    res.user = @client.authedClients[res.prefix]

    omittedFields = [
      'fn'
      'command'
      'commandType'
      'args'
    ]

    _.extend @, _.omit res, omittedFields

  send: (message) ->
    return @client.say @nick, message if @pm
    @client.say @channel, message

module.exports = Response
