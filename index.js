var Domo, EventEmitter, Router, colors, fs, irc, pack, registerDefaultRoutes, _,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

fs = require('fs');

irc = require('irc');

colors = require('colors');

Router = require('routes');

EventEmitter = require('events').EventEmitter;

_ = require('underscore');

_.str = require('underscore.string');

pack = JSON.parse(fs.readFileSync("" + __dirname + "/package.json"));

registerDefaultRoutes = function(domo) {
  domo.route('!domo', function(res) {
    var chan;
    return domo.say(res.channel, "h :) v" + pack.version + "\nCurrent channels: " + (((function() {
      var _results;
      _results = [];
      for (chan in domo.channels) {
        _results.push(chan);
      }
      return _results;
    })()).join(', ')) + "\n" + pack.repository.url);
  });
  domo.route('!auth :username :password', domo.authenticate, function(res) {
    return domo.say(res.channel, "You are now authed. Hi " + (_.str.capitalize(res.user.username)) + "!");
  });
  domo.route('!join :channel', domo.requiresUser, function(res) {
    return domo.join(res.params.channel);
  });
  domo.route('!join :channel :password', domo.requiresUser, function(res) {
    return domo.join(res.params.channel + ' ' + res.params.password);
  });
  domo.route('!part :channel', domo.requiresUser, function(res) {
    return domo.part(res.params.channel);
  });
  domo.route('!load :module', domo.requiresUser, function(res) {
    return domo.load(res.params.module, function(err) {
      if (err != null) {
        return domo.say(res.channel, err);
      }
      return domo.say(res.channel, "Module '" + res.params.module + "' loaded!");
    });
  });
  return domo.route('!stop :module', domo.requiresUser, function(res) {
    return domo.stop(res.params.module, function(err) {
      if (err != null) {
        domo.say(res.channel, err);
      }
      return domo.say(res.channel, "Module '" + res.params.module + "' stopped!");
    });
  });
};

