removeModule =
  name: 'Module remover'
  command: 'removeModule'
  func: (ftml, name) ->
    # Check that the module is not already loaded
    modCache = []
    for mod in @modules
      if mod.name != name
        modCache.push mod

    @modules = modCache
    @client.say ftml[0], 'Module "' + name + '" removed.'
exports.removeModule = removeModule