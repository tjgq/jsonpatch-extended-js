jsonpatch = require '../../jsonpatch'

module.exports =

    'move operation':

        'should fail if no source specified':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'move'
                path: '/bar/baz'
            result: jsonpatch.InvalidPatchError

        # Tests for source = target

        'should move root into itself':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'move'
                from: ''
                path: ''
            result: {foo: 1, bar: {baz: 'spam'}}

        'should move non-root into itself':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'move'
                from: '/bar'
                path: '/bar'
            result: {foo: 1, bar: {baz: 'spam'}}

        # Tests for target

        'should fail if target path has nonexisting component':
            document: {foo: 1}
            patch:
                op: 'move'
                from: '/foo'
                path: '/bar/baz'
            result: jsonpatch.PatchConflictError

        'should fail if target path indexes a non-object':
            document: {foo: 1, bar: 2}
            patch:
                op: 'move'
                from: '/foo'
                path: '/bar/baz'
            result: jsonpatch.PatchConflictError

        'should move into root':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'move'
                from: '/bar'
                path: ''
            result: {baz: 'spam'}

        'should move into empty key at root':
            document: {foo: 1, bar: 'eggs'}
            patch:
                op: 'move'
                from: '/bar'
                path: '/'
            result: {foo: 1, '': 'eggs'}

        'should move into empty key not at root':
            document: {foo: 1, bar: {baz: 'spam'}, quux: 'eggs'}
            patch:
                op: 'move'
                from: '/quux'
                path: '/bar/'
            result: {foo: 1, bar: {baz: 'spam', '': 'eggs'}}

        'should move into empty array at explicit last position':
            document: {foo: 1, bar: [], baz: 'spam'}
            patch:
                op: 'move'
                from: '/baz'
                path: '/bar/0'
            result: {foo: 1, bar: ['spam']}

        'should move into empty array at implicit last position':
            document: {foo: 1, bar: [], baz: 'spam'}
            patch:
                op: 'move'
                from: '/baz'
                path: '/bar/-'
            result: {foo: 1, bar: ['spam']}

        'should move into array at existing position':
            document: {foo: 1, bar: ['spam', 'bacon'], quux: 'eggs'}
            patch:
                op: 'move'
                from: '/quux'
                path: '/bar/1'
            result: {foo: 1, bar: ['spam', 'eggs', 'bacon']}

        'should move into array at explicit last position':
            document: {foo: 1, bar: ['spam', 'eggs'], quux: 'bacon'}
            patch:
                op: 'move'
                from: '/quux'
                path: '/bar/2'
            result: {foo: 1, bar: ['spam', 'eggs', 'bacon']}

        'should move into array at implicit last position':
            document: {foo: 1, bar: ['spam', 'eggs'], quux: 'bacon'}
            patch:
                op: 'move'
                from: '/quux'
                path: '/bar/-'
            result: {foo: 1, bar: ['spam', 'eggs', 'bacon']}

        'should fail if target array position out of bounds':
            document: {foo: 1, bar: ['spam', 'bacon'], quux: 'eggs'}
            patch:
                op: 'move'
                from: '/quux'
                path: '/bar/3'
            result: jsonpatch.PatchConflictError

        'should move into nonexisting object key':
            document: {foo: 1, bar: {quux: 'eggs'}, xyzzy: 'spam'}
            patch:
                op: 'move'
                from: '/xyzzy'
                path: '/bar/baz'
            result: {foo: 1, bar: {baz: 'spam', quux: 'eggs'}}

        'should move into existing object key':
            document: {foo: 1, bar: {baz: 'spam', quux: 'eggs'}, xyzzy: 'bacon'}
            patch:
                op: 'move'
                from: '/xyzzy'
                path: '/bar/baz'
            result: {foo: 1, bar: {baz: 'bacon', quux: 'eggs'}}

        'should move into object inside array':
            document: {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs'}], waldo: 'bacon'}
            patch:
                op: 'move'
                from: '/waldo'
                path: '/bar/1/xyzzy'
            result: {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs', xyzzy: 'bacon'}]}

            # Tests for source

        'should fail if source path has nonexisting component':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'move'
                from: '/xyzzy/waldo'
                path: '/bar/baz'
            result: jsonpatch.PatchConflictError

        'should fail if source path indexes a non-object':
            document: {foo: 1, bar: {baz: 'spam'}, xyzzy: 2}
            patch:
                op: 'move'
                from: '/xyzzy/waldo'
                path: '/bar/baz'
            result: jsonpatch.PatchConflictError

        'should fail if moving from root':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'move'
                from: ''
                path: '/waldo'
            result: jsonpatch.InvalidPatchError

        'should move from empty key at root':
            document: {foo: 1, '': 'spam'}
            patch:
                op: 'move'
                from: '/'
                path: '/waldo'
            result: {foo: 1, waldo: 'spam'}

        'should move from empty key not at root':
            document: {foo: 1, bar: {baz: 'spam', '': 'eggs'}}
            patch:
                op: 'move'
                from: '/bar/'
                path: '/waldo'
            result: {foo: 1, bar: {baz: 'spam'}, waldo: 'eggs'}

        'should fail if source array position does not exist':
            document: {foo: 1, bar: ['spam', 'bacon']}
            patch:
                op: 'move'
                from: '/bar/3'
                path: '/waldo'
            result: jsonpatch.PatchConflictError

        'should move from array at existing position':
            document: {foo: 1, bar: ['spam', 'eggs']}
            patch:
                op: 'move'
                from: '/bar/1'
                path: '/waldo'
            result: {foo: 1, bar: ['spam'], waldo: 'eggs'}

        'should fail if source object key does not exist':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'move'
                from: '/bar/quux'
                path: '/waldo'
            result: jsonpatch.PatchConflictError

        'should move from existing object key':
            document: {foo: 1, bar: {baz: 'spam', quux: 'eggs'}}
            patch:
                op: 'move'
                from: '/bar/baz'
                path: '/waldo'
            result: {foo: 1, bar: {quux: 'eggs'}, waldo: 'spam'}

        'should move from object inside array':
            document: {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs'}]}
            patch:
                op: 'move'
                from: '/bar/1/quux'
                path: '/waldo'
            result: {foo: 1, bar: [{baz: 'spam'}, {}], waldo: 'eggs'}
