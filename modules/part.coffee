part =
  name: 'part'
  command: 'part'
  func: (ftmt, chan) ->
    if chan?
       @client.part chan
exports.part = part