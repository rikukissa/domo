var colors, fs, irc, _,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

fs = require('fs');

irc = require('irc');

colors = require('colors');

_ = require('underscore');

module.exports = (function(_super) {
  __extends(exports, _super);

  function exports() {
    this.stop = __bind(this.stop, this);
    this.load = __bind(this.load, this);
    var module, _i, _len, _ref;
    this.middlewares = [];
    this.modules = {};
    exports.__super__.constructor.apply(this, arguments);
    this.on('error', function(event) {
      return this.error(JSON.stringify(event.command.toUpperCase()));
    });
    if (this.opt.modules != null) {
      _ref = this.opt.modules;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        module = _ref[_i];
        this.load(module);
      }
    }
  }

  exports.prototype.connect = function() {
    this.info("Connecting to " + this.opt.server);
    exports.__super__.connect.apply(this, arguments);
    return this.once('registered', function() {
      var channel;
      return this.info("Connected to " + this.opt.server, "Current channels: " + (((function() {
        var _results;
        _results = [];
        for (channel in this.chans) {
          _results.push(channel);
        }
        return _results;
      }).call(this)).join(', ')));
    });
  };

  exports.prototype.log = function() {
    return console.log.apply(console, arguments);
  };

  exports.prototype.info = function() {
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

  exports.prototype.warn = function() {
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

  exports.prototype.error = function() {
    var msg;
    if (this.opt.debug) {
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

  exports.prototype.load = function(mod, cb) {
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

  exports.prototype.stop = function(mod, cb) {
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

  exports.prototype.addListener = function() {
    var event, fn, middlewares, _i;
    event = arguments[0], middlewares = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), fn = arguments[_i++];
    return exports.__super__.addListener.call(this, event, this.wrap(fn, middlewares));
  };

  exports.prototype.once = function() {
    var event, fn, middlewares, _i;
    event = arguments[0], middlewares = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), fn = arguments[_i++];
    return exports.__super__.once.call(this, event, this.wrap(fn, middlewares));
  };

  exports.prototype.wrap = function(fn, middlewares) {
    var _this = this;
    return function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return _.reduceRight(_this.middlewares.concat(middlewares), function(memo, item) {
        var next;
        next = function() {
          return memo.apply(_this, args);
        };
        return function() {
          return item.apply(this, __slice.call(args).concat([next]));
        };
      }, fn).apply(_this, arguments);
    };
  };

  exports.prototype.use = function() {
    var _ref;
    return (_ref = this.middlewares).push.apply(_ref, arguments);
  };

  return exports;

})(irc.Client);
