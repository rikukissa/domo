# Domo
IRC-bot that lets you easily write your own tasks for your own needs.

[Documentation](http://rikukissa.github.io/domo/)

[NPM Package](https://npmjs.org/package/domo-kun)

[Usage examples in JavaScript](https://github.com/rikukissa/domo-example) 

![Domo](http://1.bp.blogspot.com/-VJRt-hZit4I/TbjjDINykBI/AAAAAAAABts/E3L3GFL5_hs/s800/09299bd81d5c92fc1e5461d8e04b2e64.gif "Domo")

*Domo at your service!*
## Get Domo-kun

```
npm install domo-kun
```
```
var Domo, domo;
Domo = require('domo-kun');

domo = new Domo({
  nick: 'Domo',
  userName: 'Domo',
  realName: 'Domo the awesome IRC-bot',
  address: 'irc.freenode.org',
  channels: ['#domo-kun'],
  users: [
    {
      username: 'domoAdmin',
      password: 'password'
    }
  ],
  debug: true
});

domo.connect();
```
