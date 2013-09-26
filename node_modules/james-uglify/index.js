var james = require('james'),
   uglify = require('uglify-js');

module.exports = function(options) {
  options = options || {};
  options.fromString = true;
  return james.createStream(function(content, callback) {
    callback(uglify.minify(content, options).code);
  });
};
