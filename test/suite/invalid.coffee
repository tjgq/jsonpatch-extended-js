jsonpatch = require '../../jsonpatch'

module.exports =

    'missing or invalid arguments:':

        'should fail if operation is missing':
            document: {}
            patch:
                path: '/foo/bar'
            result: jsonpatch.InvalidPatchError

        'should fail if operation is invalid':
            document: {}
            patch:
                op: 'error'
                path: '/foo/bar'
            result: jsonpatch.InvalidPatchError

        'should fail if path is missing':
            document: {}
            patch:
                op: 'test'
                value: 'spam'
            result: jsonpatch.InvalidPatchError

        'should fail if path is nonempty but does not start with /':
            document: {}
            patch:
                op: 'test'
                path: 'foo/bar'
                value: 'spam'
            result: jsonpatch.InvalidPointerError

        'should apply empty patch':
            document: {foo: 1, bar: ['spam', 'eggs', 'bacon']}
            patch: []
            result: {foo: 1, bar: ['spam', 'eggs', 'bacon']}
