module.exports = (res, next) ->
  res.channel = res.args[0]
  res.message = res.args[1]
  res.username = res.user

  res.user = unless @authedClients.hasOwnProperty(res.prefix)
    null
  else
    @authedClients[res.prefix]

  next()
