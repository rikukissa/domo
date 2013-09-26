$       = require 'jquery'
Rainbow = require 'rainbow'

require 'rainbow-js'
require 'rainbow-generic'

io = require 'socket.io-client/dist/socket.io.js'

Rainbow.color()

socket = io.connect 'http://localhost:62899'
socket.on 'hello world', ->
  socket.emit 'post', 'moi!'

