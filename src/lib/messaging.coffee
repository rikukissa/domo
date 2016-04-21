colors = require 'colors'

module.exports = (outputFn) ->
  error: (error) ->
    outputFn 'Error:'.red, error.message.red

  notify: (messages...) ->
    outputFn 'Notify:'.green, messages.join('\n').green if @config.debug?

  warn: (messages...) ->
    outputFn 'Warning:'.yellow, messages.join('\n').yellow

  say: (channel, msg) ->
    @client.say channel, msg
