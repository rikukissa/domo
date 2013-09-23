_      = require 'underscore'
assert = require 'assert'

Domo   = require '../index'

createRes = (msg) ->
  args: ['#test', msg]
  user: 'Test'
  prefix: '!test@test.com'


describe 'Middleware wrapper', ->

  it 'should pass the right arguments all the way to the final function', (done) ->
    domo = new Domo()

    mw1 = (res, next) ->
      assert.equal res.message, 'works'
      next()

    mw2 = (res, next) ->
      assert.equal res.message, 'works'
      next()

    fn = (res) ->
      assert.equal res.message, 'works'
      done()

    domo.wrap(fn, [mw1, mw2]) createRes 'works'

  it 'should pass object through middlewares', (done) ->
    domo = new Domo()

    obj =
      foo: 'bar'
      lol: 'cat'

    mw1 = (res, next) ->
      assert.equal res.message, obj
      next()

    mw2 = (res, next) ->
      assert.equal res.message, obj
      next()

    fn = (res) ->
      assert.equal res.message, obj
      done()

    domo.wrap(fn, [mw1, mw2]) createRes obj


  it 'should pass changed res object through middlewares', (done) ->
    domo = new Domo()

    mw1 = (res, next) ->
      next()

    mw2 = (res, next) ->
      res.foo = 'hello'
      next()

    fn = (res) ->
      assert.equal res.foo, 'hello'
      done()

    domo.wrap(fn, [mw1, mw2]) createRes 'hello world'

  it 'should remain the context', (done) ->
    domo = new Domo()

    mw1 = (res, next) -> next()
    mw2 = (res, next) -> next()

    fn = (res) ->
      assert.equal this, domo
      done()

    domo.wrap(fn, [mw1, mw2]) createRes 'hello world'
