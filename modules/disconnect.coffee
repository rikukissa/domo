disconnect =
  name: 'disconnect'
  command: 'disconnect'
  func: () ->
    @client.disconnect()
exports.disconnect = disconnect