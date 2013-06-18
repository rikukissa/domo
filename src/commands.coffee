class Commands
  constructor: ->
    @actions =
      join: -> console.log 'join!'
      part: -> 


  add: (key, func) -> @actions[key] = func

  fetch: (nick, channel, msg, message) =>
    return func.apply(this, arguments) for action, func of @actions when new RegExp('^!' + action).test msg

module.exports = Commands