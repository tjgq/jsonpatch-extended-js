jsonpatch = require '../../jsonpatch'

module.exports =

    'add operation:':

        'should fail if no value specified':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'add'
                path: '/bar/quux'
            result: jsonpatch.InvalidPatchError

        'should fail if target path has nonexisting component':
            document: {foo: 1}
            patch:
                op: 'add'
                path: '/bar/baz'
                value: 'spam'
            result: jsonpatch.PatchConflictError

        'should fail if target path indexes a non-object':
            document: {foo: 1}
            patch:
                op: 'add'
                path: '/foo/bar'
                value: 'spam'
            result: jsonpatch.PatchConflictError

        'should add at root':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'add'
                path: ''
                value: {spam: 1, eggs: 'bacon'}
            result: {spam: 1, eggs: 'bacon'}

        'should add into empty key at root':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'add'
                path: '/'
                value: 'spam'
            result: {foo: 1, bar: {baz: 'spam'}, '': 'spam'}

        'should add into empty key not at root':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'add'
                path: '/bar/'
                value: 'eggs'
            result: {foo: 1, bar: {baz: 'spam', '': 'eggs'}}

        'should add into empty array at explicit last position':
            document: {foo: 1, bar: []}
            patch:
                op: 'add'
                path: '/bar/0'
                value: 'spam'
            result: {foo: 1, bar: ['spam']}

        'should add into empty array at implicit last position':
            document: {foo: 1, bar: []}
            patch:
                op: 'add'
                path: '/bar/-'
                value: 'spam'
            result: {foo: 1, bar: ['spam']}

        'should add into array at existing position':
            document: {foo: 1, bar: ['spam', 'bacon']}
            patch:
                op: 'add'
                path: '/bar/1'
                value: 'eggs'
            result: {foo: 1, bar: ['spam', 'eggs', 'bacon']}

        'should add into array at explicit last position':
            document: {foo: 1, bar: ['spam', 'eggs']}
            patch:
                op: 'add'
                path: '/bar/2'
                value: 'bacon'
            result: {foo: 1, bar: ['spam', 'eggs', 'bacon']}

        'should add into array at implicit last position':
            document: {foo: 1, bar: ['spam', 'eggs']}
            patch:
                op: 'add'
                path: '/bar/-'
                value: 'bacon'
            result: {foo: 1, bar: ['spam', 'eggs', 'bacon']}

        'should fail if array position out of bounds':
            document: {foo: 1, bar: ['spam', 'eggs']}
            patch:
                op: 'add'
                path: '/bar/3'
                value: 'bacon'
            result: jsonpatch.PatchConflictError

        'should fail if array position is not a number':
            document: {foo: 1, bar: ['spam', 'eggs']}
            patch:
                op: 'add'
                path: '/bar/baz'
                value: 'bacon'
            result: jsonpatch.PatchConflictError

        'should add into nonexisting object key':
            document: {foo: 1, bar: {quux: 'eggs'}}
            patch:
                op: 'add'
                path: '/bar/baz'
                value: 'spam'
            result: {foo: 1, bar: {baz: 'spam', quux: 'eggs'}}

        'should add into existing object key':
            document: {foo: 1, bar: {baz: 'spam', quux: 'eggs'}}
            patch:
                op: 'add'
                path: '/bar/baz'
                value: 'bacon'
            result: {foo: 1, bar: {baz: 'bacon', quux: 'eggs'}}

        'should add into object inside array':
            document: {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs'}]}
            patch:
                op: 'add'
                path: '/bar/1/xyzzy'
                value: 'bacon'
            result: {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs', xyzzy: 'bacon'}]}
