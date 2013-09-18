fs  = require 'fs'
irc = require 'irc'
_   = require 'underscore'

Domo = require './src/domo'

Controller = require './src/controller'

config = JSON.parse fs.readFileSync('./config.json')

for server in config.servers
  domo = new Domo(_.extend(config.global, server))
  domo.notify 'Domo initializing'
  domo.connect()
  new Controller().register domo
