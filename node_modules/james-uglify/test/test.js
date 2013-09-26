var assert = require('assert'),
    stream = require('readable-stream'),
    james  = require('james'),
    uglify = require('../index.js');

describe('james-uglify', function() {
  it('should minify js files', function(done) {
    var src  = new stream.PassThrough(),
        dest = new stream.PassThrough();

    src.pipe(uglify()).pipe(dest);
    src.write('function hello(){var foo = 3; var bar = 4};');
    src.end();

    dest.on('finish', function() {
      assert.equal(dest.read().toString(), 'function hello(){}');
      done();
    });
  });
});
