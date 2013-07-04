DepGraph = require "dep-graph"
events = require "events"
w = require "when"


parseArguments = (f) ->
  f.toString()
    .match(/function\s+\w*\s*\((.*?)\)/)[1]
    .split(/\s*,\s*/)
    .filter((arg) -> arg.length > 0)


class Container extends events.EventEmitter
  constructor: ->
    @factories = {}
    @values = container: @
    @graph = new DepGraph

  set: (key, value) ->
    if typeof value is "function"
      @factories[key] = value
      delete @values[key]

      # check cyclic dependency
      @graph.add key, dependency for dependency in parseArguments value
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

      else if @factories[key]
        @values[key] = @inject @factories[key]
        @values[key].then (value) =>
          @values[key] = value
          deferred.resolve value
          @emit key, value

      else
        deferred.resolve undefined

      deferred.promise

    if Array.isArray keys
      w.map keys, getter
    else
      getter keys

  inject: (factory) ->
    @get(parseArguments factory).spread factory


module.exports = ->
  new Container

module.exports.Container = Container
