jsonpatch = require '../../jsonpatch'

module.exports =

    'paths with lookahead':

        'should fail if lookahead clause is malformed':
            document: {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
            patch:
                op: 'test'
                path: '/*[baz]/quux'
                value: 'eggs'
            result: jsonpatch.InvalidPointerError

        # Lookahead in final component

        'should pass test on path with matching final lookahead on object key':
            document: {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
            patch:
                op: 'test'
                path: '/bar/yes[baz=spam]'
                value: {baz: 'spam', quux: 'eggs'}
            result: {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}

        'should fail test on path with non-matching final lookahead key on object key':
            document: {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
            patch:
                op: 'test'
                path: '/yes[quack=spam]'
                value: {baz: 'spam', quux: 'eggs'}
            result: jsonpatch.PatchConflictError

        'should fail test on path with non-matching final lookahead value on object key':
            document: {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
            patch:
                op: 'test'
                path: '/yes[baz=eggs]'
                value: {baz: 'spam', quux: 'eggs'}
            result: jsonpatch.PatchConflictError

        'should pass test on path with matching final lookahead on array position':
            document: {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}
            patch:
                op: 'test'
                path: '/bar/0[baz=spam]'
                value: {baz: 'spam', quux: 'eggs'}
            result: {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}

        'should fail test on path with non-matching final lookahead key on array position':
            document: {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}
            patch:
                op: 'test'
                path: '/bar/0[quack=spam]'
                value: {baz: 'spam', quux: 'eggs'}
            result: jsonpatch.PatchConflictError

        'should fail test on path with non-matching final lookahead value on array position':
            document: {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}
            patch:
                op: 'test'
                path: '/bar/0[spam=eggs]'
                value: {baz: 'spam', quux: 'eggs'}
            result: jsonpatch.PatchConflictError

        # Lookahead in non-final component

        'should pass test on path with matching non-final lookahead on object key':
            document: {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
            patch:
                op: 'test'
                path: '/bar/yes[baz=spam]/quux'
                value: 'eggs'
            result: {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}

        'should fail test on path with non-matching non-final lookahead key on object key':
            document: {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
            patch:
                op: 'test'
                path: '/yes[quack=spam]/quux'
                value: 'eggs'
            result: jsonpatch.PatchConflictError

        'should fail test on path with non-matching non-final lookahead value on object key':
            document: {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
            patch:
                op: 'test'
                path: '/yes[baz=eggs]/quux'
                value: 'eggs'
            result: jsonpatch.PatchConflictError

        'should pass test on path with matching non-final lookahead on array position':
            document: {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}
            patch:
                op: 'test'
                path: '/bar/0[baz=spam]/quux'
                value: 'eggs'
            result: {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}

        'should fail test on path with non-matching non-final lookahead key on array position':
            document: {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}
            patch:
                op: 'test'
                path: '/bar/0[quack=spam]/quux'
                value: 'eggs'
            result: jsonpatch.PatchConflictError

        'should fail test on path with non-matching non-final lookahead value on array position':
            document: {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}
            patch:
                op: 'test'
                path: '/bar/0[spam=eggs]/quux'
                value: 'eggs'
            result: jsonpatch.PatchConflictError

        # Lookahead in final component, combined with wildcard

        'should pass test on path with matching final lookahead on wildcard object key':
            document: {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
            patch:
                op: 'test'
                path: '/bar/*[baz=spam]'
                value: {baz: 'spam', quux: 'eggs'}
            result: {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}

        'should fail test on path with non-matching final lookahead key on wildcard object key':
            document: {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
            patch:
                op: 'test'
                path: '/*[quack=spam]'
                value: {baz: 'spam', quux: 'eggs'}
            result: jsonpatch.PatchConflictError

        'should fail test on path with non-matching final lookahead value on wildcard object key':
            document: {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
            patch:
                op: 'test'
                path: '/*[baz=eggs]'
                value: {baz: 'spam', quux: 'eggs'}
            result: jsonpatch.PatchConflictError

        'should pass test on path with matching final lookahead on wildcard array position':
            document: {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}
            patch:
                op: 'test'
                path: '/bar/*[baz=spam]'
                value: {baz: 'spam', quux: 'eggs'}
            result: {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}

        'should fail test on path with non-matching final lookahead key on wildcard array position':
            document: {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}
            patch:
                op: 'test'
                path: '/bar/*[quack=spam]'
                value: {baz: 'spam', quux: 'eggs'}
            result: jsonpatch.PatchConflictError

        'should fail test on path with non-matching final lookahead value on wildcard array position':
            document: {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}
            patch:
                op: 'test'
                path: '/bar/*[spam=eggs]'
                value: {baz: 'spam', quux: 'eggs'}
            result: jsonpatch.PatchConflictError

        # Lookahead in non-final component, combined with wildcard

        'should pass test on path with matching non-final lookahead on wildcard object key':
            document: {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
            patch:
                op: 'test'
                path: '/bar/*[baz=spam]/quux'
                value: 'eggs'
            result: {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}

        'should fail test on path with non-matching non-final lookahead key on wildcard object key':
            document: {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
            patch:
                op: 'test'
                path: '/*[quack=spam]/quux'
                value: 'eggs'
            result: jsonpatch.PatchConflictError

        'should fail test on path with non-matching non-final lookahead value on wildcard object key':
            document: {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
            patch:
                op: 'test'
                path: '/*[baz=eggs]/quux'
                value: 'eggs'
            result: jsonpatch.PatchConflictError

        'should pass test on path with matching non-final lookahead on wildcard array position':
            document: {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}
            patch:
                op: 'test'
                path: '/bar/*[baz=spam]/quux'
                value: 'eggs'
            result: {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}

        'should fail test on path with non-matching non-final lookahead key on wildcard array position':
            document: {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}
            patch:
                op: 'test'
                path: '/bar/*[quack=spam]/quux'
                value: 'eggs'
            result: jsonpatch.PatchConflictError

        'should fail test on path with non-matching non-final lookahead value on wildcard array position':
            document: {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}
            patch:
                op: 'test'
                path: '/bar/*[spam=eggs]/quux'
                value: 'eggs'
            result: jsonpatch.PatchConflictError
