# Domo
[NPM Package](https://npmjs.org/package/domo-kun)

* Best irc-bot ever
* Easy to configure

## Get Domo-kun

```
npm install
```
```
var Domo, domo;
Domo = require('domo-kun');
domo = new Domo(config);
domo.connect();
```

## Configuration
````
var config = {
  nick: 'Domo',
  userName: 'Domo',
  realName: 'Domo the awesome IRC-bot',
  address: 'irc.quakenet.org',
  channels: ['#riku'],
  users: [{ // Array of users able to control your Domo instance
      username: 'admin',
      password: 'lolwut'
    }],
  modules: ['domo-eval'], // Modules to be loaded when Domo connects
  debug: true
};

````
## Creating routes

domo.route(path, callback);

For routing Domo uses routes library. Received IRC messages are matched to defined paths and the callback functions are called.

````
domo.route('Hello Domo!', function(res) {
  this.say(res.channel, 'Hi ' + res.nick + '!');
});
````
## Built in IRC Commands
* !domo
  * Print Domo info


* !auth &lt;username&gt; &lt;password&gt;
  * Authenticate (Probably better to do this with private message)


* !join &lt;channel&gt; &lt;password&gt;
  * __Requires authentication__
  * Tell Dōmo-kun to join channel


* !part [channels..]
  * __Requires authentication__
  * Tell Dōmo-kun to leave channel


* !load &lt;module&gt;
  * __Requires authentication__
  * Load domo module from node_modules directory


* !stop &lt;module&gt;
  * __Requires authentication__
  * Stop module and detach it from message events

![alt text](http://1.bp.blogspot.com/-VJRt-hZit4I/TbjjDINykBI/AAAAAAAABts/E3L3GFL5_hs/s800/09299bd81d5c92fc1e5461d8e04b2e64.gif "Domo")
