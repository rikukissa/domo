require('coffee-script');

var logger    = require('./logger.js'),
    james     = require(process.cwd() + '/node_modules/james/index.js'),
    jamesfile = require(process.cwd() + '/Jamesfile'),
    tasks     = process.argv.slice(2);

if (!tasks.length) {
  tasks.push('default');
}

for (var i=0; i < tasks.length; ++i) {
  james.run(tasks[i]);
}

process.on('uncaughtException', function(err){
  logger.error(err.message);
  process.exit(1);
});
