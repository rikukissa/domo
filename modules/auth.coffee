module.exports =
  name: 'Auth module'
  command: '*'
  func: (from, to, message, text) ->
    conf = @app.config
    if to == conf.nick
      parsed = message.split ' '
      if parsed[0]? && parsed[0] == 'auth' && parsed[1]
        if parsed[1] == conf.password
          @client.whois from, (data) ->
            user = data.user + '@' + data.host
            if @app.users.indexOf(user) > -1
              @client.say from 'You\'re already authed ^^'
              return
            @app.users.push user
        else
          @client.say from 'Wrong password!'
