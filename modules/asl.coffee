asl =
  name: 'asl'
  command: 'asl'
  func: (ftml) ->
    sexes = ['m', 'f', 'animu', 'bot']
    locs = ['internet', 'finland', 'sweden', 'japan']
    str = Math.round(Math.random() * 100)
    str += '/' + sexes[Math.floor(Math.random() * sexes.length)];
    str += '/' + locs[Math.floor(Math.random() * locs.length)];
    @client.say ftml[1], str  
exports.asl = asl