module.exports =
  name: 'h'
  command: '*'
  func: (from, to, message, text) ->
    if /^h$/.test(message)
      @client.say to, 'h'