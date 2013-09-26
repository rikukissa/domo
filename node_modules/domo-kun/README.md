# Domo
[NPM Package](https://npmjs.org/package/domo-kun)

[Usage example in JavaScript](https://github.com/rikukissa/domo-example)

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

For routing Domo uses [routes](https://github.com/aaronblohowiak/routes.js) library. Received IRC messages are matched to defined paths and the callback functions are called.

````
domo.route('Hello Domo!', function(res) {
  this.say(res.channel, 'Hi ' + res.nick + '!');
});
````
## Middlewares

You can specify route specific middleware functions by adding them as arguments before the callback function.

````
// Only responds if the user who sends the message is authenticated
domo.route('Hello Domo!', domo.requiresUser, function(res) {
  this.say(res.channel, 'Hi ' + res.nick + '!');
});
````

Currently the only built-in middleware is __domo.requiresUser__, that checks if the user who sends a message is authenticated.
Creating custom middlewares is also possible.
#### Example middleware
````
// Reverses received messages
var reverseMessages = function(res, next) {
    res.message = res.message.split('').reverse().join('');
    next();
};
````
It's now possible to use the new middleware like in the example above. It's also possible to use it automatically for all routes by registering it with __domo.use__ method.
````
domo.use(reverseMessages);
````

## Creating custom modules
Domo allows you to write your own modules that can be loaded on runtime without having to restart your Domo instance.

Modules can be loaded with the built-in __!load &lt;moduleName&gt;__  command.

If you are looking for an example module, take a look at [domo-eval](https://github.com/rikukissa/domo-eval).

The only requirement for the module is that it needs to return "init" method that is called when the module is loaded.

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
