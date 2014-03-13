_      = require 'underscore'
assert = require 'assert'
Domo   = require '../'

createRes = (msg) ->
  args: ['#test', msg]
  user: 'Test'
  prefix: '!test@test.com'

noopMw = (res, next) -> next()

log = console.log

describe 'Domo messaging', ->

  afterEach ->
    console.log = log

  it 'should console.log errors with color red', (done) ->
    domo = new Domo()

    lines = 0

    console.log = (prefix, message) ->
      assert.equal prefix, 'Error:'.red
      assert.equal message, 'foo\nbar\nbaz'.red
      done()

    domo.error('foo', 'bar', 'baz')

  it 'should console.log warnings with color yellow', (done) ->
      domo = new Domo()

      lines = 0

      console.log = (prefix, message) ->
        assert.equal prefix, 'Warning:'.yellow
        assert.equal message, 'foo\nbar\nbaz'.yellow
        done()

      domo.warn('foo', 'bar', 'baz')

  it 'should console.log notifications with color green', (done) ->
      domo = new Domo(debug: true)

      lines = 0

      console.log = (prefix, message) ->
        assert.equal prefix, 'Notify:'.green
        assert.equal message, 'foo\nbar\nbaz'.green
        done()

      domo.notify('foo', 'bar', 'baz')

  it 'should console.log notifications only if debug config is true', (done) ->
      domo = new Domo()

      lines = 0

      console.log = (prefix, message) ->
        throw new Error 'Notification logged even though its not allowed in config'

      domo.notify('foo', 'bar', 'baz')

      setTimeout ->
        done()
      , 100
