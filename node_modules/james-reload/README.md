# James.js reload 
Browser reload plugin for [James.js](https://github.com/leonidas/james.js)

```javascript
var reload = require('james-reload')({
  proxy: 9001,
  reload: 9002
});

reload(); // location.reload in browser
reload(true); // refresh stylesheets

```