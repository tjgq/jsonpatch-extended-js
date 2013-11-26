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
    listIndices = (arr) -> [0...arr.length]
    listKeys = _.keys
    cloneDeep = _.cloneDeep

    coerceForArray = (reference, accessor, modify) ->
        switch
            when accessor is '-'
                accessor = reference.length
            when /^\d+$/.test(accessor)
                accessor = parseInt(accessor, 10)
            else
                return null
        if accessor < reference.length + (if modify then 1 else 0)
            return accessor
        return null

    coerceForObject = (reference, accessor, modify) ->
        if modify or accessor of reference
            return accessor
        return null

    # Coerce an accessor relative to the reference object type
    # and whether modifications are allowed.
    # Returns null if the reference is invalid.
    coerce = (reference, accessor, modify) ->
        switch
            when isArray(reference)
                return coerceForArray(reference, accessor, modify)
            when isObject(reference)
                return coerceForObject(reference, accessor, modify)
            else
                # Attempting to index a non-object
                return null

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

    # The singleton wildcard object.
    Wildcard = {}

    # Spec: http://tools.ietf.org/html/draft-ietf-appsawg-json-pointer-05
    # Extended to support wildcard matching on path components.
    class JSONPointer
        constructor: (path) ->
            steps = []

            # A path must either be empty or start with /.
            # An empty path refers to the document root.
            if path and (steps = path.split '/').shift() isnt ''
                throw new InvalidPointerError('Path must be empty or start with /')

            # Decode each component, decode JSON Pointer specific syntax ~0 and ~1
            for step, i in steps
                if steps[i] is '*'
                    steps[i] = Wildcard
                else
                    # Unescape each component
                    steps[i] = step
                        .replace('~2', '*')
                        .replace('~1', '/')
                        .replace('~0', '~')

            @steps = steps
            @path = path

        # Return the object referenced by the pointer and its parent object.
        # Modify determines whether the reference is to be modified,
        # in which case the last component may not exist yet.
        # If the referenced object is the root, return a null parent.
        # If the pointed to object is not found, return a null object.
        getReference: (object, modify) ->

            find = (object, level) =>

                findWildcard = () =>
                    # Try every array position or object property.
                    elems = switch
                        when isArray object then listIndices object
                        when isObject object then listKeys object
                        else [] # XXX what about primitive types?
                    for e in elems
                        # Return the first successful match.
                        [reference, accessor] = find(object[e], level + 1)
                        return [reference, accessor] if accessor?
                    return [object, null]

                step = @steps[level]
                isLast = level is @steps.length - 1
                if step is Wildcard
                    throw InvalidPointerError("Last path component can't be wildcard") if isLast
                    return findWildcard(object, level)
                accessor = coerce(object, step, modify and isLast)
                return [object, null] unless accessor?
                return [object, accessor] if isLast
                return find(object[accessor], level + 1)

            return [null, object] unless @steps.length # root doc
            return find(object, 0)


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
            # Apply the patch to a deep copy of the original document.
            @applyInPlace(cloneDeep(document))


    class SourceRefPatch extends JSONPatch
        applyInPlace: (document) ->
            [reference, accessor] = @path.getReference(document, false)
            unless accessor?
                throw new PatchConflictError("Source path not found")
            value = @patch.value
            return @realApply(document, reference, accessor, value)


    class TargetRefPatch extends JSONPatch
        applyInPlace: (document) ->
            [reference, accessor] = @path.getReference(document, true)
            unless accessor?
                throw new PatchConflictError("Target path not found")
            value = @patch.value
            return @realApply(document, reference, accessor, value)


    class BothRefsPatch extends JSONPatch
        initialize: (patch) ->
            @from = new JSONPointer(patch.from)

            # Check whether @from is a prefix of @path.
            isPrefix = true
            for i in [0...@from.steps.length]
                if @from.steps[i] isnt @path.steps[i]
                    isPrefix = false
                    break

            if isPrefix
                if @from.steps.length is @path.steps.length
                    # Source and target are the same, therefore apply can be a no-op
                    @applyInPlace = (document) -> document
                else
                    # From is a proper prefix of path
                    throw new InvalidPatchError("Cannot move or copy into ancestor")

        applyInPlace: (document) ->
            [fromReference, fromAccessor] = @from.getReference(document, false)
            unless fromAccessor?
                throw new PatchConflictError("Source path not found")
            [toReference, toAccessor] = @path.getReference(document, true)
            unless toAccessor?
                throw new PatchConflictError("Target path not found")
            return @realApply(document, fromReference, fromAccessor, toReference, toAccessor)


    class AddPatch extends TargetRefPatch
        validate: (patch) ->
            if 'value' not of patch then throw new InvalidPatchError('Missing value')

        realApply: (document, reference, accessor, value) ->
            if not reference?
                document = value
            else if isArray(reference)
                reference.splice(accessor, 0, value)
            else
                reference[accessor] = value
            return document


    class RemovePatch extends SourceRefPatch
        realApply: (document, reference, accessor, value) ->
            if not reference?
                throw new PatchConflictError("Can't remove root document")
            if isArray(reference)
                reference.splice(accessor, 1)
            else
                delete reference[accessor]
            return document


    class ReplacePatch extends SourceRefPatch
        validate: (patch) ->
            if 'value' not of patch then throw new InvalidPatchError('Missing value')

        realApply: (document, reference, accessor, value) ->
            if not reference?
                document = value
            else
                if isArray(reference)
                    reference.splice(accessor, 1, value)
                else
                    reference[accessor] = value
            return document


    class TestPatch extends SourceRefPatch
        validate: (patch) ->
            if 'value' not of patch then throw new InvalidPatchError('Missing value')

        realApply: (document, reference, accessor, value) ->
            if not reference?
                result = isEqual(document, value)
            else
                result = isEqual(reference[accessor], value)
            if not result
                throw new PatchConflictError('Test failed')
            return document


    class MovePatch extends BothRefsPatch
        validate: (patch) ->
            if 'from' not of patch then throw new InvalidPatchError('Missing from')

        realApply: (document, fromReference, fromAccessor, toReference, toAccessor) ->
            if isArray(fromReference)
                value = fromReference.splice(fromAccessor, 1)[0]
            else
                value = fromReference[fromAccessor]
                delete fromReference[fromAccessor]
            if not toReference?
                document = value
            else if isArray(toReference)
                toReference.splice(toAccessor, 0, value)
            else
                toReference[toAccessor] = value
            return document


    class CopyPatch extends BothRefsPatch
        validate: (patch) ->
            if 'from' not of patch then throw new InvalidPatchError('Missing from')

        realApply: (document, fromReference, fromAccessor, toReference, toAccessor) ->
            if isArray(fromReference)
                value = fromReference.slice(fromAccessor, fromAccessor + 1)[0]
            else
                value = fromReference[fromAccessor]
            if not toReference?
                document = value
            else if isArray(toReference)
                toReference.splice(toAccessor, 0, value)
            else
                toReference[toAccessor] = value
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
