# Synopsis

[![Build Status](https://travis-ci.org/leonidas/james.js.png?branch=master)](https://travis-ci.org/leonidas/james.js)

James.js is a composable build tool which prefers code over configuration.

```javascript
// Jamesfile.js
var james  = require('james'),
    coffee = require('james-coffee'),
    uglify = require('james-uglify');

james.task('build', function() {

  james.list('src/**/*.coffee').forEach(function(file) {

    james.read(file)
      .transform(coffee({bare: true}))
      .transform(uglify)
      .write(file.replace('src', 'dist').replace('.coffee', '.min.js'));
  });
});

james.task('watch', function() {
  james.watch('test/**/*.coffee', function(event, file) {
    james.read(file)
      .transform(coffee({bare: true}))
      .write(file.replace('.coffee', '.js')));
  });
});

james.task('default', ['build', 'watch']);
```

## API

`james.task(name, task)` Define a new task with given `name`. `task` can be either a callback or a list of existing task names.

`james.list(glob1, glob2, ...)` List files matching to a given `glob`s.

`james.watch(glob, callback)` Watch files matching the `glob`.

`james.dest(filename)` Returns a [Writable stream](http://nodejs.org/api/stream.html#stream_class_stream_writable).
Handy if you want to concatenate files to a single destination.

`james.read(filename)` Read a file. Returns a `Pipeline` object. Use `Pipeline.stream`, if you need an access
to the underlying ReadableStream.

`james.wait(writes)` Waits for `Pipeline.write` operation to finish. `writes` can be a single write operation or a list of
write operations, e.g.,

```javascript
js = james.list('src/**/*.coffee').map(function(file) {
  james.read(file).transform(coffee).write(file.replace(/\.coffee/, '.js'));
});

// After james.wait, it's safe to read files, e.g., with browserify or r.js
james.wait(js, function(js) { js.forEach(function(filename){ james.read(filename).write(process.stdout) }) });
```

`Pipeline.transform(transformation)` Transform the underlying stream with a given `transformation`. `transformation` can be
either a [Transform stream](http://nodejs.org/api/stream.html#stream_class_stream_transform) or a Transform stream constructor.

`Pipeline.write(dest)` Write the underlying stream to a `dest`. `dest` can be either a
[Writable stream](http://nodejs.org/api/stream.html#stream_class_stream_writable) or a filename. Returns the Writable stream
with `stream.promise` property. Promise is resolved when the file has been written. Promise is used by `james.wait`.

## Command-line

By default, james runs `default` task. Specific tasks can be run by listing them on the command-line.

```
> npm install -g james
> james
> james build watch
```

## Transformations

Existing transformations are listed in the [wiki](https://github.com/leonidas/james.js/wiki). Please add your transformations, too!

### Creating new transformations

James uses node.js streams for transformations.
Create a [Transform stream](http://nodejs.org/api/stream.html#stream_class_stream_transform),
or use `james.createTransformation` helper.

```javascript
// james-coffee/index.js
var james  = require('james'),
    coffee = require('coffee-script');

coffee.createStream = function() {
  return james.createTransformation(function(content, callback) {

    // Process the file content and call the callback with the result.
    callback(coffee.compile(content));
  });
};

james.read('./hello.coffee')
  .transform(coffee.createStream)
  .write(process.stdout);
```
