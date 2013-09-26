Domo = require 'domo-kun'
io   = require("socket.io").listen(62899)

domo = new Domo
  nick: 'Domo'
  userName: 'Domo'
  address: 'irc.datnode.net'
  channels: ['#domo']
  debug: true

domo.connect()

io.sockets.on "connection", (socket) ->

  socket.emit 'hello world', 666

  socket.on 'post', (data) ->
    for channel in domo.config.channels
      domo.say channel, data

