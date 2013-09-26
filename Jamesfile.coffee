james  = require 'james'
jade   = require 'james-jade-static'
stylus = require 'james-stylus'
uglify = require 'james-uglify'

shim       = require 'browserify-shim'
browserify = require 'browserify'
coffeeify  = require 'coffeeify'

transmogrifyCoffee = (debug) ->
  libs =
    jquery:
      path: './src/js/vendor/jquery/jquery.js'
      exports: '$'
    rainbow:
      path: './src/js/vendor/rainbow/js/rainbow.js'
      exports: 'Rainbow'
    'rainbow-js':
      path: './src/js/vendor/rainbow/js/language/javascript.js'
      exports: 'Rainbow'
    'rainbow-generic':
      path: './src/js/vendor/rainbow/js/language/generic.js'
      exports: 'Rainbow'

  bundle = james.read shim(browserify(), libs)
    .transform(coffeeify)
    .require(require.resolve('./src/js/main.coffee'), entry: true)
    .bundle
      debug: debug

  bundle = bundle.transform(uglify) unless debug
  bundle.write('js/bundle.js')

transmogrifyJade = (file) ->
  james.read(file)
    .transform(jade)
    .write(file
      .replace('src/', '')
      .replace('.jade', '.html'))


transmogrifyStylus = (file) ->
  james.read(file)
    .transform(stylus({'include css': true}))
    .write(file
      .replace('src/', '')
      .replace('.stylus', '.css')
      .replace('.styl', '.css'))

james.task 'browserify', -> transmogrifyCoffee false
james.task 'browserify_debug', -> transmogrifyCoffee true

james.task 'jade_static', ->
  james.list('src/**/*.jade').forEach transmogrifyJade

james.task 'stylus', ->
  james.list('src/**/*.styl').forEach transmogrifyStylus

james.task 'actual_watch', ->
  james.watch 'src/**/*.coffee', -> transmogrifyCoffee true
  james.watch 'src/**/*.jade', (ev, file) -> transmogrifyJade file
  james.watch 'src/**/*.styl', (ev, file) -> transmogrifyStylus file

james.task 'server', =>
  require('./server/server.coffee')

james.task 'reload', =>
  reload = require('james-reload')
    proxy: 9001
    reload: 9002
  james.watch './js/**/*.js', -> reload()
  james.watch './css/**/*.css', -> reload(true)
  james.watch './*.html', -> reload()

james.task 'build_debug', ['browserify_debug', 'jade_static', 'stylus']
james.task 'build', ['browserify', 'jade_static', 'stylus']
james.task 'watch', ['build_debug', 'actual_watch']
james.task 'default', ['build_debug']
james.task 'httpd', ['server', 'reload']

