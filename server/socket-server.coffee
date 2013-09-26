Domo = require 'domo-kun'

io   = require("socket.io").listen 61973

domo = new Domo
  nick: 'Domo'
  userName: 'Domo'
  address: 'irc.freenode.net'
  channels: ['#domo-kun']
  debug: true

domo.connect()

domo.route '*', (res) ->
  io.sockets.emit 'message', res.message

io.sockets.on "connection", (socket) ->
  socket.on 'message', (data) ->
    for channel in domo.config.channels
      domo.say channel, data

