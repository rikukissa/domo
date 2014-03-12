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

describe 'Module loader', ->
  domo = null

  beforeEach ->
    mkdirp.sync 'node_modules/test-module'

  afterEach ->
    rimraf.sync 'node_modules/test-module'
    domo.stop 'test-module'

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

  it 'should be able to reload modules when domo is connected to irc', (done) ->
    createModule()

    domo = new Domo
      nick: 'domox'
      address: 'irc.freenode.org'
      channels: ['#domo-kun']

    domo.connect()

    domo.on 'registered', ->

      domo.load 'test-module', (err) ->
        throw err if err?

        assert.equal domo.modules['test-module'].foo(), 2

        domo.stop 'test-module', (err) ->

          throw err if err?
          assert.ok not domo.modules['test-module']?

          createModule(15)

          domo.load 'test-module', (err) ->
            throw err if err?
            assert.equal domo.modules['test-module'].foo(), 15

            done()

  it 'should be able to reload modules through message dispatcher when domo is connected to irc', (done) ->
    createModule()

    helloSaid = false

    domo = new Domo
      nick: 'domox'
      address: 'irc.freenode.org'
      channels: ['#domo-kun']
      users: [
        username: 'admin'
        password: 'admin'
      ]

    domo.use domo.basicRoutes

    domo.connect()

    domo.on 'registered', ->

      domo.say = (channel, message) ->
        return helloSaid = true if message is 'hello there'

        return unless helloSaid

        done() if message is 'hello theree'

      res = createRes 'hello'

      res.params =
        username: 'admin'
        password: 'admin'

      domo.authenticate res, ->
        domo.matchRoutes '!load test-module', createRes('!load test-module')
        domo.matchRoutes 'hello', createRes('hello')
        domo.matchRoutes '!stop test-module', createRes('!load test-module')
        createModule(12, 'e')
        domo.matchRoutes '!load test-module', createRes('!load test-module')
        domo.matchRoutes 'hello', createRes('hello')



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



