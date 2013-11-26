jsonpatch = require '../jsonpatch'
expect = require('chai').expect


describe 'generic', ->

    it 'should fail if operation is missing', ->
        expect( -> jsonpatch.apply({}, [{path: '/foo/bar'}]) )
            .to.throw(jsonpatch.InvalidPatchError, 'Missing operation')

    it 'should fail if operation is invalid', ->
        expect( -> jsonpatch.apply({}, [{op: 'error', path: '/foo/bar'}]) )
            .to.throw(jsonpatch.InvalidPatchError, 'Invalid operation')

    it 'should fail if path is missing', ->
        expect( -> jsonpatch.apply({}, [{op: 'test', value: 'spam'}]) )
            .to.throw(jsonpatch.InvalidPatchError, 'Missing path')

    it 'should fail if path is nonempty but does not start with /', ->
        expect( -> jsonpatch.apply({}, [{op: 'test', path: 'foo/bar', value: 'spam'}]) )
            .to.throw(jsonpatch.InvalidPointerError)

    it 'should apply empty patch', ->
        obj = {foo: 1, bar: ['spam', 'eggs', 'bacon']}
        expect( jsonpatch.apply(obj, []) )
            .to.deep.equal( {foo: 1, bar: ['spam', 'eggs', 'bacon']} )


