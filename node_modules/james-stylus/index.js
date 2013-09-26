var james = require('james'),
   stylus = require('stylus');

module.exports = function(options) {
  return james.createStream(function(file, callback) {
    var renderer = stylus(file, options);
    if (options && options.use) renderer.use(options.use);
    renderer.render(function(err, css) {
      if (err) {
        throw Error(err);
      }
      callback(css);
    });
  });
};
