module.exports = (res, next) ->
  res.channel = res.args[0]
  res.message = res.args[1]
  res.username = res.user

  res.user = @authedClients[res.prefix]

  next()
