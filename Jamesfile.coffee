james = require("james")
coffee = require("james-coffee")
uglify = require("james-uglify")

james.task "build", ->
  james.list("src/*.coffee").forEach (file) ->
    james.read(file).transform(coffee(bare: true))
      .transform(uglify).write file.replace("src", ".").replace(".coffee", ".js")


james.task "actual_watch", ->
  james.watch "src/*.coffee", (event, file) ->
    james.read(file).transform(coffee(bare: true))
      .transform(uglify).write file.replace("src", ".").replace(".coffee", ".js")

james.task 'default', ['build']
james.task 'watch', ['build', 'actual_watch']
