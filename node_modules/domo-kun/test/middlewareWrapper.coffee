assert = require 'assert'
Domo = require '../src/domo'

describe 'Middleware wrapper', ->

  it 'should pass the right arguments all the way to the final function', (done) ->
    domo = new Domo()

    mw1 = (res, next) ->
      assert.equal res, 'works'
      next()

    mw2 = (res, next) ->
      assert.equal res, 'works'
      next()

    fn = (res) ->
      assert.equal res, 'works'
      done()

    domo.wrap(fn, [mw1, mw2])('works')

  it 'should pass object through middlewares', (done) ->
    domo = new Domo()

    obj =
      foo: 'bar'
      lol: 'cat'

    mw1 = (res, next) ->
      assert.equal res, obj
      next()

    mw2 = (res, next) ->
      assert.equal res, obj
      next()

    fn = (res) ->
      assert.equal res, obj
      done()

    domo.wrap(fn, [mw1, mw2]) obj


  it 'should pass changed object through middlewares', (done) ->
    domo = new Domo()

    obj =
      foo: 'bar'
      lol: 'cat'

    mw1 = (res, next) ->
      next()

    mw2 = (res, next) ->
      res.foo = 'hello'
      next()

    fn = (res) ->
      assert.equal res.foo, 'hello'
      done()

    domo.wrap(fn, [mw1, mw2]) obj

  it 'should allow the use of multiple arguments', (done) ->
    domo = new Domo()

    mw1 = (a, b, next) -> next()
    mw2 = (a, b, next) -> next()

    fn = (a, b) ->
      assert.equal a, 'hello'
      assert.equal b, 'world'
      done()

    domo.wrap(fn, [mw1, mw2])('hello', 'world')

  it 'should remain the context', (done) ->
    domo = new Domo()
    mw1 = (a, b, next) -> next()
    mw2 = (a, b, next) -> next()

    fn = (a, b) ->
      assert.equal this, domo
      done()

    domo.wrap(fn, [mw1, mw2])('hello', 'world')
