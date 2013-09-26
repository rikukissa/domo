var assert = require('assert'),
    stream = require('readable-stream'),
    james  = require('james'),
    stylus = require('../index.js');

describe('james-stylus', function() {
  it('should transform stylus files to css', function(done) {
    var src  = new stream.PassThrough(),
        dest = new stream.PassThrough();

    src.pipe(stylus()).pipe(dest);
    src.write('body\n  background red');
    src.end();

    dest.on('finish', function() {
      assert.equal(dest.read().toString(),
        'body {\n  background: #f00;\n}\n');
      done();
    });
  });

  it('should inject plugins via use()', function(done) {
    var myPlugin = function(style){
      assert(style !== null);
      done();
    };

    var src  = new stream.PassThrough(),
        dest = new stream.PassThrough();

    src.pipe(stylus({use: myPlugin})).pipe(dest);
    src.write('body\n  background red');
    src.end();
  });
});
