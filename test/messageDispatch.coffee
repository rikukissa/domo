_      = require 'underscore'
assert = require 'assert'

Domo   = require '../'

createRes = (msg) ->
  args: ['#test', msg]
  user: 'Test'
  prefix: '!test@test.com'

noopMw = (res, next) -> next()

describe 'Message dispatcher', ->

  it 'should route messages to right route handler', (done) ->
    domo = new Domo()

    domo.route 'foo bars', (res) ->
      throw new Error 'Router matched invalid route'

    domo.route 'foo ba', (res) ->
      throw new Error 'Router matched invalid route'

    domo.route 'foo bar', (res) -> done()

    domo.matchRoutes 'foo bar', createRes 'hello'

  it 'should redirect messages through middlewares', (done) ->
    domo = new Domo()

    testMiddleware = (res, next) ->
      done()
      next()

    domo.route 'hello world', testMiddleware, ->
    domo.matchRoutes 'hello world', createRes 'hello'

  it 'should parse given params', (done) ->
    domo = new Domo()

    domo.route 'hello :what', (res) ->
      assert.equal res.params.what, 'world'
      done()

    domo.matchRoutes 'hello world', createRes 'hello world'

  it 'it should allow registering multiple routes with the same path', (done) ->
    domo = new Domo()
    ready = false

    domo.route 'hello :what', (res) ->
      return done() if ready
      ready = true

    domo.route 'hello :what', (res) ->
      return done() if ready
      ready = true

    domo.matchRoutes 'hello world', createRes 'hello world'


  it 'it should call routes in their registration order', (done) ->
    domo = new Domo()
    ready = false

    domo.route 'hello :what', (res) ->
      ready = true

    domo.route 'hello :what', (res) ->
      done() if ready

    domo.matchRoutes 'hello world', createRes 'hello world'

  it 'it should allow destroying routes', (done) ->
    domo = new Domo()

    fail = ->
      throw new Error 'Route wasnt destroyed properly'

    success = (res) ->
      done()


    domo.route 'hello :what', fail
    domo.route 'hello :what', success

    domo.destroyRoute 'hello :what', fail

    domo.matchRoutes 'hello world', createRes 'hello world'

  it 'it should handle params correctly', (done) ->
    domo = new Domo()

    domo.route 'hello :what', (res) ->
      assert.equal res.params.what, 'world'
      done()

    domo.matchRoutes 'hello world', createRes()

  it 'it should handle multiple params correctly', (done) ->
    domo = new Domo()

    domo.route 'hello :a :b :c', (res) ->
      assert.equal res.params.a, 'foo'
      assert.equal res.params.b, 'bar'
      assert.equal res.params.c, 'baz'
      done()

    domo.matchRoutes 'hello foo bar baz', createRes()

  it 'it should handle matching with non-uri charachers', (done) ->
    domo = new Domo()

    domo.route 'hello *', (res) ->
      assert.equal res.splats[0], '%'
      done()

    domo.matchRoutes 'hello %', createRes()
