_      = require 'underscore'
assert = require 'assert'
Domo   = require '../'

createRes = (msg) ->
  args: ['#test', msg]
  user: 'Test'
  prefix: '!test@test.com'

describe 'Domo basic routes', ->
  it 'should print information about domo when !domo is called', (done) ->
    domo = new Domo()

    domo.use domo.basicRoutes()

    domo.say = (chan, msg) ->
      assert.ok msg.length > 0
      done()

    domo.matchRoutes '!domo', createRes()

  it 'should join a channel when !join is called', (done) ->
    domo = new Domo()
    domo.use domo.basicRoutes()

    res = createRes()
    domo.authedClients[res.prefix] = true

    domo.join = (chan) ->
      assert.equal chan, '#foo'
      done()
      catch: ->

    domo.matchRoutes '!join #foo', res

  it 'should not join a channel when user is not auther', (done) ->
    domo = new Domo()
    domo.use domo.basicRoutes()

    res = createRes()

    domo.join = (chan) ->
      throw new Error 'should not join a channel when user is not auther'

    domo.matchRoutes '!join #foo', res
    done()

  it 'should part a channel when !part is called', (done) ->
    domo = new Domo()
    domo.use domo.basicRoutes()

    res = createRes()
    domo.authedClients[res.prefix] = true

    domo.part = (chan) ->
      assert.equal chan, '#foo'
      done()
      catch: ->

    domo.matchRoutes '!part #foo', res

  it 'should not part a channel when user is not auther', (done) ->
    domo = new Domo()
    domo.use domo.basicRoutes()

    res = createRes()

    domo.part = (chan) ->
      throw new Error 'should not part a channel when user is not auther'

    domo.matchRoutes '!part #foo', res
    done()
