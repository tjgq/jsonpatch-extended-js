jsonpatch = require '../../jsonpatch'

module.exports =

    'test operation':

        # Failures

        'should fail if no value specified':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'test'
                path: '/bar/baz'
            result: jsonpatch.InvalidPatchError

        'should fail if target has nonexisting component':
            document: {foo: 1}
            patch:
                op: 'test'
                path: '/bar/baz'
                value: 'spam'
            result: jsonpatch.PatchConflictError

        'should fail if target path indexes a non-object':
            document: {foo: 1, bar: 2}
            patch:
                op: 'test'
                path: '/bar/baz'
                value: 'spam'
            result: jsonpatch.PatchConflictError

        'should fail if target is nonexisting array position':
            document: {foo: 1, bar: ['spam', 'eggs']}
            patch:
                op: 'test'
                path: '/bar/2'
                value: 'eggs'
            result: jsonpatch.PatchConflictError

        'should fail if target is position past end of array':
            document: {foo: 1, bar: ['spam', 'eggs']}
            patch:
                op: 'test'
                path: '/bar/-'
                value: 'eggs'
            result: jsonpatch.PatchConflictError

        'should fail if target object key does not exist':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'test'
                path: '/bar/quux'
                value: 'spam'
            result: jsonpatch.PatchConflictError

        # Positive tests

        'should pass test on root':
            document: {foo: 1, bar: ['spam']}
            patch:
                op: 'test'
                path: ''
                value: {foo: 1, bar: ['spam']}
            result: {foo: 1, bar: ['spam']}

        'should pass test on empty key at root':
            document: {foo: 1, '': {bar: 'spam', baz: 'eggs'}}
            patch:
                op: 'test'
                path: '/'
                value: {bar: 'spam', baz: 'eggs'}
            result: {foo: 1, '': {bar: 'spam', baz: 'eggs'}}

        'should pass test on empty key not at root':
            document: {foo: 1, bar: {baz: 'spam', '': {'eggs', 'bacon'}}}
            patch:
                op: 'test'
                path: '/bar/'
                value: {'eggs', 'bacon'}
            result: {foo: 1, bar: {baz: 'spam', '': {'eggs', 'bacon'}}}

        'should pass test on existing array position':
            document: {foo: 1, bar: ['spam', 'eggs', 'bacon']}
            patch:
                op: 'test'
                path: '/bar/1'
                value: 'eggs'
            result: {foo: 1, bar: ['spam', 'eggs', 'bacon']}

        'should pass test on existing object key':
            document: {foo: 1, bar: {baz: 'spam', quux: 'eggs'}}
            patch:
                op: 'test'
                path: '/bar/baz'
                value: 'spam'
            result: {foo: 1, bar: {baz: 'spam', quux: 'eggs'}}

        'should pass test on key in object inside array':
            document: {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs', xyzzy: 'bacon'}]}
            patch:
                op: 'test'
                path: '/bar/1/xyzzy'
                value: 'bacon'
            result: {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs', xyzzy: 'bacon'}]}

        # Negative tests

        'should fail test on root':
            document: {foo: 1, bar: ['spam']}
            patch:
                op: 'test'
                path: ''
                value: {foo: 1, bar: ['eggs']}
            result: jsonpatch.PatchConflictError

        'should fail test on empty key at root':
            document: {foo: 1, '': {bar: 'spam', baz: 'eggs'}}
            patch:
                op: 'test'
                path: '/'
                value: {bar: 'spam', baz: 'bacon'}
            result: jsonpatch.PatchConflictError

        'should fail test on empty key not at root':
            document: {foo: 1, bar: {baz: 'spam', '': {'eggs', 'bacon'}}}
            patch:
                op: 'test'
                path: '/bar/'
                value: {'eggs', 'tomato'}
            result: jsonpatch.PatchConflictError

        'should fail test on existing array position':
            document: {foo: 1, bar: ['spam', 'eggs', 'bacon']}
            patch:
                op: 'test'
                path: '/bar/1'
                value: 'tomato'
            result: jsonpatch.PatchConflictError

        'should fail test on existing object key':
            document: {foo: 1, bar: {baz: 'spam', quux: 'eggs'}}
            patch:
                op: 'test'
                path: '/bar/baz'
                value: 'bacon'
            result: jsonpatch.PatchConflictError

        'should fail test on key in object inside array':
            document: {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs', xyzzy: 'bacon'}]}
            patch:
                op: 'test'
                path: '/bar/1/xyzzy'
                value: 'tomato'
            result: jsonpatch.PatchConflictError
