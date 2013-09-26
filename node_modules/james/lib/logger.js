var colors = require('colors'),
    BELL   = '\u0007',
    decorate;

decorate = function(message, color, bell) {
  if (process.stdout.isTTY) {
    return bell ? (message + bell)[color] : message[color];

  } else {
    return message;
  }
};

exports.info = function(message) {
  console.log(decorate(message, 'green'));
};

exports.warn = function(message) {
  console.log(decorate('WARN: ' + message, 'yellow'));
};

exports.error = function(message) {
  console.error(decorate('ERROR: ' + message, 'red', BELL));
};
