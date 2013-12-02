# jsonpatch-extended.js

Javascript library to apply JSON Patches with JSON Pointer syntax extensions.

Code adapted from [jsonpatch-js](http://github.com/bruth/jsonpatch-js) by Byron Ruth.

References:

* JSON Patch - http://tools.ietf.org/html/rfc6902
* JSON Pointer - http://tools.ietf.org/html/rfc6901
* Extensions (to be documented):
    * wildcard references
    * attribute lookahead
    * lax mode

## Methods

**`jsonpatch.apply(document, patch, lax=true)`**

Applies a patch set to the document. The last parameter enables lax mode, in which the following modifications are made to the JSONPatch algorithm:
* The add operation adjusts out-of-bounds array indices down to the array length.
* The replace operation works even when the source location does not exist: for objects the new key is created, and for arrays the item is inserted at the end.
* Any other conflicting patches are silently ignored instead of aborting the operation.

**`jsonpatch.compile(patch)`**

Compiles a patch set and returns a function that takes a document to apply the patch set to.

## Patch Operations

### Add

Patch syntax: `{op: 'add', path: <path>, value: <value>}`

```javascript
// Add property, result: {foo: 'bar'}
jsonpatch.apply({}, [{op: 'add', path: '/foo', value: 'bar'}]);

// Add array element, result: {foo: [1, 2, 3]}
jsonpatch.apply({foo: [1, 3]}, [{op: 'add', path: '/foo/1', value: 2}]);

// Complex, result: {foo: [{bar: 'baz'}]}
jsonpatch.apply({foo: [{}]}, [{op: 'add', path: '/foo/0/bar', value: 'baz'}]);
```

### Remove

Patch syntax: `{op: 'remove', path: <path>}`

```javascript
// Remove property, result: {}
jsonpatch.apply({foo: 'bar'}, [{op: 'remove', path: '/foo'}]);

// Remove array element, result: {foo: [1, 3]}
jsonpatch.apply({foo: [1, 2, 3]}, [{op: 'remove', path: '/foo/1'}]);

// Complex, result: {foo: [{}]}
jsonpatch.apply({foo: [{bar: 'baz'}]}, [{op: 'remove', path: '/foo/0/bar'}]);
```

### Replace

Patch syntax: `{op: 'replace', path: <path>, value: <value>}`

```javascript
// Replace property, result: {foo: 1}
jsonpatch.apply({foo: 'bar'}, [{op: 'replace', path: '/foo', value: 1}]);

// Repalce array element, result: {foo: [1, 4, 3]}
jsonpatch.apply({foo: [1, 2, 3]}, [{op: 'replace', path: '/foo/1', value: 4}]);

// Complex, result: {foo: [{bar: 1}]}
jsonpatch.apply({foo: [{bar: 'baz'}]}, [{op: 'replace', path: '/foo/0/bar', value: 1}]);
```

### Move

Patch syntax: `{op: 'move', from: <path>, path: <path>}`

```javascript
// Move property, result {bar: [1, 2, 3]}
jsonpatch.apply({foo: [1, 2, 3]}, [{op: 'move', from: '/foo', path: '/bar'}]);
```

### Copy

Patch syntax: `{op: 'copy', from: <path>, path: <path>}`

```javascript
// Copy property, result {foo: [1, 2, 3], bar: 2}
jsonpatch.apply({foo: [1, 2, 3]}, [{op: 'copy', from: '/foo/1', path: '/bar'}]);
```

### Test

Patch syntax: `{op: 'test', path: <path>, value: <value>}`

```javascript
// Test equality of property to value, result: {foo: 'bar'}
jsonpatch.apply({foo: 'bar'}, [{op: 'test', path: '/foo', value: 'bar'}]
```

## Error Types

**`JSONPatchError`**

Base error type which all patch errors extend from.

**`InvalidPointerError`**

Thrown when the pointer is invalid.

**`InvalidPatchError`**

Thrown when the patch itself has an invalid syntax.

**`PatchConflictError`**

Thrown when there is a conflic with applying the patch to the document.
