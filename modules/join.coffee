join =
  name: 'join'
  command: 'join'
  func: (ftmt, chan, pass) ->
    if chan?
      if pass?
        chan += ' ' + pass
      @client.join chan, () =>
        @client.say chan, 'h'
exports.join = join