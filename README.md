# kantaina

> Wonderful asynchronous DI container based on promises.

[![Build Status](https://travis-ci.org/rithis/kantaina.png?branch=master)](https://travis-ci.org/rithis/kantaina)
[![Coverage Status](https://coveralls.io/repos/rithis/kantaina/badge.png?branch=master)](https://coveralls.io/r/rithis/kantaina?branch=master)
[![Dependency Status](https://gemnasium.com/rithis/kantaina.png)](https://gemnasium.com/rithis/kantaina)
[![NPM version](https://badge.fury.io/js/kantaina.png)](http://badge.fury.io/js/kantaina)

## Usage

```coffee
kantaina = require "kantaina"
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

# inject dependencies into function
promise = container.inject (a, b, c) ->
  a + b + c

# inject method returns promise
promise.then (value) ->
  # writes "6" immediately because "c" already resolved
  console.log value
```
