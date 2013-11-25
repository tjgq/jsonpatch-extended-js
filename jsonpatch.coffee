# jsonpatch.js 0.4
# (c) 2011-2012 Byron Ruth
# jsonpatch may be freely distributed under the BSD license

((root, factory) ->
    if typeof exports isnt 'undefined'
        # NodeJS
        _ = require 'lodash'
        factory(root, _)
    else
        # Browser
        root.jsonpatch = factory(root, window._)
) @, (root, _) ->

    # Utilities
    toString = Object.prototype.toString
    hasOwnProperty = Object.prototype.hasOwnProperty

    # Grab a few helper functions from underscore/lodash
    isArray = _.isArray
    isObject = _.isObject
    isString = _.isString
    isEqual = _.isEqual
    cloneDeep = _.cloneDeep

    # Various error constructors
    class JSONPatchError extends Error
        constructor: (@message='JSON patch error') ->
            @name = 'JSONPatchError'

    class InvalidPointerError extends Error
        constructor: (@message='Invalid pointer') ->
            @name = 'InvalidPointer'

    class InvalidPatchError extends JSONPatchError
        constructor: (@message='Invalid patch') ->
            @name = 'InvalidPatch'

    class PatchConflictError extends JSONPatchError
        constructor: (@message='Patch conflict') ->
            @name = 'PatchConflictError'


    # Spec: http://tools.ietf.org/html/draft-ietf-appsawg-json-pointer-05
    class JSONPointer
        constructor: (path) ->
            steps = []

            # A path must either be empty or start with /.
            # An empty path refers to the document root.
            if path and (steps = path.split '/').shift() isnt ''
                throw new InvalidPointerError('Path must be empty or start with /')

            # Decode each component, decode JSON Pointer specific syntax ~0 and ~1
            for step, i in steps
                steps[i] = step.replace('~1', '/').replace('~0', '~')

            # The final segment is the accessor (property/index) of the object
            # the pointer ultimately references
            @accessor = steps.pop()
            @steps = steps
            @path = path

        # Returns an object with the object reference and the accessor
        getReference: (parent) ->
            ref = @findReference parent, 0
            if ref is null
                throw new PatchConflictError('Array location out of ' +
                    'bounds or not an instance property')
            return ref

        findReference: (parent, level) ->
            step = @steps[level]
            return parent if step is undefined
            if isArray parent then step = parseInt(step, 10)
            if step not of parent
                return null
            return @findReference parent[step], level + 1

        # Returns an accessor coerced relative to the
        # reference object it will be applied to.
        getAccessor: (reference) ->
            accessor = @accessor
            if isArray(reference)
                if isString(accessor)
                    if accessor is '-'
                        accessor = reference.length
                    else if /^\d+$/.test(accessor)
                        accessor = parseInt(accessor, 10)
                    else
                        throw new InvalidPointerError('Invalid array index number')
            return accessor


    # Interface for patch operation classes
    class JSONPatch
        constructor: (patch) ->
            # All patches required a 'path' member
            if 'path' not of patch
                throw new InvalidPatchError('Missing path')

            # Validates the patch based on the requirements of this operation
            @validate(patch)
            @patch = patch
            # Create the primary pointer for this operation
            @path = new JSONPointer(patch.path)
            # Call for operation-specific setup
            @initialize(patch)

        initialize: ->

        validate: (patch) ->

        apply: (document) ->
            unless @applyInPlace then throw new Error('Method not implemented')
            # Apply the patch to a deep copy of the original document.
            @applyInPlace(cloneDeep(document))


    class AddPatch extends JSONPatch
        validate: (patch) ->
            if 'value' not of patch then throw new InvalidPatchError('Missing value')

        applyInPlace: (document) ->
            reference = @path.getReference(document)
            accessor = @path.getAccessor(reference)
            value = @patch.value

            if not accessor?
                document = value
            else if isArray(reference)
                unless 0 <= accessor <= reference.length
                    throw new PatchConflictError("Index #{accessor} out of bounds")
                reference.splice(accessor, 0, value)
            else
                reference[accessor] = value

            return document


    class RemovePatch extends JSONPatch
        applyInPlace: (document) ->
            reference = @path.getReference(document)
            accessor = @path.getAccessor(reference)

            if accessor not of reference
                throw new PatchConflictError("Value at #{accessor} does not exist")
            if isArray(reference)
                reference.splice(accessor, 1)
            else
                delete reference[accessor]

            return document


    class ReplacePatch extends JSONPatch
        validate: (patch) ->
            if 'value' not of patch then throw new InvalidPatchError('Missing value')

        applyInPlace: (document) ->
            reference = @path.getReference(document)
            accessor = @path.getAccessor(reference)
            value = @patch.value

            if not accessor?
                document = value
            else
                if accessor not of reference
                    throw new PatchConflictError("Value at #{accessor} does not exist")
                if isArray(reference)
                    reference.splice(accessor, 1, value)
                else
                    reference[accessor] = value

            return document


    class TestPatch extends JSONPatch
        validate: (patch) ->
            if 'value' not of patch then throw new InvalidPatchError('Missing value')

        applyInPlace: (document) ->
            reference = @path.getReference(document)
            accessor = @path.getAccessor(reference)
            value = @patch.value

            if not accessor?
                result = isEqual(document, value)
            else
                result = isEqual(reference[accessor], value)

            if not result
                throw new PatchConflictError('Test failed')

            return document


    class MovePatch extends JSONPatch
        initialize: (patch) ->
            @from = new JSONPointer(patch.from)

            # Check whether @from is a proper prefix of @path.
            # Don't forget that the last component of @from is its accessor.
            isPrefix = true
            for i in [0...@from.steps.length]
                if @from.steps[i] isnt @path.steps[i]
                    isPrefix = false
                    break
            isPrefix = false if @from.accessor isnt @path.steps[@from.steps.length]
            isPrefix = false if @from.path == '' and @path.path == '' # moving root into root

            if isPrefix
                throw new InvalidPatchError("Cannot move into ancestor")

            if @from.accessor is @path.accessor
                # Source and target are the same, therefore apply can be a no-op
                @applyInPlace = (document) -> document

        validate: (patch) ->
            if 'from' not of patch then throw new InvalidPatchError('Missing from')

        applyInPlace: (document) ->
            reference = @from.getReference(document)
            accessor = @from.getAccessor(reference)

            if accessor not of reference
                throw new PatchConflictError("Value at #{accessor} does not exist")
            if isArray(reference)
                value = reference.splice(accessor, 1)[0]
            else
                value = reference[accessor]
                delete reference[accessor]

            reference = @path.getReference(document)
            accessor = @path.getAccessor(reference)

            # Add to object
            if not accessor?
                document = value
            else if isArray(reference)
                unless 0 <= accessor <= reference.length
                    throw new PatchConflictError("Index #{accessor} out of bounds")
                reference.splice(accessor, 0, value)
            else
                reference[accessor] = value

            return document


    class CopyPatch extends MovePatch
        applyInPlace: (document) ->
            reference = @from.getReference(document)
            accessor = @from.getAccessor(reference)

            if accessor not of reference
                throw new PatchConflictError("Value at #{accessor} does not exist")
            if isArray(reference)
                value = reference.slice(accessor, accessor + 1)[0]
            else
                value = reference[accessor]

            reference = @path.getReference(document)
            accessor = @path.getAccessor(reference)

            # Add to object
            if not accessor?
                document = value
            else if isArray(reference)
                unless 0 <= accessor <= reference.length
                    throw new PatchConflictError("Index #{accessor} out of bounds")
                reference.splice(accessor, 0, value)
            else
                reference[accessor] = value

            return document


    # Map of operation classes
    operationMap =
        add: AddPatch
        remove: RemovePatch
        replace: ReplacePatch
        move: MovePatch
        copy: CopyPatch
        test: TestPatch


    # Validates and compiles a patch document and returns a function to apply
    # to multiple documents
    compile = (patch) ->
        ops = []

        for p in patch
            # Not a valid operation
            if not p.op then throw new InvalidPatchError('Missing operation')
            if not (klass = operationMap[p.op])
                throw new InvalidPatchError('Invalid operation')
            ops.push new klass(p)

        return (document) ->
            # Since we are applying multiple patches in succession,
            # we only need to clone the original document and apply
            # the patches in place.
            result = cloneDeep(document)
            for op in ops
                result = op.applyInPlace(document)
            return result


    # Applies a patch to a document
    apply = (document, patch) ->
        compile(patch)(document)


    # Export to root
    root.apply = apply
    root.compile = compile
    root.JSONPointer = JSONPointer
    root.JSONPatch = JSONPatch
    root.JSONPatchError = JSONPatchError
    root.InvalidPointerError = InvalidPointerError
    root.InvalidPatchError = InvalidPatchError
    root.PatchConflictError = PatchConflictError

    return root
