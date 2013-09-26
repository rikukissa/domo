Rainbow = require 'rainbow'
ko      = require 'knockout'

require 'rainbow-js'
require 'rainbow-generic'

Rainbow.color()

io = require 'socket.io-client/dist/socket.io.js'

socket = io.connect 'http://lakka.kapsi.fi:61973'

class ViewModel
  constructor: ->
    @messages = ko.observableArray()
    
    socket.on 'messages', (messages) =>
      @messages messages
      @scrollBottom()
    
    socket.on 'message', (message) =>
      @messages.push message
      @scrollBottom()
  
  scrollBottom: ->
    el = document.getElementById 'message-box'
    el.scrollTop = el.scrollHeight

  formatTime: (time) ->
    return new Date(time).toLocaleTimeString()

ko.applyBindings new ViewModel, document.getElementById 'message-box'