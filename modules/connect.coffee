connect =
  name: 'connect'
  command: 'connect'
  func: (ftmt, server) ->
    if server?
      conn = new @connection(@app,
        address: server
        channels: []
      )
      @app.connections.push conn
exports.connect = connect