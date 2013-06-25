# Domo

* Best irc-bot ever
* Easy to configure
* Creating plugins for Domo is the most awesome thing ever

## Installation

```
git clone git@github.com:rikukissa/domo.git
cd domo
npm install
```

## Configuration

Edit the config.example.json file and rename it to config.json

* nick, username, realName
  * Basic IRC configuration. Self-explanatory.
* servers
  * List of servers and their configuration
    * __address__ - server address
    * __channels__ - channels to automatically join
    * __users__ - list of authorized users
* users
  * List of authorized users
* modules
  * Modules to load on startup

## Starting things up
```
coffee domo.coffee
```
## Commands
* !domo
  * Print bot info
* !auth &lt;username&gt; &lt;password&gt;
  * Authenticate (Probably better to do this with private message)
* !nick <nickname>
  * Change Domo's nickname
* !join [channels..]
  * __Requires authentication__
  * Tell Dōmo-kun to join channels (supports multiple arguments as a space separated string)
* !part [channels..]
  * __Requires authentication__
  * Tell Dōmo-kun to leave channels (supports multiple arguments as a space separated string)
* !save
  * __Requires authentication__
  * Save current state (channels, modules...) to config.json
* !load &lt;module&gt;
  * __Requires authentication__
  * Load domo module from node_modules directory
![alt text](http://1.bp.blogspot.com/-VJRt-hZit4I/TbjjDINykBI/AAAAAAAABts/E3L3GFL5_hs/s800/09299bd81d5c92fc1e5461d8e04b2e64.gif "Domo")