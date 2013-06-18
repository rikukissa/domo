module.exports =
  name: 'disconnect'
  command: 'disconnect'
  func: () ->
    @client.disconnect()
