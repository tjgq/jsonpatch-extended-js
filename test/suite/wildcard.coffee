jsonpatch = require '../../jsonpatch'

module.exports =

    'paths with wildcard':

        'should pass test if last path component is wildcard':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'test'
                path: '/bar/*'
                value: 'spam'
            result: {foo: 1, bar: {baz: 'spam'}}

        'should fail test if wildcard component indexes a non-object':
            document: {foo: 1, bar: 2}
            patch:
                op: 'test'
                path: '/bar/*/quux'
                value: 'spam'
            result: jsonpatch.PatchConflictError

        'should pass test on path with matching wildcard on object key':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'test'
                path: '/*/baz'
                value: 'spam'
            result: {foo: 1, bar: {baz: 'spam'}}

        'should fail test on path with non-matching wildcard on object key':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'test'
                path: '/*/quux'
                value: 'spam'
            result: jsonpatch.PatchConflictError

        'should pass test on path with matching wildcard on array position':
            document: {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}]}
            patch:
                op: 'test'
                path: '/bar/*/baz'
                value: 'spam'
            result: {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}]}

        'should fail test on path with non-matching wildcard on array position':
            document: {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}]}
            patch:
                op: 'test'
                path: '/bar/*/waldo'
                value: 'spam'
            result: jsonpatch.PatchConflictError
