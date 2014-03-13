colors = require 'colors'

module.exports =
  error: (messages...) ->
    console.log 'Error:'.red, messages.join('\n').red

  notify: (messages...) ->
    console.log 'Notify:'.green, messages.join('\n').green if @config.debug?

  warn: (messages...) ->
    console.log 'Warning:'.yellow, messages.join('\n').yellow

  say: (channel, msg) ->
    @client.say channel, msg
