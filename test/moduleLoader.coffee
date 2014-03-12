_ = require 'underscore'
async = require 'async'
fs = require 'fs'
assert = require 'assert'
mkdirp = require 'mkdirp'
rimraf = require 'rimraf'

Domo = require '../'

createRes = (msg) ->
  args: ['#test', msg]
  user: 'Test'
  prefix: '!test@test.com'

createModule = (num = 2, suffix = '')->
  mkdirp.sync 'node_modules/test-module'
  fs.writeFileSync 'node_modules/test-module/index.js', """
    module.exports = {
      foo: function() {
        return #{num};
      },
      routes: {
        'hello': function(res) {
          this.say(res.channel, 'hello there#{suffix}');
        }
      }
    }
  """

removeModules = ->
  rimraf.sync 'node_modules/test_module'


describe 'Module loader', ->
  afterEach ->
    removeModules()

  it 'should be able to load modules', (done) ->
    createModule()

    domo = new Domo()

    domo.load 'test-module', (err) ->
      assert.equal domo.modules['test-module'].foo(), 2
      done()

  it 'should be able to purge modules', (done) ->
    createModule()

    domo = new Domo()

    domo.load 'test-module', (err) ->
      throw err if err?

      assert.equal domo.modules['test-module'].foo(), 2

      domo.stop 'test-module', (err) ->
        assert.ok not domo.modules['test-module']?
        done()

  it 'should be able to reload modules', (done) ->
    createModule()

    domo = new Domo()

    domo.load 'test-module', (err) ->
      throw err if err?

      assert.equal domo.modules['test-module'].foo(), 2

      domo.stop 'test-module', (err) ->
        throw err if err?
        assert.ok not domo.modules['test-module']?

        createModule(3)

        domo.load 'test-module', (err) ->
          throw err if err?
          assert.equal domo.modules['test-module'].foo(), 3

          done()

  it 'should register all routes', (done) ->
    createModule()

    domo = new Domo()

    domo.say = (channel, message) ->
      assert.equal message, 'hello there'
      done()

    domo.load 'test-module', (err) ->
      throw err if err?

      domo.matchRoutes 'hello', createRes 'hello world'

  it 'should destroy all routes when a module is destroyed', (done) ->
    createModule()

    domo = new Domo()

    domo.say = (channel, message) ->
      throw new Error 'module route was not destroyed properly'

    domo.load 'test-module', (err) ->
      throw err if err?

      domo.stop 'test-module', (err) ->
        throw err if err?

        domo.matchRoutes 'hello', createRes 'hello world'

        setTimeout ->
          done()
        , 10

  it 'should keep modules working even if they are loaded/unloaded multiple times', (done) ->
    createModule()

    domo = new Domo()

    domo.say = (channel, message) ->
      assert.equal message, 'hello there'
      done()

    async.series [
      _.partial domo.load, 'test-module'
      _.partial domo.stop, 'test-module'
      _.partial domo.load, 'test-module'
      _.partial domo.stop, 'test-module'
      _.partial domo.load, 'test-module'
    ], (err) ->
      throw new Error err if err?
      domo.matchRoutes 'hello', createRes 'hello world'

  it 'should keep modules working even if they are loaded/unloaded multiple times and changed in the middle', (done) ->
    createModule()

    domo = new Domo()

    domo.say = (channel, message) ->
      assert.equal message, 'hello theres'
      done()

    async.series [
      _.partial domo.load, 'test-module'
      _.partial domo.stop, 'test-module'
      (callback) ->
        createModule 2, 's'
        callback null
      _.partial domo.load, 'test-module'
      _.partial domo.stop, 'test-module'
      _.partial domo.load, 'test-module'
    ], (err) ->
      throw new Error err if err?
      domo.matchRoutes 'hello', createRes 'hello world'