Domo = (function(_super) {
  __extends(Domo, _super);

  function Domo(config) {
    var module, _i, _len, _ref;
    this.config = config;
    this.stop = __bind(this.stop, this);
    this.load = __bind(this.load, this);
    this.router = new Router;
    this.modules = {};
    this.authedClients = [];
    this.middlewares = [];
    this.config = this.config || {};
    this.use(this.constructRes);
    registerDefaultRoutes(this);
    if (this.config.modules != null) {
      _ref = this.config.modules;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        module = _ref[_i];
        this.load(module);
      }
    }
  }

  Domo.prototype.log = function() {
    return console.log(arguments);
  };

  Domo.prototype.info = function() {
    var msg;
    return console.info.apply(console, ['Info:'.green].concat(__slice.call((function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = arguments.length; _i < _len; _i++) {
        msg = arguments[_i];
        _results.push(msg.green);
      }
      return _results;
    }).apply(this, arguments))));
  };

  Domo.prototype.warn = function() {
    var msg;
    return console.warn.apply(console, ['Warn:'.yellow].concat(__slice.call((function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = arguments.length; _i < _len; _i++) {
        msg = arguments[_i];
        _results.push(msg.yellow);
      }
      return _results;
    }).apply(this, arguments))));
  };

  Domo.prototype.error = function() {
    var msg;
    if (this.config.debug) {
      return console.error.apply(console, ['Error:'.red].concat(__slice.call((function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = arguments.length; _i < _len; _i++) {
          msg = arguments[_i];
          _results.push(msg.red);
        }
        return _results;
      }).apply(this, arguments))));
    }
  };

  Domo.prototype.say = function() {
    return this.irc.say(arguments);
  };

  Domo.prototype.join = function(channel, cb) {
    var _this = this;
    return this.irc.join(channel, function() {
      if (cb != null) {
        return cb.apply(_this, arguments);
      }
    });
  };

  Domo.prototype.part = function(channel, cb) {
    var _this = this;
    return this.irc.part(channel, function() {
      if (cb != null) {
        return cb.apply(_this, arguments);
      }
    });
  };

  Domo.prototype.load = function(mod, cb) {
    var err, module, msg;
    try {
      module = require(mod);
    } catch (_error) {
      err = _error;
      msg = err.code === 'MODULE_NOT_FOUND' ? "Module " + mod + " not found" : "Module " + mod + " cannot be loaded";
      this.error(msg);
      return typeof cb === "function" ? cb(msg) : void 0;
    }
    if (this.modules.hasOwnProperty(mod)) {
      msg = "Module " + mod + " already loaded";
      this.error(msg);
      return typeof cb === "function" ? cb(msg) : void 0;
    }
    this.info("Loaded module " + mod);
    if (typeof Module === 'function') {
      module = new Module(this);
    }
    this.modules[mod] = module;
    if (typeof module.init === "function") {
      module.init(this);
    }
    return typeof cb === "function" ? cb(null) : void 0;
  };

  Domo.prototype.stop = function(mod, cb) {
    var msg, _base;
    if (!this.modules.hasOwnProperty(mod)) {
      msg = "Module " + mod + " not loaded";
      this.error(msg);
      return typeof cb === "function" ? cb(msg) : void 0;
    }
    if (typeof (_base = this.modules[mod]).destruct === "function") {
      _base.destruct();
    }
    delete require.cache[require.resolve(mod)];
    delete this.modules[mod];
    this.info("Stopped module " + mod);
    return typeof cb === "function" ? cb(null) : void 0;
  };

  Domo.prototype.connect = function() {
    var _this = this;
    this.info("Connecting to server " + this.config.address + ".");
    this.irc = new irc.Client(this.config.address, this.config.nick, this.config);
    this.channels = this.irc.chans;
    this.on('error', this.error);
    this.on('registered', function() {
      return _this.info("Connected to server " + _this.config.address + ".\n\tChannels joined: " + (_this.config.channels.join(', ')));
    });
    this.on('message', function(nick, channel, msg, res) {
      return _this.match(msg, res);
    });
    return this.irc;
  };

  Domo.prototype.route = function() {
    var fn, middlewares, path, _i;
    path = arguments[0], middlewares = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), fn = arguments[_i++];
    return this.router.addRoute(path, this.wrap(fn, middlewares));
  };

  Domo.prototype.on = function() {
    var event, fn, middlewares, _i;
    event = arguments[0], middlewares = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), fn = arguments[_i++];
    this.irc.addListener(event, this.wrap(fn, middlewares, false));
    return Domo.__super__.on.apply(this, arguments);
  };

  Domo.prototype.match = function(path, data) {
    var result;
    if ((result = this.router.match(path)) == null) {
      return;
    }
    return result.fn.call(this, _.extend(result, data));
  };

  Domo.prototype.wrap = function(fn, middlewares, useRegisted) {
    var _this = this;
    if (useRegisted == null) {
      useRegisted = true;
    }
    return function() {
      var args, combinedMiddlewares;
      args = Array.prototype.slice.call(arguments, 0);
      combinedMiddlewares = useRegisted ? _this.middlewares.concat(middlewares) : middlewares;
      return _.reduceRight(combinedMiddlewares, function(memo, item) {
        var next;
        next = function() {
          return memo.apply(_this, args);
        };
        return function() {
          return item.apply(this, _.flatten([args, next], true));
        };
      }, fn).apply(_this, arguments);
    };
  };

  Domo.prototype.use = function() {
    return this.middlewares.push(arguments);
  };

  Domo.prototype.constructRes = function(res, next) {
    res.channel = res.args[0];
    res.message = res.args[1];
    res.username = res.user;
    res.user = !this.authedClients.hasOwnProperty(res.prefix) ? null : this.authedClients[res.prefix];
    return next();
  };

  Domo.prototype.authenticate = function(res, next) {
    var user;
    if (this.config.users == null) {
      return this.error("Tried to authenticate. No users configured");
    }
    if (this.authedClients.hasOwnProperty(res.prefix)) {
      return this.say(res.channel, "You are already authed.");
    }
    user = res.user = _.findWhere(this.config.users, {
      username: res.params.username,
      password: res.params.password
    });
    if (user == null) {
      this.error("User " + res.prefix + " tried to authenticate with bad credentials");
      return this.say(res.channel, "Authentication failed. Bad credentials.");
    }
    this.authedClients[res.prefix] = user;
    return next();
  };

  Domo.prototype.requiresUser = function(res, next) {
    if (res.user == null) {
      return this.error("User " + res.prefix + " tried to use '" + res.route + "' route");
    }
    return next();
  };

  return Domo;

})(EventEmitter);

module.exports = Domo;
