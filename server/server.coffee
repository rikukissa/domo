nodeStatic = require('node-static')
staticFiles = new nodeStatic.Server './'

require('http').createServer (req, res) ->
  req.addListener 'end', ->
    staticFiles.serve req, res
  req.resume()
.listen 9001
