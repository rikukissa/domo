urltitle =
  name: 'urltitle'
  command: '*'
  func: (from, to, message, text) ->
    urlRegex = /(https?|ftp):\/\/(([\w\-]+\.)+[a-zA-Z]{2,6}|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})(:\d+)?(\/([\w\-~.#\/?=&;:+%!*\[\]@$\'()+,|\^]+)?)?/
    titleRegex = /<title>(.*)<\/title>/      
    if urlRegex.test(message)
      matches = message.match urlRegex
      request matches[0], (error, response, body) =>
        if !error && response.statusCode == 200
          if titleRegex.test(body)
            matches = body.match titleRegex
            if matches[1]?
              @client.say to, matches[1]
exports.urltitle = urltitle