module.exports =
  name: 'Module loader'
  command: 'loadModule'
  func: (ftml, name) ->
    # Check that the module is not already loaded
    for mod in @modules
      if mod.name == name
        @client.say ftml[0], 'This module is already loaded.'
        return
    try
      module = require(__dirname + '/' + name)
      @client.say ftml[0], 'Module "' + name + '" loaded.'
      @modules.push module[name]
    catch e
      @client.say ftml[0], 'Couln\'t load the module "' + name + '"'