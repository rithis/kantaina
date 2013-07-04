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

# try to override already defined value
container.unless "a", 100

# receive value resolved by async factory
container.get("c").then (value) ->
  # writes "3" after one second
  console.log value

# inject dependencies to the function
promise = container.inject (a, b, c) ->
  a + b + c

# inject method returns promise
promise.then (value) ->
  # writes "6" immediately because "c" already resolved
  console.log value
