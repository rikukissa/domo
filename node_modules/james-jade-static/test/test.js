var assert = require('assert'),
    stream = require('readable-stream'),
    jade   = require('../index.js');

describe('james-jade-static', function() {

  it('should return Jade to HTML transformation stream', function(done){
    var src  = new stream.PassThrough(),
        dest = new stream.PassThrough();

    src.pipe(jade()).pipe(dest);
    src.write('\ndiv\n  span Hello World!\n');
    src.end();

    dest.on('finish', function() {
      assert.equal(dest.read().toString(), '<div><span>Hello World!</span></div>');
      done();
    });
  });
});
