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
        container.on "factored-key", listener
        container.get("key").then ->
          listener.should.be.calledOnce
        .should.notify callback

    describe "#inject()", ->
      it "should wrap function with promise and inject values", (callback) ->
        container = kantaina()
        container.set "a", 1
        container.set "b", 2
        wrapped = container.inject (a, b) ->
          a + b
        wrapped().should.eventually.equal(3).notify callback

    describe "#call()", ->
      it "should call wrapped function", (callback) ->
        container = kantaina()
        container.set "a", 1
        container.set "b", 2
        promise = container.call (a, b) ->
          a + b
        promise.should.eventually.equal(3).notify callback
