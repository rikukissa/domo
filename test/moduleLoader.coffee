fs = require 'fs'
assert = require 'assert'
mkdirp = require 'mkdirp'
rimraf = require 'rimraf'

Domo = require '../'

createRes = (msg) ->
  args: ['#test', msg]
  user: 'Test'
  prefix: '!test@test.com'

createModule = (num = 2)->
  mkdirp.sync 'node_modules/test-module'
  fs.writeFileSync 'node_modules/test-module/index.js', """
    module.exports = {
      foo: function() {
        return #{num};
      },
      routes: {
        'hello': function(res) {
          this.say(res.channel, 'hello there');
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

        removeModules()
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


