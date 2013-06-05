kantaina = require ".."
w = require "when"

# create container
container = kantaina()

# define scalar value
container.set "a", 1

# define sync factory
container.set "b", (a) ->
  a + 1

# define async factory
container.set "c", (a, b) ->
  deffered = w.defer()

  setTimeout ->
    deffered.resolve a + b
  , 1000

  deffered.promise

# receive value resolved by async factory
container.get("c").then (value) ->
  # writes "3" after one second
  console.log value

# wrap function and inject dependencies
wrapped = container.inject (a, b, c) ->
  a + b + c

# wrapped function returns promise
wrapped().then (value) ->
  # writes "6" immediately because "c" already resolved
  console.log value
