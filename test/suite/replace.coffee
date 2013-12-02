jsonpatch = require '../../jsonpatch'

module.exports =

    'replace operation':

        'should fail if no value specified':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'replace'
                path: '/bar/baz'
            result: jsonpatch.InvalidPatchError

        'should fail if target path has nonexisting component':
            document: {foo: 1}
            patch:
                op: 'replace'
                path: '/bar/baz'
                value: 'spam'
            result: jsonpatch.PatchConflictError

        'in lax mode, should do nothing if target path has nonexisting component':
            document: {foo: 1}
            patch:
                op: 'replace'
                path: '/bar/baz'
                value: 'spam'
            lax: true
            result: {foo: 1}

        'should fail if target path indexes a non-object':
            document: {foo: 1}
            patch:
                op: 'replace'
                path: '/foo/bar'
                value: 'spam'
            result: jsonpatch.PatchConflictError

        'in lax mode, should do nothing if target path indexes a non-object':
            document: {foo: 1}
            patch:
                op: 'replace'
                path: '/foo/bar'
                value: 'spam'
            lax: true
            result: {foo: 1}

        'should replace root':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'replace'
                path: ''
                value: {spam: 1, eggs: 'bacon'}
            result: {spam: 1, eggs: 'bacon'}

        'should replace empty key at root':
            document: {foo: 1, '': 'spam'}
            patch:
                op: 'replace'
                path: '/'
                value: 'eggs'
            result: {foo: 1, '': 'eggs'}

        'should replace empty key not at root':
            document: {foo: 1, bar: {baz: 'spam', '': 'eggs'}}
            patch:
                op: 'replace'
                path: '/bar/'
                value: 'bacon'
            result: {foo: 1, bar: {baz: 'spam', '': 'bacon'}}

        'should replace existing array position':
            document: {foo: 1, bar: ['spam', 'eggs']}
            patch:
                op: 'replace'
                path: '/bar/1'
                value: 'bacon'
            result: {foo: 1, bar: ['spam', 'bacon']}

        'should fail if target is nonexisting array position':
            document: {foo: 1, bar: ['spam', 'eggs']}
            patch:
                op: 'replace'
                path: '/bar/2'
                value: 'bacon'
            result: jsonpatch.PatchConflictError

        'in lax mode, should insert at end of array if target is nonexisting array position':
            document: {foo: 1, bar: ['spam', 'eggs']}
            patch:
                op: 'replace'
                path: '/bar/2'
                value: 'bacon'
            lax: true
            result: {foo: 1, bar: ['spam', 'eggs', 'bacon']}

        'should fail if target is position past end of array':
            document: {foo: 1, bar: ['spam', 'eggs']}
            patch:
                op: 'replace'
                path: '/bar/-'
                value: 'bacon'
            result: jsonpatch.PatchConflictError

        'in lax mode, should insert at end of array if target is position past end of array':
            document: {foo: 1, bar: ['spam', 'eggs']}
            patch:
                op: 'replace'
                path: '/bar/-'
                value: 'bacon'
            lax: true
            result: {foo: 1, bar: ['spam', 'eggs', 'bacon']}

        'should fail if target array position is not a number':
            document: {foo: 1, bar: ['spam', 'eggs']}
            patch:
                op: 'replace'
                path: '/bar/baz'
                value: 'bacon'
            result: jsonpatch.PatchConflictError

        'in lax mode, should do nothing if target array position is not a number':
            document: {foo: 1, bar: ['spam', 'eggs']}
            patch:
                op: 'replace'
                path: '/bar/baz'
                value: 'bacon'
            lax: true
            result: {foo: 1, bar: ['spam', 'eggs']}

        'should replace existing object key':
            document: {foo: 1, bar: {baz: 'spam', quux: 'eggs'}}
            patch:
                op: 'replace'
                path: '/bar/baz'
                value: 'bacon'
            result: {foo: 1, bar: {baz: 'bacon', quux: 'eggs'}}

        'should fail if target object key does not exist':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'replace'
                path: '/bar/quux'
                value: 'eggs'
            result: jsonpatch.PatchConflictError

        'in lax mode, should insert into object if target object key does not exist':
            document: {foo: 1, bar: {baz: 'spam'}}
            patch:
                op: 'replace'
                path: '/bar/quux'
                value: 'eggs'
            lax: true
            result: {foo: 1, bar: {baz: 'spam', quux: 'eggs'}}

        'should replace key in object inside array':
            document: {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs', xyzzy: 'bacon'}]}
            patch:
                op: 'replace'
                path: '/bar/1/xyzzy'
                value: 'tomato'
            result: {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs', xyzzy: 'tomato'}]}
