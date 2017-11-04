# build time tests for register plugin
# see http://mochajs.org/

register = require '../client/register'
expect = require 'expect.js'

describe 'register plugin', ->

  describe 'expand', ->

    it 'can make itallic', ->
      result = register.expand 'hello *world*'
      expect(result).to.be 'hello <i>world</i>'
