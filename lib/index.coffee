_ = require "lodash"
w = require "when"


parseArguments = (f) ->
  f.toString()
    .match(/function\s+\w*\s*\((.*?)\)/)[1]
    .split(/\s*,\s*/)
    .filter((arg) -> arg.length > 0)


class Container
  constructor: ->
    @factories = {}
    @values = {}

  set: (key, value) ->
    if _.isFunction value
      @factories[key] = value
    else
      @values[key] = value

  get: (keys) ->
    if _.isArray keys
      @_getMany keys
    else
      @_getOne keys

  inject: (factory) ->
    =>
      deferred = w.defer()
      args = parseArguments factory

      @_getMany(args).then (dependencies) ->
        deferred.resolve factory.apply null, dependencies

      deferred.promise

  _getOne: (key) ->
    deferred = w.defer()

    if @values.hasOwnProperty key
      deferred.resolve @values[key]

    else if _.isFunction @factories[key]
      @values[key] = @inject(@factories[key])()
      @values[key].then (value) =>
        @values[key] = value
        deferred.resolve value

    else
      deferred.resolve undefined

    deferred.promise

  _getMany: (keys) ->
    promises = keys.map (key) =>
      @_getOne key

    w.all promises


module.exports = ->
  new Container

module.exports.Container = Container
