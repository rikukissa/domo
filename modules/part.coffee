module.exports =
  name: 'part'
  command: 'part'
  func: (ftmt, chan) ->
    if chan?
       @client.part chan
