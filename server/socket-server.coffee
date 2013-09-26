Domo = require 'domo-kun'

io   = require("socket.io").listen 61973

domo = new Domo
  nick: 'Domo'
  userName: 'Domo'
  address: 'irc.freenode.net'
  channels: ['#domo-kun']
  debug: true

domo.connect()

messageCache = []

io.sockets.on 'connection', (socket) ->
  socket.emit 'messages', messageCache

domo.route '*', (res) ->
  return unless res.channel is '#domo-kun'

  message =
    channel: res.channel
    message: res.message
    timestamp: Date.now()  

  io.sockets.emit 'message', message

  if messageCache.length >= 100
    messageCache.shift()

  messageCache.push message