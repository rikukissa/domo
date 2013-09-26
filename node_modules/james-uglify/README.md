# Synopsis

UglifyJS 2 transformer for [James.js](https://github.com/leonidas/james.js).

```javascript
var james  = require('james'),
    uglify = require('james-uglify');

james.task('default', function() {

  james.files('src/**/*.js').forEach(function(file) {
    james.read(file)
      .transform(uglify)
      .write(process.stdout);
  });
});
```

## API

`uglify(options)`: Return a new UglifyJS 2 transformer. Available options are listed in
[Uglify documentation](https://github.com/mishoo/UglifyJS2#the-simple-way).
