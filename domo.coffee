fs  = require 'fs'
irc = require 'irc'
_   = require 'underscore'

console.log 'Domo initializing'

Domo = require './src/Domo'

Controller = require './src/controller'

config = JSON.parse fs.readFileSync('./config.json')

for server in config.servers
  domo = new Domo(_.extend(config.global, server))

  domo.connect()

  new Controller().register domo
