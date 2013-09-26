var jade  = require('jade'),
    james = require('james');

module.exports = function(options) {
  return james.createStream(function(file, callback) {
    callback(jade.compile(file, options)());
  });
};
