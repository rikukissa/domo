
_   = require 'underscore'
fs  = require 'fs'
irc = require 'irc'

Connection = require './src/connection'

console.log 'IRCbot loaded'

config = JSON.parse fs.readFileSync('./config.json')

new Connection config, server for server in config.servers
