jsonpatch = require '../../jsonpatch'

module.exports =

    'remove operation':

        'should fail if target is root':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'remove'
                path: ''
            result: jsonpatch.InvalidPatchError

        'should fail if target path has nonexisting component':
            document: {foo: 1}
            patch:
                op: 'remove'
                path: '/bar/baz'
            result: jsonpatch.PatchConflictError

        'should fail if target path indexes a non-object':
            document: {foo: 1}
            patch:
                op: 'remove'
                path: '/foo/bar'
                value: 'spam'
            result: jsonpatch.PatchConflictError

        'should remove empty key at root':
            document: {foo: 1, '': 'spam'}
            patch:
                op: 'remove'
                path: '/'
            result: {foo: 1}

        'should remove empty key not at root':
            document: {foo: 1, bar: {baz: 'spam', '': 'eggs'}}
            patch:
                op: 'remove'
                path: '/bar/'
            result: {foo: 1, bar: {baz: 'spam'}}

        'should remove existing array position':
            document: {foo: 1, bar: ['spam', 'eggs', 'bacon']}
            patch:
                op: 'remove'
                path: '/bar/1'
            result: {foo: 1, bar: ['spam', 'bacon']}

        'should fail if target is nonexisting array position':
            document: {foo: 1, bar: ['spam', 'eggs', 'bacon']}
            patch:
                op: 'remove'
                path: '/bar/3'
            result: jsonpatch.PatchConflictError

        'should fail if target is position past end of array':
            document: {foo: 1, bar: ['spam', 'eggs', 'bacon']}
            patch:
                op: 'remove'
                path: '/bar/-'
            result: jsonpatch.PatchConflictError

        'should remove existing object key':
            document: {foo: 1, bar: {baz: 'spam', quux: 'eggs'}}
            patch:
                op: 'remove'
                path: '/bar/baz'
            result: {foo: 1, bar: {quux: 'eggs'}}

        'should fail if target object key does not exist':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'remove'
                path: '/bar/quux'
            result: jsonpatch.PatchConflictError

        'should remove key from object inside array':
            document: {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs', xyzzy: 'bacon'}]}
            patch:
                op: 'remove'
                path: '/bar/1/xyzzy'
            result: {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs'}]}
