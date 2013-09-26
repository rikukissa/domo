var assert = require('assert'),
    fs     = require('fs'),
    stream = require('readable-stream'),
    path   = require('path'),
    mkdirp = require('mkdirp'),
    james  = require('../index');

describe('james', function(){

  after(function() {
    fs.rmdirSync('test/fixtures');
  });

  describe('#list', function(){
    var files = [
      'test/fixtures/hello.js',
      'test/fixtures/world.js'
    ];

    beforeEach(function(){
      for (var i = 0; i < files.length; i++) {
        var file = files[i];
        mkdirp.sync(path.dirname(file));
        fs.writeFileSync(file, 'console.log(hello);', 'utf8');
      }
    });

    afterEach(function(){
      for (var i = 0; i < files.length; i++) {
        var file = files[i];
        fs.unlinkSync(file);
      }
    });

    it('should return matching files for glob a glob pattern', function(){
        assert.deepEqual(james.list('test/fixtures/**/*.js'), files);
    });
  });

  describe('#watch', function(){

    var file = 'test/fixtures/hello.js';

    beforeEach(function(){
      mkdirp.sync(path.dirname(file));
      fs.writeFileSync(file, 'console.log(hello);', 'utf8');
    });

    afterEach(function(){ fs.unlinkSync(file); });

    it('should return added/changed/deleted file for a glob pattern', function(done){

      james.watch('test/**/*.js', function(event, file) {
        assert.equal(event, 'changed');
        assert.equal(file, 'test/fixtures/hello.js');
        done();
      });

      setTimeout(function(){
        var now = new Date();
        fs.utimesSync(file, now, now);
      },
        1000);
    });
  });

  describe('#read', function(){
    var file = {
      name:    'console.log("hello");',
      content: 'test/fixtures/foo.js'
    };

    beforeEach(function(){
      mkdirp.sync(path.dirname(file.name));
      fs.writeFileSync(file.name, file.content, 'utf8');
    });

    afterEach(function(){
      fs.unlinkSync(file.name);
    });

    it('should return a read stream for the file', function(done){
      var src  = james.read(file.name),
          dest = new stream.PassThrough();

      src.write(dest);

      dest.on('finish', function() {
        assert.equal(dest.read().toString(), file.content);
        done();
      });
    });
  });

  describe('#write', function(){
    var file = {
      name:    'test/fixtures/foo.js',
      content: 'console.log("hello");'
    };

    afterEach(function(){
      fs.unlinkSync(file.name);
    });

    it('should return a write stream for the file', function(done){
      var src  = new stream.PassThrough(),
          dest = james.dest(file.name);

      src.pipe(dest);
      src.write(file.content);
      src.end();

      dest.on('close', function(){
        assert.equal(fs.readFileSync(file.name, 'utf8'), file.content);
        done();
      });
    });
  });

  describe('#run', function(){
    it('should run the listed tasks', function(done){
      var foo = false;

      james.task('foo', function() {
        foo = true;
      });

      james.task('bar', function() {
        assert(foo);
        done();
      });

      james.task('default', ['foo', 'bar']);

      james.run('default');
    });
  });

  describe('#createTransformation', function(){
    it('should return a stream for the transformation operation', function(done){
      var src  = new stream.PassThrough(),
          dest = new stream.PassThrough(),
          operation,
          transform;

      operation = function(file, callback) {
        callback(file + " World!");
      };

      transform = james.createTransformation(operation);

      src.pipe(transform).pipe(dest);
      src.write("Hello");
      src.end();

      dest.on('finish', function(){
        assert.equal(dest.read(), "Hello World!");
        done();
      });
    });
  });

  describe('Pipeline', function() {
    describe('#transform', function() {

      it('should add transform stream to pipeline', function(done) {
        var src  = new stream.PassThrough(),
            dest = new stream.PassThrough(),
            operation,
            createHelloStream;

        createHelloStream = function(name) {
          name = name || 'World';
          return james.createStream(function(file, callback) {
            callback(file + ' and ' + name);
          });
        };

        james.read(src)
          .transform(createHelloStream)
          .transform(createHelloStream('Rich'))
          .write(dest);
        src.write('Hello James');
        src.end();

        dest.on('finish', function(){
          assert.equal(dest.read().toString(), 'Hello James and World and Rich');
          done();
        });
      });
    });

    describe('#write', function() {
      it('should write to a given stream', function(done) {
        var src  = new stream.PassThrough(),
            dest = new stream.PassThrough();

        james.read(src).write(dest);

        src.write("Hello World!");
        src.end();

        dest.on('finish', function(){
          assert.equal(dest.read(), "Hello World!");
          done();
        });
      });

      it('should write to a given file', function(done) {
        var src  = new stream.PassThrough(),
            file = 'test/fixtures/write.txt',
            dest;

        dest = james.read(src).write(file);
        src.write("Hello World!");
        src.end();

        dest.on('close', function(){
          assert.equal(fs.readFileSync(file, 'utf8'), "Hello World!");
          fs.unlinkSync(file);
          done();
        });
      });
    });
  });
});
