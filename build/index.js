var Container, DepGraph, events, parseArguments, w,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

parseArguments = require("parse-fn-args");

DepGraph = require("dep-graph");

events = require("events");

w = require("when");

Container = (function(_super) {
  __extends(Container, _super);

  function Container() {
    this.clean();
  }

  Container.prototype.set = function(key, dependencies, value) {
    var dependency, _i, _len;
    if (value === void 0) {
      value = dependencies;
      dependencies = void 0;
    }
    if (typeof value === "function") {
      this.factories[key] = value;
      delete this.values[key];
      delete this.graph.map[key];
      if (!dependencies) {
        dependencies = parseArguments(value);
      }
      for (_i = 0, _len = dependencies.length; _i < _len; _i++) {
        dependency = dependencies[_i];
        this.graph.add(key, dependency);
      }
      this.graph.getChain(key);
      if (this.listeners(key).length > 0) {
        this.get(key);
      }
    } else {
      this.values[key] = value;
      this.emit(key, value);
    }
    return this;
  };

  Container.prototype.has = function(key) {
    return this.values.hasOwnProperty(key) || this.factories.hasOwnProperty(key);
  };

  Container.prototype.unless = function(key, dependencies, value) {
    if (!this.has(key)) {
      this.set(key, dependencies, value);
    }
    return this;
  };

  Container.prototype.get = function(keys) {
    var getter,
      _this = this;
    getter = function(key) {
      var deffered;
      if (_this.values.hasOwnProperty(key)) {
        return w.resolve(_this.values[key]);
      } else if (_this.factories[key]) {
        return _this.values[key] = _this.inject(_this.graph.map[key], _this.factories[key]).then(function(value) {
          _this.values[key] = value;
          _this.emit(key, value);
          return value;
        });
      } else {
        deffered = w.defer();
        _this.once(key, deffered.resolve);
        return deffered.promise;
      }
    };
    if (Array.isArray(keys)) {
      return w.map(keys, getter);
    } else {
      return getter(keys);
    }
  };

  Container.prototype.inject = function(dependencies, factory) {
    var injector,
      _this = this;
    if (dependencies == null) {
      dependencies = [];
    }
    injector = function(factory, dependencies) {
      if (!dependencies) {
        dependencies = parseArguments(factory);
      }
      return _this.get(dependencies).spread(factory);
    };
    if (factory === void 0) {
      factory = dependencies;
      dependencies = void 0;
    }
    if (Array.isArray(factory)) {
      return w.map(factory, injector);
    } else {
      return injector(factory, dependencies);
    }
  };

  Container.prototype.clean = function() {
    this.graph = new DepGraph;
    this.factories = {};
    return this.values = {
      container: this
    };
  };

  return Container;

})(events.EventEmitter);

module.exports = function() {
  return new Container;
};

module.exports.Container = Container;
