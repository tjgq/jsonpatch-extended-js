jsonpatch = require '../../jsonpatch'

module.exports =

    'copy operation':

        'should fail if no source specified':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'copy'
                path: '/bar/baz'
            result: jsonpatch.InvalidPatchError

        # Tests for target

        'should fail if target path has nonexisting component':
            document: {foo: 1}
            patch:
                op: 'copy'
                from: '/foo'
                path: '/bar/baz'
            result: jsonpatch.PatchConflictError

        'in lax mode, should do nothing if target path has nonexisting component':
            document: {foo: 1}
            patch:
                op: 'copy'
                from: '/foo'
                path: '/bar/baz'
            lax: true
            result: {foo: 1}

        'should fail if target path indexes a non-object':
            document: {foo: 1, bar: 2}
            patch:
                op: 'copy'
                from: '/foo'
                path: '/bar/baz'
            result: jsonpatch.PatchConflictError

        'in lax mode, should do nothing if target path indexes a non-object':
            document: {foo: 1, bar: 2}
            patch:
                op: 'copy'
                from: '/foo'
                path: '/bar/baz'
            lax: true
            result: {foo: 1, bar: 2}

        'should copy into root':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'copy'
                from: '/bar'
                path: ''
            result: {baz: 'spam'}

        'should copy into empty key at root':
            document: {foo: 1, bar: 'spam'}
            patch:
                op: 'copy'
                from: '/bar'
                path: '/'
            result: {foo: 1, '': 'spam', bar: 'spam'}

        'should copy into empty key not at root':
            document: {foo: 1, bar: {baz: 'spam'}, quux: 'eggs'}
            patch:
                op: 'copy'
                from: '/quux'
                path: '/bar/'
            result: {foo: 1, bar: {baz: 'spam', '': 'eggs'}, quux: 'eggs'}

        'should copy into empty array at explicit last position':
            document: {foo: 1, bar: [], baz: 'spam'}
            patch:
                op: 'copy'
                from: '/baz'
                path: '/bar/0'
            result: {foo: 1, bar: ['spam'], baz: 'spam'}

        'should copy into empty array at implicit last position':
            document: {foo: 1, bar: [], baz: 'spam'}
            patch:
                op: 'copy'
                from: '/baz'
                path: '/bar/-'
            result: {foo: 1, bar: ['spam'], baz: 'spam'}

        'should copy into array at existing position':
            document: {foo: 1, bar: ['spam', 'bacon'], quux: 'eggs'}
            patch:
                op: 'copy'
                from: '/quux'
                path: '/bar/1'
            result: {foo: 1, bar: ['spam', 'eggs', 'bacon'], quux: 'eggs'}

        'should copy into array at explicit last position':
            document: {foo: 1, bar: ['spam', 'eggs'], quux: 'bacon'}
            patch:
                op: 'copy'
                from: '/quux'
                path: '/bar/2'
            result: {foo: 1, bar: ['spam', 'eggs', 'bacon'], quux: 'bacon'}

        'should copy into array at implicit last position':
            document: {foo: 1, bar: ['spam', 'eggs'], quux: 'bacon'}
            patch:
                op: 'copy'
                from: '/quux'
                path: '/bar/-'
            result: {foo: 1, bar: ['spam', 'eggs', 'bacon'], quux: 'bacon'}

        'should fail if target array position out of bounds':
            document: {foo: 1, bar: ['spam', 'bacon'], quux: 'eggs'}
            patch:
                op: 'copy'
                from: '/quux'
                path: '/bar/3'
            result: jsonpatch.PatchConflictError

        'in lax mode, should copy into end of array if target position out of bounds':
            document: {foo: 1, bar: ['spam', 'bacon'], quux: 'eggs'}
            patch:
                op: 'copy'
                from: '/quux'
                path: '/bar/3'
            lax: true
            result: {foo: 1, bar: ['spam', 'bacon', 'eggs'], quux: 'eggs'}

        'should copy into nonexisting object key':
            document: {foo: 1, bar: {quux: 'eggs'}, xyzzy: 'spam'}
            patch:
                op: 'copy'
                from: '/xyzzy'
                path: '/bar/baz'
            result: {foo: 1, bar: {baz: 'spam', quux: 'eggs'}, xyzzy: 'spam'}

        'should copy into existing object key':
            document: {foo: 1, bar: {baz: 'spam', quux: 'eggs'}, xyzzy: 'bacon'}
            patch:
                op: 'copy'
                from: '/xyzzy'
                path: '/bar/baz'
            result: {foo: 1, bar: {baz: 'bacon', quux: 'eggs'}, xyzzy: 'bacon'}

        'should copy into object inside array':
            document: {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs'}], waldo: 'bacon'}
            patch:
                op: 'copy'
                from: '/waldo'
                path: '/bar/1/xyzzy'
            result: {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs', xyzzy: 'bacon'}], waldo: 'bacon'}

        # Tests for source

        'should fail if source path has nonexisting component':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'copy'
                from: '/xyzzy/waldo'
                path: '/bar/baz'
            result: jsonpatch.PatchConflictError

        'in lax mode, should do nothing if source path has nonexisting component':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'copy'
                from: '/xyzzy/waldo'
                path: '/bar/baz'
            lax: true
            result: {foo: 1, bar: {baz: 'spam'}}

        'should fail if source path indexes a non-object':
            document: {foo: 1, bar: {baz: 'spam'}, xyzzy: 2}
            patch:
                op: 'copy'
                from: '/xyzzy/waldo'
                path: '/bar/baz'
            result: jsonpatch.PatchConflictError

        'in lax mode, should do nothing if source path indexes a non-object':
            document: {foo: 1, bar: {baz: 'spam'}, xyzzy: 2}
            patch:
                op: 'copy'
                from: '/xyzzy/waldo'
                path: '/bar/baz'
            lax: true
            result: {foo: 1, bar: {baz: 'spam'}, xyzzy: 2}

        'should copy from empty key at root':
            document: {foo: 1, '': 'spam'}
            patch:
                op: 'copy'
                from: '/'
                path: '/waldo'
            result: {foo: 1, '': 'spam', waldo: 'spam'}

        'should copy from empty key not at root':
            document: {foo: 1, bar: {baz: 'spam', '': 'eggs'}}
            patch:
                op: 'copy'
                from: '/bar/'
                path: '/waldo'
            result: {foo: 1, bar: {baz: 'spam', '': 'eggs'}, waldo: 'eggs'}

        'should fail if source array position does not exist':
            document: {foo: 1, bar: ['spam', 'bacon']}
            patch:
                op: 'copy'
                from: '/bar/3'
                path: '/waldo'
            result: jsonpatch.PatchConflictError

        'in lax mode, should do nothing if source array position does not exist':
            document: {foo: 1, bar: ['spam', 'bacon']}
            patch:
                op: 'copy'
                from: '/bar/3'
                path: '/waldo'
            lax: true
            result: {foo: 1, bar: ['spam', 'bacon']}

        'should copy from array at existing position':
            document: {foo: 1, bar: ['spam', 'eggs']}
            patch:
                op: 'copy'
                from: '/bar/1'
                path: '/waldo'
            result: {foo: 1, bar: ['spam', 'eggs'], waldo: 'eggs'}

        'should fail if source object key does not exist':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'copy'
                from: '/bar/quux'
                path: '/waldo'
            result: jsonpatch.PatchConflictError

        'in lax mode, should do nothing if source object key does not exist':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'copy'
                from: '/bar/quux'
                path: '/waldo'
            lax: true
            result: {foo: 1, bar: {baz: 'spam'}}

        'should copy from existing object key':
            document: {foo: 1, bar: {baz: 'spam', quux: 'eggs'}}
            patch:
                op: 'copy'
                from: '/bar/baz'
                path: '/waldo'
            result: {foo: 1, bar: {baz: 'spam', quux: 'eggs'}, waldo: 'spam'}

        'should copy from object inside array':
            document: {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs'}]}
            patch:
                op: 'copy'
                from: '/bar/1/quux'
                path: '/waldo'
            result: {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs'}], waldo: 'eggs'}
