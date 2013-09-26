# Synopsis

Stylus to CSS transformer for [James.js](https://github.com/leonidas/james.js).

```javascript
var james  = require('james'),
    stylus = require('james-stylus');

james.task('default', function() {

  james.files('src/**/*.styl').forEach(function(file) {
    james.read(file)
      .transform(stylus({filename: file}))
      .write(process.stdout);
  });
});
```

## API

`stylus(options)`: Return a new Stylus to CSS transformer. Available options are listed in 
[Stylus documentation](http://learnboost.github.com/stylus/docs/js.html).