describe 'add', ->

    it 'should fail if no value specified', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect( -> jsonpatch.apply(obj, [{op: 'add', path: '/bar/quux'}]) )
            .to.throw(jsonpatch.InvalidPatchError)

    it 'should fail if target path has nonexisting component', ->
        obj = {foo: 1}
        expect( -> jsonpatch.apply(obj, [{op: 'add', path: '/bar/baz', value: 'spam'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail if target path indexes a non-object', ->
        obj = {foo: 1}
        expect( -> jsonpatch.apply(obj, [{op: 'add', path: '/foo/bar', value: 'spam'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should add at root', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect( jsonpatch.apply(obj, [{op: 'add', path: '', value: {spam: 1, eggs: 'bacon'}}]) )
            .to.deep.equal( {spam: 1, eggs: 'bacon'} )

    it 'should add into empty key at root', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect( jsonpatch.apply(obj, [{op: 'add', path: '/', value: 'spam'}]) )
            .to.deep.equal( {foo: 1, bar: {baz: 'spam'}, '': 'spam'} )

    it 'should add into empty key not at root', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect( jsonpatch.apply(obj, [{op: 'add', path: '/bar/', value: 'eggs'}]) )
            .to.deep.equal( {foo: 1, bar: {baz: 'spam', '': 'eggs'}} )

    it 'should add into empty array at explicit last position', ->
        obj = {foo: 1, bar: []}
        expect( jsonpatch.apply(obj, [{op: 'add', path: '/bar/0', value: 'spam'}]) )
            .to.deep.equal( {foo: 1, bar: ['spam']} )

    it 'should add into empty array at implicit last position', ->
        obj = {foo: 1, bar: []}
        expect( jsonpatch.apply(obj, [{op: 'add', path: '/bar/-', value: 'spam'}]) )
            .to.deep.equal( {foo: 1, bar: ['spam']} )

    it 'should add into array at existing position', ->
        obj = {foo: 1, bar: ['spam', 'bacon']}
        expect( jsonpatch.apply(obj, [{op: 'add', path: '/bar/1', value: 'eggs'}]) )
            .to.deep.equal( {foo: 1, bar: ['spam', 'eggs', 'bacon']} )

    it 'should add into array at explicit last position', ->
        obj = {foo: 1, bar: ['spam', 'eggs']}
        expect( jsonpatch.apply(obj, [{op: 'add', path: '/bar/2', value: 'bacon'}]) )
            .to.deep.equal( {foo: 1, bar: ['spam', 'eggs', 'bacon']} )

    it 'should add into array at implicit last position', ->
        obj = {foo: 1, bar: ['spam', 'eggs']}
        expect( jsonpatch.apply(obj, [{op: 'add', path: '/bar/-', value: 'bacon'}]) )
            .to.deep.equal( {foo: 1, bar: ['spam', 'eggs', 'bacon']} )

    it 'should fail if array position out of bounds', ->
        obj = {foo: 1, bar: ['spam', 'eggs']}
        expect( -> jsonpatch.apply(obj, [{op: 'add', path: '/bar/3', value: 'bacon'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail if array position is not a number', ->
        obj = {foo: 1, bar: ['spam', 'eggs']}
        expect( -> jsonpatch.apply(obj, [{op: 'add', path: '/bar/baz', value: 'bacon'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should add into nonexisting object key', ->
        obj = {foo: 1, bar: {quux: 'eggs'}}
        expect( jsonpatch.apply(obj, [{op: 'add', path: '/bar/baz', value: 'spam'}]) )
            .to.deep.equal( {foo: 1, bar: {baz: 'spam', quux: 'eggs'}} )

    it 'should add into existing object key', ->
        obj = {foo: 1, bar: {baz: 'spam', quux: 'eggs'}}
        expect( jsonpatch.apply(obj, [{op: 'add', path: '/bar/baz', value: 'bacon'}]) )
            .to.deep.equal( {foo: 1, bar: {baz: 'bacon', quux: 'eggs'}} )

    it 'should add into object inside array', ->
        obj = {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs'}]}
        expect( jsonpatch.apply(obj, [{op: 'add', path: '/bar/1/xyzzy', value: 'bacon'}]) )
            .to.deep.equal( {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs', xyzzy: 'bacon'}]} )


describe 'remove', ->

    it 'should fail if target is root', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect( -> jsonpatch.apply(obj, [{op: 'remove', path: ''}]) )
            .to.throw(jsonpatch.InvalidPatchError)

    it 'should fail if target path has nonexisting component', ->
        obj = {foo: 1}
        expect( -> jsonpatch.apply(obj, [{op: 'remove', path: '/bar/baz'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail if target path indexes a non-object', ->
        obj = {foo: 1}
        expect( -> jsonpatch.apply(obj, [{op: 'remove', path: '/foo/bar', value: 'spam'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should remove empty key at root', ->
        obj = {foo: 1, '': 'spam'}
        expect( jsonpatch.apply(obj, [{op: 'remove', path: '/'}]) )
            .to.deep.equal( {foo: 1} )

    it 'should remove empty key not at root', ->
        obj = {foo: 1, bar: {baz: 'spam', '': 'eggs'}}
        expect( jsonpatch.apply(obj, [{op: 'remove', path: '/bar/'}]) )
            .to.deep.equal( {foo: 1, bar: {baz: 'spam'}} )

    it 'should remove existing array position', ->
        obj = {foo: 1, bar: ['spam', 'eggs', 'bacon']}
        expect( jsonpatch.apply(obj, [{op: 'remove', path: '/bar/1'}]) )
            .to.deep.equal( {foo: 1, bar: ['spam', 'bacon']} )

    it 'should fail if target is nonexisting array position', ->
        obj = {foo: 1, bar: ['spam', 'eggs', 'bacon']}
        expect( -> jsonpatch.apply(obj, [{op: 'remove', path: '/bar/3'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail if target is position past end of array', ->
        obj = {foo: 1, bar: ['spam', 'eggs', 'bacon']}
        expect( -> jsonpatch.apply(obj, [{op: 'remove', path: '/bar/-'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should remove existing object key', ->
        obj = {foo: 1, bar: {baz: 'spam', quux: 'eggs'}}
        expect( jsonpatch.apply(obj, [{op: 'remove', path: '/bar/baz'}]) )
            .to.deep.equal( {foo: 1, bar: {quux: 'eggs'}} )

    it 'should fail if target object key does not exist', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect( -> jsonpatch.apply(obj, [{op: 'remove', path: '/bar/quux'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should remove key from object inside array', ->
        obj = {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs', xyzzy: 'bacon'}]}
        expect( jsonpatch.apply(obj, [{op: 'remove', path: '/bar/1/xyzzy'}]) )
            .to.deep.equal( {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs'}]} )


describe 'replace', ->

    it 'should fail if no value specified', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect( -> jsonpatch.apply(obj, [{op: 'replace', path: '/bar/baz'}]) )
            .to.throw(jsonpatch.InvalidPatchError)

    it 'should fail if target path has nonexisting component', ->
        obj = {foo: 1}
        expect( -> jsonpatch.apply(obj, [{op: 'replace', path: '/bar/baz', value: 'spam'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail if target path indexes a non-object', ->
        obj = {foo: 1}
        expect( -> jsonpatch.apply(obj, [{op: 'replace', path: '/foo/bar', value: 'spam'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should replace root', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect( jsonpatch.apply(obj, [{op: 'replace', path: '', value: {spam: 1, eggs: 'bacon'}}]) )
            .to.deep.equal( {spam: 1, eggs: 'bacon'} )

    it 'should replace empty key at root', ->
        obj = {foo: 1, '': 'spam'}
        expect( jsonpatch.apply(obj, [{op: 'replace', path: '/', value: 'eggs'}]) )
            .to.deep.equal( {foo: 1, '': 'eggs'} )

    it 'should replace empty key not at root', ->
        obj = {foo: 1, bar: {baz: 'spam', '': 'eggs'}}
        expect( jsonpatch.apply(obj, [{op: 'replace', path: '/bar/', value: 'bacon'}]) )
            .to.deep.equal( {foo: 1, bar: {baz: 'spam', '': 'bacon'}} )

    it 'should replace existing array position', ->
        obj = {foo: 1, bar: ['spam', 'eggs']}
        expect( jsonpatch.apply(obj, [{op: 'replace', path: '/bar/1', value: 'bacon'}]) )
            .to.deep.equal( {foo: 1, bar: ['spam', 'bacon']} )

    it 'should fail if target is nonexisting array position', ->
        obj = {foo: 1, bar: ['spam', 'eggs']}
        expect( -> jsonpatch.apply(obj, [{op: 'replace', path: '/bar/2', value: 'bacon'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail if target is position past end of array', ->
        obj = {foo: 1, bar: ['spam', 'eggs']}
        expect( -> jsonpatch.apply(obj, [{op: 'replace', path: '/bar/-', value: 'bacon'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail if target array position is not a number', ->
        obj = {foo: 1, bar: ['spam', 'eggs']}
        expect( -> jsonpatch.apply(obj, [{op: 'replace', path: '/bar/baz', value: 'bacon'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should replace existing object key', ->
        obj = {foo: 1, bar: {baz: 'spam', quux: 'eggs'}}
        expect( jsonpatch.apply(obj, [{op: 'replace', path: '/bar/baz', value: 'bacon'}]) )
            .to.deep.equal( {foo: 1, bar: {baz: 'bacon', quux: 'eggs'}} )

    it 'should fail if target object key does not exist', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect( -> jsonpatch.apply(obj, [{op: 'replace', path: '/bar/quux', value: 'eggs'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should replace key in object inside array', ->
        obj = {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs', xyzzy: 'bacon'}]}
        expect( jsonpatch.apply(obj, [{op: 'replace', path: '/bar/1/xyzzy', value: 'tomato'}]) )
            .to.deep.equal( {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs', xyzzy: 'tomato'}]} )


describe 'move', ->

    it 'should fail if no source specified', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect( -> jsonpatch.apply(obj, [{op: 'move', path: '/bar/baz'}]) )
            .to.throw(jsonpatch.InvalidPatchError)

    # Tests for source = target

    it 'should move root into itself', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect(jsonpatch.apply(obj, [{op: 'move', from: '', path: ''}]))
            .to.deep.equal( {foo: 1, bar: {baz: 'spam'}} )

    it 'should move non-root into itself', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect(jsonpatch.apply(obj, [{op: 'move', from: '/bar', path: '/bar'}]))
            .to.deep.equal( {foo: 1, bar: {baz: 'spam'}} )

    # Tests for target

    it 'should fail if target path has nonexisting component', ->
        obj = {foo: 1}
        expect( -> jsonpatch.apply(obj, [{op: 'move', from: '/foo', path: '/bar/baz'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail if target path indexes a non-object', ->
        obj = {foo: 1, bar: 2}
        expect( -> jsonpatch.apply(obj, [{op: 'move', from: '/foo', path: '/bar/baz'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should move into root', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect( jsonpatch.apply(obj, [{op: 'move', from: '/bar', path: ''}]) )
            .to.deep.equal( {baz: 'spam'} )

    it 'should move into empty key at root', ->
        obj = {foo: 1, bar: 'eggs'}
        expect( jsonpatch.apply(obj, [{op: 'move', from: '/bar', path: '/'}]) )
            .to.deep.equal( {foo: 1, '': 'eggs'} )

    it 'should move into empty key not at root', ->
        obj = {foo: 1, bar: {baz: 'spam'}, quux: 'eggs'}
        expect( jsonpatch.apply(obj, [{op: 'move', from: '/quux', path: '/bar/'}]) )
            .to.deep.equal( {foo: 1, bar: {baz: 'spam', '': 'eggs'}} )

    it 'should move into empty array at explicit last position', ->
        obj = {foo: 1, bar: [], baz: 'spam'}
        expect( jsonpatch.apply(obj, [{op: 'move', from: '/baz', path: '/bar/0'}]) )
            .to.deep.equal( {foo: 1, bar: ['spam']} )

    it 'should move into empty array at implicit last position', ->
        obj = {foo: 1, bar: [], baz: 'spam'}
        expect( jsonpatch.apply(obj, [{op: 'move', from: '/baz', path: '/bar/-'}]) )
            .to.deep.equal( {foo: 1, bar: ['spam']} )

    it 'should move into array at existing position', ->
        obj = {foo: 1, bar: ['spam', 'bacon'], quux: 'eggs'}
        expect( jsonpatch.apply(obj, [{op: 'move', from: '/quux', path: '/bar/1'}]) )
            .to.deep.equal( {foo: 1, bar: ['spam', 'eggs', 'bacon']} )

    it 'should move into array at explicit last position', ->
        obj = {foo: 1, bar: ['spam', 'eggs'], quux: 'bacon'}
        expect( jsonpatch.apply(obj, [{op: 'move', from: '/quux', path: '/bar/2'}]) )
            .to.deep.equal( {foo: 1, bar: ['spam', 'eggs', 'bacon']} )

    it 'should move into array at implicit last position', ->
        obj = {foo: 1, bar: ['spam', 'eggs'], quux: 'bacon'}
        expect( jsonpatch.apply(obj, [{op: 'move', from: '/quux', path: '/bar/-'}]) )
            .to.deep.equal( {foo: 1, bar: ['spam', 'eggs', 'bacon']} )

    it 'should fail if target array position out of bounds', ->
        obj = {foo: 1, bar: ['spam', 'bacon'], quux: 'eggs'}
        expect( -> jsonpatch.apply(obj, [{op: 'move', from: '/quux', path: '/bar/3'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should move into nonexisting object key', ->
        obj = {foo: 1, bar: {quux: 'eggs'}, xyzzy: 'spam'}
        expect( jsonpatch.apply(obj, [{op: 'move', from: '/xyzzy', path: '/bar/baz'}]) )
            .to.deep.equal( {foo: 1, bar: {baz: 'spam', quux: 'eggs'}} )

    it 'should move into existing object key', ->
        obj = {foo: 1, bar: {baz: 'spam', quux: 'eggs'}, xyzzy: 'bacon'}
        expect( jsonpatch.apply(obj, [{op: 'move', from: '/xyzzy', path: '/bar/baz'}]) )
            .to.deep.equal( {foo: 1, bar: {baz: 'bacon', quux: 'eggs'}} )

    it 'should move into object inside array', ->
        obj = {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs'}], waldo: 'bacon'}
        expect( jsonpatch.apply(obj, [{op: 'move', from: '/waldo', path: '/bar/1/xyzzy'}]) )
            .to.deep.equal( {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs', xyzzy: 'bacon'}]} )

    # Tests for source

    it 'should fail if source path has nonexisting component', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect( -> jsonpatch.apply(obj, [{op: 'move', from: '/xyzzy/waldo', path: '/bar/baz'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail if source path indexes a non-object', ->
        obj = {foo: 1, bar: {baz: 'spam'}, xyzzy: 2}
        expect( -> jsonpatch.apply(obj, [{op: 'move', from: '/xyzzy/waldo', path: '/bar/baz'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail if moving from root', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect( -> jsonpatch.apply(obj, [{op: 'move', from: '', path: '/waldo'}]) )
            .to.throw(jsonpatch.InvalidPatch)

    it 'should move from empty key at root', ->
        obj = {foo: 1, '': 'spam'}
        expect( jsonpatch.apply(obj, [{op: 'move', from: '/', path: '/waldo'}]) )
            .to.deep.equal( {foo: 1, waldo: 'spam'} )

    it 'should move from empty key not at root', ->
        obj = {foo: 1, bar: {baz: 'spam', '': 'eggs'}}
        expect( jsonpatch.apply(obj, [{op: 'move', from: '/bar/', path: '/waldo'}]) )
            .to.deep.equal( {foo: 1, bar: {baz: 'spam'}, waldo: 'eggs'} )

    it 'should fail if source array position does not exist', ->
        obj = {foo: 1, bar: ['spam', 'bacon']}
        expect( -> jsonpatch.apply(obj, [{op: 'move', from: '/bar/3', path: '/waldo'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should move from array at existing position', ->
        obj = {foo: 1, bar: ['spam', 'eggs']}
        expect( jsonpatch.apply(obj, [{op: 'move', from: '/bar/1', path: '/waldo'}]) )
            .to.deep.equal( {foo: 1, bar: ['spam'], waldo: 'eggs'} )

    it 'should fail if source object key does not exist', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect( -> jsonpatch.apply(obj, [{op: 'move', from: '/bar/quux', path: '/waldo'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should move from existing object key', ->
        obj = {foo: 1, bar: {baz: 'spam', quux: 'eggs'}}
        expect( jsonpatch.apply(obj, [{op: 'move', from: '/bar/baz', path: '/waldo'}]) )
            .to.deep.equal( {foo: 1, bar: {quux: 'eggs'}, waldo: 'spam'} )

    it 'should move from object inside array', ->
        obj = {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs'}]}
        expect( jsonpatch.apply(obj, [{op: 'move', from: '/bar/1/quux', path: '/waldo'}]) )
            .to.deep.equal( {foo: 1, bar: [{baz: 'spam'}, {}], waldo: 'eggs'} )


describe 'copy', ->

    it 'should fail if no source specified', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect( -> jsonpatch.apply(obj, [{op: 'copy', path: '/bar/baz'}]) )
            .to.throw(jsonpatch.InvalidPatchError)

    # Tests for target

    it 'should fail if target path has nonexisting component', ->
        obj = {foo: 1}
        expect( -> jsonpatch.apply(obj, [{op: 'copy', from: '/foo', path: '/bar/baz'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail if target path indexes a non-object', ->
        obj = {foo: 1, bar: 2}
        expect( -> jsonpatch.apply(obj, [{op: 'copy', from: '/foo', path: '/bar/baz'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should copy into root', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect( jsonpatch.apply(obj, [{op: 'copy', from: '/bar', path: ''}]) )
            .to.deep.equal( {baz: 'spam'} )

    it 'should copy into empty key at root', ->
        obj = {foo: 1, bar: 'spam'}
        expect( jsonpatch.apply(obj, [{op: 'copy', from: '/bar', path: '/'}]) )
            .to.deep.equal( {foo: 1, '': 'spam', bar: 'spam'} )

    it 'should copy into empty key not at root', ->
        obj = {foo: 1, bar: {baz: 'spam'}, quux: 'eggs'}
        expect( jsonpatch.apply(obj, [{op: 'copy', from: '/quux', path: '/bar/'}]) )
            .to.deep.equal( {foo: 1, bar: {baz: 'spam', '': 'eggs'}, quux: 'eggs'} )

    it 'should copy into empty array at explicit last position', ->
        obj = {foo: 1, bar: [], baz: 'spam'}
        expect( jsonpatch.apply(obj, [{op: 'copy', from: '/baz', path: '/bar/0'}]) )
            .to.deep.equal( {foo: 1, bar: ['spam'], baz: 'spam'} )

    it 'should copy into empty array at implicit last position', ->
        obj = {foo: 1, bar: [], baz: 'spam'}
        expect( jsonpatch.apply(obj, [{op: 'copy', from: '/baz', path: '/bar/-'}]) )
            .to.deep.equal( {foo: 1, bar: ['spam'], baz: 'spam'} )

    it 'should copy into array at existing position', ->
        obj = {foo: 1, bar: ['spam', 'bacon'], quux: 'eggs'}
        expect( jsonpatch.apply(obj, [{op: 'copy', from: '/quux', path: '/bar/1'}]) )
            .to.deep.equal( {foo: 1, bar: ['spam', 'eggs', 'bacon'], quux: 'eggs'} )

    it 'should copy into array at explicit last position', ->
        obj = {foo: 1, bar: ['spam', 'eggs'], quux: 'bacon'}
        expect( jsonpatch.apply(obj, [{op: 'copy', from: '/quux', path: '/bar/2'}]) )
            .to.deep.equal( {foo: 1, bar: ['spam', 'eggs', 'bacon'], quux: 'bacon'} )

    it 'should copy into array at implicit last position', ->
        obj = {foo: 1, bar: ['spam', 'eggs'], quux: 'bacon'}
        expect( jsonpatch.apply(obj, [{op: 'copy', from: '/quux', path: '/bar/-'}]) )
            .to.deep.equal( {foo: 1, bar: ['spam', 'eggs', 'bacon'], quux: 'bacon'} )

    it 'should fail if target array position out of bounds', ->
        obj = {foo: 1, bar: ['spam', 'bacon'], quux: 'eggs'}
        expect( -> jsonpatch.apply(obj, [{op: 'copy', from: '/quux', path: '/bar/3'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should copy into nonexisting object key', ->
        obj = {foo: 1, bar: {quux: 'eggs'}, xyzzy: 'spam'}
        expect( jsonpatch.apply(obj, [{op: 'copy', from: '/xyzzy', path: '/bar/baz'}]) )
            .to.deep.equal( {foo: 1, bar: {baz: 'spam', quux: 'eggs'}, xyzzy: 'spam'} )

    it 'should copy into existing object key', ->
        obj = {foo: 1, bar: {baz: 'spam', quux: 'eggs'}, xyzzy: 'bacon'}
        expect( jsonpatch.apply(obj, [{op: 'copy', from: '/xyzzy', path: '/bar/baz'}]) )
            .to.deep.equal( {foo: 1, bar: {baz: 'bacon', quux: 'eggs'}, xyzzy: 'bacon'} )

    it 'should copy into object inside array', ->
        obj = {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs'}], waldo: 'bacon'}
        expect( jsonpatch.apply(obj, [{op: 'copy', from: '/waldo', path: '/bar/1/xyzzy'}]) )
            .to.deep.equal( {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs', xyzzy: 'bacon'}], waldo: 'bacon'} )

    # Tests for source

    it 'should fail if source path has nonexisting component', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect( -> jsonpatch.apply(obj, [{op: 'copy', from: '/xyzzy/waldo', path: '/bar/baz'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail if source path indexes a non-object', ->
        obj = {foo: 1, bar: {baz: 'spam'}, xyzzy: 2}
        expect( -> jsonpatch.apply(obj, [{op: 'copy', from: '/xyzzy/waldo', path: '/bar/baz'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should copy from empty key at root', ->
        obj = {foo: 1, '': 'spam'}
        expect( jsonpatch.apply(obj, [{op: 'copy', from: '/', path: '/waldo'}]) )
            .to.deep.equal( {foo: 1, '': 'spam', waldo: 'spam'} )

    it 'should copy from empty key not at root', ->
        obj = {foo: 1, bar: {baz: 'spam', '': 'eggs'}}
        expect( jsonpatch.apply(obj, [{op: 'copy', from: '/bar/', path: '/waldo'}]) )
            .to.deep.equal( {foo: 1, bar: {baz: 'spam', '': 'eggs'}, waldo: 'eggs'} )

    it 'should fail if source array position does not exist', ->
        obj = {foo: 1, bar: ['spam', 'bacon']}
        expect( -> jsonpatch.apply(obj, [{op: 'copy', from: '/bar/3', path: '/waldo'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should copy from array at existing position', ->
        obj = {foo: 1, bar: ['spam', 'eggs']}
        expect( jsonpatch.apply(obj, [{op: 'copy', from: '/bar/1', path: '/waldo'}]) )
            .to.deep.equal( {foo: 1, bar: ['spam', 'eggs'], waldo: 'eggs'} )

    it 'should fail if source object key does not exist', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect( -> jsonpatch.apply(obj, [{op: 'copy', from: '/bar/quux', path: '/waldo'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should copy from existing object key', ->
        obj = {foo: 1, bar: {baz: 'spam', quux: 'eggs'}}
        expect( jsonpatch.apply(obj, [{op: 'copy', from: '/bar/baz', path: '/waldo'}]) )
            .to.deep.equal( {foo: 1, bar: {baz: 'spam', quux: 'eggs'}, waldo: 'spam'} )

    it 'should copy from object inside array', ->
        obj = {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs'}]}
        expect( jsonpatch.apply(obj, [{op: 'copy', from: '/bar/1/quux', path: '/waldo'}]) )
            .to.deep.equal( {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs'}], waldo: 'eggs'} )


describe 'test', ->

    # Failures

    it 'should fail if no value specified', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/bar/baz'}]) )
            .to.throw(jsonpatch.InvalidPatchError)

    it 'should fail if target has nonexisting component', ->
        obj = {foo: 1}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/bar/baz', value: 'spam'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail if target path indexes a non-object', ->
        obj = {foo: 1, bar: 2}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/bar/baz', value: 'spam'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail if target is nonexisting array position', ->
        obj = {foo: 1, bar: ['spam', 'eggs']}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/bar/2', value: 'eggs'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail if target is position past end of array', ->
        obj = {foo: 1, bar: ['spam', 'eggs']}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/bar/-', value: 'eggs'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail if target object key does not exist', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/bar/quux', value: 'spam'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    # Positive tests

    it 'should pass test on root', ->
        obj = {foo: 1, bar: ['spam']}
        expect(jsonpatch.apply(obj, [{op: 'test', path: '', value: {foo: 1, bar: ['spam']}}]) )
            .to.deep.equal( {foo: 1, bar: ['spam']} )

    it 'should pass test on empty key at root', ->
        obj = {foo: 1, '': {bar: 'spam', baz: 'eggs'}}
        expect( jsonpatch.apply(obj, [{op: 'test', path: '/', value: {bar: 'spam', baz: 'eggs'}}]) )
            .to.deep.equal( {foo: 1, '': {bar: 'spam', baz: 'eggs'}} )

    it 'should pass test on empty key not at root', ->
        obj = {foo: 1, bar: {baz: 'spam', '': {'eggs', 'bacon'}}}
        expect( jsonpatch.apply(obj, [{op: 'test', path: '/bar/', value: {'eggs', 'bacon'}}]) )
            .to.deep.equal( {foo: 1, bar: {baz: 'spam', '': {'eggs', 'bacon'}}} )

    it 'should pass test on existing array position', ->
        obj = {foo: 1, bar: ['spam', 'eggs', 'bacon']}
        expect( jsonpatch.apply(obj, [{op: 'test', path: '/bar/1', value: 'eggs'}]) )
            .to.deep.equal( {foo: 1, bar: ['spam', 'eggs', 'bacon']} )

    it 'should pass test on existing object key', ->
        obj = {foo: 1, bar: {baz: 'spam', quux: 'eggs'}}
        expect( jsonpatch.apply(obj, [{op: 'test', path: '/bar/baz', value: 'spam'}]) )
            .to.deep.equal( {foo: 1, bar: {baz: 'spam', quux: 'eggs'}} )

    it 'should pass test on key in object inside array', ->
        obj = {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs', xyzzy: 'bacon'}]}
        expect( jsonpatch.apply(obj, [{op: 'test', path: '/bar/1/xyzzy', value: 'bacon'}]) )
            .to.deep.equal( {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs', xyzzy: 'bacon'}]} )

    # Negative tests

    it 'should fail test on root', ->
        obj = {foo: 1, bar: ['spam']}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '', value: {foo: 1, bar: ['eggs']}}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail test on empty key at root', ->
        obj = {foo: 1, '': {bar: 'spam', baz: 'eggs'}}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/', value: {bar: 'spam', baz: 'bacon'}}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail test on empty key not at root', ->
        obj = {foo: 1, bar: {baz: 'spam', '': {'eggs', 'bacon'}}}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/bar/', value: {'eggs', 'tomato'}}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail test on existing array position', ->
        obj = {foo: 1, bar: ['spam', 'eggs', 'bacon']}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/bar/1', value: 'tomato'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail test on existing object key', ->
        obj = {foo: 1, bar: {baz: 'spam', quux: 'eggs'}}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/bar/baz', value: 'bacon'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail test on key in object inside array', ->
        obj = {foo: 1, bar: [{baz: 'spam'}, {quux: 'eggs', xyzzy: 'bacon'}]}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/bar/1/xyzzy', value: 'tomato'}]) )
            .to.throw(jsonpatch.PatchConflictError)


describe 'wildcard', ->

    it 'should pass test if last path component is wildcard', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect( jsonpatch.apply(obj, [{op: 'test', path: '/bar/*', value: 'spam'}]) )
            .to.deep.equal( {foo: 1, bar: {baz: 'spam'}} )

    it 'should fail test if wildcard component indexes a non-object', ->
        obj = {foo: 1, bar: 2}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/bar/*/quux', value: 'spam'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should pass test on path with matching wildcard on object key', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect( jsonpatch.apply(obj, [{op: 'test', path: '/*/baz', value: 'spam'}]) )
            .to.deep.equal( {foo: 1, bar: {baz: 'spam'}} )

    it 'should fail test on path with non-matching wildcard on object key', ->
        obj = {foo: 1, bar: {baz: 'spam'}}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/*/quux', value: 'spam'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should pass test on path with matching wildcard on array position', ->
        obj = {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}]}
        expect( jsonpatch.apply(obj, [{op: 'test', path: '/bar/*/baz', value: 'spam'}]) )
            .to.deep.equal( {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}]} )

    it 'should fail test on path with non-matching wildcard on array position', ->
        obj = {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}]}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/bar/*/waldo', value: 'spam'}]) )
            .to.throw(jsonpatch.PatchConflictError)


describe 'lookahead', ->

    it 'should fail if lookahead clause is malformed', ->
        obj = {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/*[baz]/quux', value: 'eggs'}]) )
            .to.throw(jsonpatch.InvalidPointerError)

    # Lookahead in final component

    it 'should pass test on path with matching final lookahead on object key', ->
        obj = {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
        expect( jsonpatch.apply(obj, [{op: 'test', path: '/bar/yes[baz=spam]', value: {baz: 'spam', quux: 'eggs'}}]) )
            .to.deep.equal( {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}} )

    it 'should fail test on path with non-matching final lookahead key on object key', ->
        obj = {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/yes[quack=spam]', value: {baz: 'spam', quux: 'eggs'}}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail test on path with non-matching final lookahead value on object key', ->
        obj = {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/yes[baz=eggs]', value: {baz: 'spam', quux: 'eggs'}}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should pass test on path with matching final lookahead on array position', ->
        obj = {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}
        expect( jsonpatch.apply(obj, [{op: 'test', path: '/bar/0[baz=spam]', value: {baz: 'spam', quux: 'eggs'}}]) )
            .to.deep.equal( {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]} )

    it 'should fail test on path with non-matching final lookahead key on array position', ->
        obj = {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/bar/0[quack=spam]', value: {baz: 'spam', quux: 'eggs'}}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail test on path with non-matching final lookahead value on array position', ->
        obj = {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/bar/0[spam=eggs]', value: {baz: 'spam', quux: 'eggs'}}]) )
            .to.throw(jsonpatch.PatchConflictError)

    # Lookahead in non-final component

    it 'should pass test on path with matching non-final lookahead on object key', ->
        obj = {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
        expect( jsonpatch.apply(obj, [{op: 'test', path: '/bar/yes[baz=spam]/quux', value: 'eggs'}]) )
            .to.deep.equal( {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}} )

    it 'should fail test on path with non-matching non-final lookahead key on object key', ->
        obj = {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/yes[quack=spam]/quux', value: 'eggs'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail test on path with non-matching non-final lookahead value on object key', ->
        obj = {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/yes[baz=eggs]/quux', value: 'eggs'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should pass test on path with matching non-final lookahead on array position', ->
        obj = {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}
        expect( jsonpatch.apply(obj, [{op: 'test', path: '/bar/0[baz=spam]/quux', value: 'eggs'}]) )
            .to.deep.equal( {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]} )

    it 'should fail test on path with non-matching non-final lookahead key on array position', ->
        obj = {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/bar/0[quack=spam]/quux', value: 'eggs'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail test on path with non-matching non-final lookahead value on array position', ->
        obj = {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/bar/0[spam=eggs]/quux', value: 'eggs'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    # Lookahead in final component, combined with wildcard

    it 'should pass test on path with matching final lookahead on wildcard object key', ->
        obj = {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
        expect( jsonpatch.apply(obj, [{op: 'test', path: '/bar/*[baz=spam]', value: {baz: 'spam', quux: 'eggs'}}]) )
            .to.deep.equal( {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}} )

    it 'should fail test on path with non-matching final lookahead key on wildcard object key', ->
        obj = {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/*[quack=spam]', value: {baz: 'spam', quux: 'eggs'}}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail test on path with non-matching final lookahead value on wildcard object key', ->
        obj = {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/*[baz=eggs]', value: {baz: 'spam', quux: 'eggs'}}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should pass test on path with matching final lookahead on wildcard array position', ->
        obj = {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}
        expect( jsonpatch.apply(obj, [{op: 'test', path: '/bar/*[baz=spam]', value: {baz: 'spam', quux: 'eggs'}}]) )
            .to.deep.equal( {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]} )

    it 'should fail test on path with non-matching final lookahead key on wildcard array position', ->
        obj = {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/bar/*[quack=spam]', value: {baz: 'spam', quux: 'eggs'}}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail test on path with non-matching final lookahead value on wildcard array position', ->
        obj = {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/bar/*[spam=eggs]', value: {baz: 'spam', quux: 'eggs'}}]) )
            .to.throw(jsonpatch.PatchConflictError)

    # Lookahead in non-final component, combined with wildcard

    it 'should pass test on path with matching non-final lookahead on wildcard object key', ->
        obj = {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
        expect( jsonpatch.apply(obj, [{op: 'test', path: '/bar/*[baz=spam]/quux', value: 'eggs'}]) )
            .to.deep.equal( {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}} )

    it 'should fail test on path with non-matching non-final lookahead key on wildcard object key', ->
        obj = {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/*[quack=spam]/quux', value: 'eggs'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail test on path with non-matching non-final lookahead value on wildcard object key', ->
        obj = {foo: 1, bar: {yes: {baz: 'spam', quux: 'eggs'}, no: {xyzzy: 'bacon'}}}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/*[baz=eggs]/quux', value: 'eggs'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should pass test on path with matching non-final lookahead on wildcard array position', ->
        obj = {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}
        expect( jsonpatch.apply(obj, [{op: 'test', path: '/bar/*[baz=spam]/quux', value: 'eggs'}]) )
            .to.deep.equal( {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]} )

    it 'should fail test on path with non-matching non-final lookahead key on wildcard array position', ->
        obj = {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/bar/*[quack=spam]/quux', value: 'eggs'}]) )
            .to.throw(jsonpatch.PatchConflictError)

    it 'should fail test on path with non-matching non-final lookahead value on wildcard array position', ->
        obj = {foo: 1, bar: [{baz: 'spam', quux: 'eggs'}, {xyzzy: 'bacon'}]}
        expect( -> jsonpatch.apply(obj, [{op: 'test', path: '/bar/*[spam=eggs]/quux', value: 'eggs'}]) )
            .to.throw(jsonpatch.PatchConflictError)
