# Domo
[![NPM version][npm-image]][npm-url] 
[![Downloads][downloads-image]][npm-url] 
[![Issue tracking][issues-image]][issues-url]
### IRC-bot that lets you easily write your own tasks for your own needs.


[Documentation](http://rikukissa.github.io/domo/)

[NPM Package](https://npmjs.org/package/domo-kun)

![Domo](http://1.bp.blogspot.com/-VJRt-hZit4I/TbjjDINykBI/AAAAAAAABts/E3L3GFL5_hs/s800/09299bd81d5c92fc1e5461d8e04b2e64.gif "Domo")

*Domo at your service!*
## Get Domo-kun

```
npm install domo-kun domo-url
```
```javascript
var Domo, domo;
Domo = require('domo-kun');

domo = new Domo({
  nick: 'Domo',
  userName: 'Domo',
  realName: 'Domo the awesome IRC-bot',
  address: 'irc.freenode.org',
  modules: ['domo-url'],
  channels: ['#domo-kun'],
  users: [
    {
      username: 'domoAdmin',
      password: 'password'
    }
  ],
  debug: true
});

domo.use(domo.basicRoutes());

domo.on('!hello', function(res) {
  res.send("Hello there " + res.nick + "!");
});

domo.connect();
```
## Changelog
### 0.2
* Multiple bug fixes.
* res - object now contains a "send" - method.
* Modules can now export a function that is called with domo's context.
  * Routes in "routes" - property are registered and destroyed automatically.
* A lot of new tests.
* ### Breaking changes
    * To enable basic commands (!auth, !join etc.) you need to register domo.basicRoutes
    with `domo.use(domo.basicRoutes());`


## License

The MIT License (MIT)

Copyright (c) 2014 Riku Rouvila

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[downloads-image]: http://img.shields.io/npm/dm/domo-kun.svg
[npm-url]: https://npmjs.org/package/domo-kun
[npm-image]: http://img.shields.io/npm/v/domo-kun.svg

[issues-url]: https://github.com/rikukissa/domo/issues
[issues-image]: http://img.shields.io/github/issues/rikukissa/domo.svg
