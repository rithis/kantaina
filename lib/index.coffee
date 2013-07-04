DepGraph = require "dep-graph"
events = require "events"
_ = require "lodash"
w = require "when"


parseArguments = (f) ->
  f.toString()
    .match(/function\s+\w*\s*\((.*?)\)/)[1]
    .split(/\s*,\s*/)
    .filter((arg) -> arg.length > 0)


class Container extends events.EventEmitter
  constructor: ->
    @graph = new DepGraph
    @factories = {}
    @values = container: @

  set: (key, value) ->
    if _.isFunction value
      @factories[key] = value
      delete @values[key]

      for dependency in parseArguments value
        @graph.add key, dependency

      # check cyclic dependency
      @graph.getChain key

    else
      @values[key] = value
      @emit key, value

  has: (key) ->
    @values.hasOwnProperty(key) or @factories.hasOwnProperty(key)

  unless: (key, value) ->
    @set key, value unless @has key

  get: (keys) ->
    getter = (key) =>
      deferred = w.defer()

      if @values.hasOwnProperty key
        deferred.resolve @values[key]

      else if _.isFunction @factories[key]
        @values[key] = do @inject @factories[key]
        @values[key].then (value) =>
          @values[key] = value
          deferred.resolve value
          @emit key, value

      else
        deferred.resolve undefined

      deferred.promise


    if _.isArray keys
      w.map keys, getter
    else
      getter keys

  inject: (factory) ->
    =>
      @get(parseArguments factory).then (dependencies) ->
        factory.apply null, dependencies


module.exports = ->
  new Container

module.exports.Container = Container
