_ = require 'lodash'
fs = require 'fs'
path = require 'path'
jsonpatch = require '../jsonpatch'
expect = require('chai').expect


testDir = path.join(__dirname, 'suite')
testSuite = _(fs.readdirSync(testDir)).map((f) -> require("./suite/#{f}")).reduce(_.merge)


runTest = (test) ->

    patch = if _.isArray(test.patch) then test.patch else [test.patch]
    fn = -> jsonpatch.apply(test.document, patch, test.lax || false)

    if test.result.prototype instanceof Error
        expect(fn).to.throw(test.result)
    else
        expect(fn()).to.deep.equal(test.result)


_(testSuite).each (feature, featureName) ->
    $describe = if feature.only? then describe.only else describe
    $describe featureName, ->
        _(feature).each (test, testName) ->
            $it = if test.only? then it.only else it
            $it testName, ->
                runTest(test)
