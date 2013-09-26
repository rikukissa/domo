server = (opts) ->

  fs        = require 'fs'
  http      = require 'http'

  WebSocketServer = require('websocket').server
  client = fs.readFileSync __dirname + '/client.js'

  appendScript = (content) ->
    content.replace '</body>', "<script>#{client.toString()}</script></body>"

  server = http.createServer (request, response) ->
    proxyReq = http.request
      hostname: "localhost"
      port: opts.proxy
      method: request.method
      path: request.url
      headers: request.headers
    , (proxyRes) ->

      headers = proxyRes.headers['content-type']
      html = headers? and headers.indexOf("text/html") > -1
      content = ""

      proxyRes.on 'data', (chunk) -> #content += chunk
        return response.write chunk, 'binary' unless html
        content += chunk

      proxyRes.on 'end', ->
        return response.end appendScript(content), 'utf-8' if html
        response.end()

      response.writeHead proxyRes.statusCode, proxyRes.headers unless html

    request.on 'data', (data) ->
      proxyReq.write(data)

    request.on 'end', ->
     proxyReq.end()

  server.listen opts.reload

  wsServer = new WebSocketServer
    httpServer: server
    autoAcceptConnections: false

  connections = []

  wsServer.on "request", (request) ->
    connection = request.accept(null, request.origin)
    connections.push connection
    connection.on "close", () ->
      connections.splice connections.indexOf(connection), 1

  reload = (refreshOnly = false) ->
    for connection in connections
      connection.sendUTF (if refreshOnly then 'refresh' else 'reload')

  return reload

module.exports = server

