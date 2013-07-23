kantaina = require ".."
sinon = require "sinon"
chai = require "chai"
w = require "when"


describe "kantaina()", ->
  chai.use require "chai-as-promised"
  chai.use require "sinon-chai"
  chai.should()

  it "should return new kantaina.Container()", ->
    kantaina().should.be.an.instanceOf kantaina.Container

  describe "Container", ->
    describe "#set()", ->
      it "should save function as factory", ->
        container = kantaina()
        container.factories.should.not.have.property "key"
        container.set "key", ->
        container.factories.should.have.property "key"

      it "should save value as value", ->
        container = kantaina()
        container.values.should.not.have.property "key"
        container.set "key", "value"
        container.values.should.have.property "key"

      it "should replace first value if second value is factory", (callback) ->
        container = kantaina()

        container.set "key", ->
          "first"

        container.get("key").then (value) ->
          value.should.equal "first"
        .then ->
          container.set "key", ->
            "second"
        .then ->
          container.get "key"
        .then (value) ->
          value.should.equal "second"
        .should.notify callback

      it "should call factory if key has subscribers", (callback) ->
        container = kantaina()
        container.get("key").should.eventually.equal("value").notify callback
        setTimeout ->
          container.set "key", ->
            "value"
        , 50

      it "should inject specified dependencies", (callback) ->
        container = kantaina()
        container.set "a", 6
        container.set "b", 2
        container.set "c", ["a", "b"], (b, a) ->
          b/a
        container.get("c").should.eventually.equal(3).notify callback

      it "should reset grapth on next define", (callback) ->
        container = kantaina()
        container.set "a", 1
        container.set "b", 2
        container.set "c", (a) ->
          a
        container.set "c", (b) ->
          b
        container.get("c").should.eventually.equal(2).notify callback

    describe "#has()", ->
      it "should check values", ->
        container = kantaina()
        container.set "key", "value"
        container.has("key").should.be.true

      it "should check factories", ->
        container = kantaina()
        container.set "key", ->
          "value"
        container.has("key").should.be.true

    describe "#unless()", ->
      it "should set new value", (callback) ->
        container = kantaina()
        container.unless "key", "value"
        container.get("key").should.eventually.equal("value").notify callback

      it "should not replace old value", (callback) ->
        container = kantaina()
        container.unless "key", "first"
        container.unless "key", "second"
        container.get("key").should.eventually.equal("first").notify callback

      it "should inject specified dependencies", (callback) ->
        container = kantaina()
        container.unless "a", 6
        container.unless "b", 2
        container.unless "c", ["a", "b"], (b, a) ->
          b/a
        container.get("c").should.eventually.equal(3).notify callback

    describe "#get()", ->
      it "should return promise", ->
        w.isPromise(kantaina().get("key")).should.be.true

      it "should resolve value", (callback) ->
        container = kantaina()
        container.set "key", "value"
        container.get("key").should.eventually.equal("value").notify callback

      it "should resolve factory", (callback) ->
        container = kantaina()
        container.set "key", ->
          "value"
        container.get("key").should.eventually.equal("value").notify callback

      it "should resolve factory with promise", (callback) ->
        container = kantaina()
        container.set "key", ->
          deffered = w.defer()
          deffered.resolve "value"
          deffered.promise
        container.get("key").should.eventually.equal("value").notify callback

      it "should resolve many values", (callback) ->
        container = kantaina()
        container.set "a", 1
        container.set "b", 2
        container.get(["a", "b"]).should.eventually.eql([1, 2]).notify callback

      it "should run async factory only once", (callback) ->
        container = kantaina()
        calls = 0
        container.set "key", ->
          deffered = w.defer()
          calls += 1
          setTimeout ->
            deffered.resolve "value"
          , 100
          deffered.promise
        container.get("key")
        container.get("key").then (value) ->
          value.should.equal "value"
          calls.should.equal 1
        .should.notify callback

      it "should throw error if cyclic dependency found", (callback) ->
        try
          container = kantaina()
          container.set "a", (b) ->
            b
          container.set "b", (c) ->
            c
          container.set "c", (a) ->
            a
        catch err
          err.message.should.equal "Cyclic dependency from b to c"
          callback()

      it "should emit event after dependency factored", (callback) ->
        container = kantaina()
        listener = sinon.spy()
        container.set "key", ->
        container.on "key", listener
        container.get("key").then ->
          listener.should.be.calledOnce
        .should.notify callback

      it "should return promise if no value found", (callback) ->
        container = kantaina()
        container.get("key").should.eventually.equal("value").notify callback
        setTimeout ->
          container.set "key", "value"
        , 50

    describe "#inject()", ->
      it "should wrap function with promise and inject values", (callback) ->
        container = kantaina()
        container.set "a", 1
        container.set "b", 2
        container.inject (a, b) ->
          a + b
        .should.eventually.equal(3).notify callback

      it "should inject specified dependencies", (callback) ->
        container = kantaina()
        container.set "a", 6
        container.set "b", 2
        container.inject ["a", "b"], (b, a) ->
          b/a
        .should.eventually.equal(3).notify callback

      it "should inject array of factories", (callback) ->
        container = kantaina()
        container.inject([
          (container) -> container.set "c", (a, b) -> a + b
          (container) -> container.set "b", 2
          (container) -> container.set "a", 1
        ]).then ->
          container.get "c"
        .should.eventually.equal(3).notify callback

    describe "#clean()", ->
      it "should clean container", ->
        container = kantaina()
        container.set "a", 1
        container.set "b", ->
        container.values.should.have.property "a"
        container.factories.should.have.property "b"
        container.clean()
        container.values.should.not.have.property "a"
        container.factories.should.not.have.property "b"
