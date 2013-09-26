var james = require('../index.js');

function Pipeline(stream) {
  this.stream = stream;
}

Pipeline.prototype.transform = function(dest) {
  if (typeof dest === 'function') {
    dest = dest();
  }

  this.stream.pipe(dest);
  return new Pipeline(dest);
};

Pipeline.prototype.write = function(dest) {
  if (typeof dest === 'string' ) {
    dest = james.dest(dest);
  }
  this.stream.pipe(dest);
  return dest;
};

module.exports = Pipeline;
