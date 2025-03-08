# build time tests for register plugin
# see http://mochajs.org/

register = require '../client/register'
expect = require 'expect.js'

describe 'register plugin', ->

  describe 'expand', ->

    it 'can escape tags', ->
      result = register.expand 'hi < hello'
      expect(result).to.be 'hi &lt; hello'
