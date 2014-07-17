colors = require 'colors'

module.exports =
  error: (error) ->
    console.log 'Error:'.red, error.message.red

  notify: (messages...) ->
    console.log 'Notify:'.green, messages.join('\n').green if @config.debug?

  warn: (messages...) ->
    console.log 'Warning:'.yellow, messages.join('\n').yellow

  say: (channel, msg) ->
    @client.say channel, msg
