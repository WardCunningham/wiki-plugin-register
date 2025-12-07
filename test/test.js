// build time tests for register plugin

import { register } from '../src/client/register.js'
import { suite, test } from 'node:test'
import assert from 'node:assert'

suite('register plugin', () => {
  suite('expand', () => {
    test('can escape tags', () => {
      const result = register.expand('hi < hello')
      assert.equal(result, 'hi &lt; hello')
    })
  })
})
