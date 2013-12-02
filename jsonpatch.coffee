# jsonpatch.js
# (c) 2013 Tiago Quelhas, (c) 2011-2012 Byron Ruth
# This code may be freely distributed under the BSD license.

((root, factory) ->
    if typeof exports isnt 'undefined'
        # NodeJS
        factory(root, require('lodash'))
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

    coerceForArray = (reference, accessor, modify, adjust) ->
        switch
            when accessor is '-'
                accessor = reference.length
            when /^\d+$/.test(accessor)
                accessor = parseInt(accessor, 10)
            else
                return null
        if modify and adjust
            accessor = Math.min(accessor, reference.length)
        if accessor < reference.length + (if modify then 1 else 0)
            return accessor
        return null

    coerceForObject = (reference, accessor, modify) ->
        if modify or accessor of reference
            return accessor
        return null

    # Coerce an accessor relative to the reference object type,
    # whether modifications are allowed, and whether out-of-bounds
    # array indices should be adjusted down to the array length.
    # Returns null if the reference is invalid.
    coerce = (reference, accessor, modify, adjust) ->
        switch
            when isArray(reference)
                return coerceForArray(reference, accessor, modify, adjust)
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
    # Extended to support wildcard matching and single-level, single-attribute lookahead.
    class JSONPointer
        constructor: (path) ->
            steps = []
            lookaheads = []

            # A path must either be empty or start with /.
            # An empty path refers to the document root.
            if path and (steps = path.split '/').shift() isnt ''
                throw new InvalidPointerError('Path must be empty or start with /')

            for step, i in steps
                [steps[i], lookaheads[i]] = @decodeStep(step)

            @steps = steps
            @lookaheads = lookaheads
            @path = path

        decodeStep: (step) ->
            # 1st token is accessor
            # 2nd token is lookahead
            # 3rd token is lookahead key name
            # 4th token is lookahead key value
            match = /^([^\[]*)(\[([^\]=]*)=([^\]]*)\])?$/.exec(step)
            unless match?
                throw new InvalidPointerError("Invalid component")
            lookahead = if match[2] then [match[3], match[4]] else null
            step = if match[1] is '*' then Wildcard else @unescape(match[1])
            return [step, lookahead]

        # Decode JSON Pointer specific syntax ~0 and ~1
        unescape: (step) ->
            step.replace('~2', '*').replace('~1', '/').replace('~0', '~')

        # Return the object referenced by the pointer and its parent object.
        # Modify determines whether the reference is a modification target,
        # in which case the last component may not yet exist.
        # If modify and lax are both set, adjust out-of-bounds array indices
        # to the last position.
        # If the referenced object is the root, return a null parent.
        # If the pointed to object is not found, return a null object.
        getReference: (object, modify, lax) ->
            return [null, object] unless @steps.length # root doc
            return @findReference(object, 0, modify, lax)

        # Find a reference, beginning at the specified level.
        findReference: (object, level, modify, lax) =>

            matchLookahead = (object) =>
                return true unless @lookaheads[level]
                return false unless isArray(object) or isObject(object)
                [key, value] = @lookaheads[level]
                return key of object and object[key] is value

            # Get the current step.
            step = @steps[level]
            isLast = level is @steps.length - 1

            # Determine the available search possibilities.
            if step is Wildcard
                # Consider every array position or object property.
                accessors = switch
                    when isArray object then listIndices object
                    when isObject object then listKeys object
                    else [] # XXX what about primitive types?
            else
                # Consider only the specified array position or object property,
                # as long as it exists or is a modification target.
                acc = coerce(object, step, modify and isLast, lax)
                accessors =  if acc? then [acc] else []

            # Go through each search possibility.
            for acc in accessors
                # Check that the lookahead matches.
                continue unless matchLookahead(object[acc])
                # If this is the last step, don't go any deeper.
                return [object, acc] if isLast
                # Search one level deeper.
                [ref, acc] = @findReference(object[acc], level+1, modify, lax)
                # Return the first match.
                return [ref, acc] if acc?

            # No match found.
            return [object, null]


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

        apply: (document, lax=true) ->
            # Apply the patch to a deep copy of the original document.
            @applyInPlace(cloneDeep(document), lax)


    class SourceRefPatch extends JSONPatch
        applyInPlace: (document, lax) ->
            [reference, accessor] = @path.getReference(document, false)
            unless accessor?
                if lax then return document
                throw new PatchConflictError("Source path '#{@path.path}' not found")
            value = cloneDeep(@patch.value)
            return @realApply(document, reference, accessor, value, lax)


    class TargetRefPatch extends JSONPatch
        applyInPlace: (document, lax) ->
            [reference, accessor] = @path.getReference(document, true, lax)
            unless accessor?
                if lax then return document
                throw new PatchConflictError("Target path '#{@path.path}' not found")
            value = cloneDeep(@patch.value)
            return @realApply(document, reference, accessor, value, lax)


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

        applyInPlace: (document, lax) ->
            [fromReference, fromAccessor] = @from.getReference(document, false)
            unless fromAccessor?
                if lax then return document
                throw new PatchConflictError("Source path '#{@from.path}' not found")
            [toReference, toAccessor] = @path.getReference(document, true, lax)
            unless toAccessor?
                if lax then return document
                throw new PatchConflictError("Target path '#{@path.path}' not found")
            return @realApply(document, fromReference, fromAccessor, toReference, toAccessor, lax)


    class AddPatch extends TargetRefPatch
        validate: (patch) ->
            if 'value' not of patch then throw new InvalidPatchError('Missing value')

        realApply: (document, reference, accessor, value, lax) ->
            if not reference?
                document = value
            else if isArray(reference)
                reference.splice(accessor, 0, value)
            else
                reference[accessor] = value
            return document


    class RemovePatch extends SourceRefPatch
        realApply: (document, reference, accessor, value, lax) ->
            if not reference?
                throw new InvalidPatchError("Can't remove root document")
            if isArray(reference)
                reference.splice(accessor, 1)
            else
                delete reference[accessor]
            return document


    class ReplacePatch extends JSONPatch
        validate: (patch) ->
            if 'value' not of patch then throw new InvalidPatchError('Missing value')

        applyInPlace: (document, lax) ->
            if lax
                TargetRefPatch.prototype.applyInPlace.call(@, document, lax)
            else
                SourceRefPatch.prototype.applyInPlace.call(@, document, lax)

        realApply: (document, reference, accessor, value, lax) ->
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

        realApply: (document, reference, accessor, value, lax) ->
            if not reference?
                result = isEqual(document, value)
            else
                result = isEqual(reference[accessor], value)
            if not result
                if lax then return document
                throw new PatchConflictError("Test on path '#{@path.path}' failed")
            return document


    class MovePatch extends BothRefsPatch
        validate: (patch) ->
            if 'from' not of patch then throw new InvalidPatchError('Missing from')

        realApply: (document, fromReference, fromAccessor, toReference, toAccessor, lax) ->
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

        realApply: (document, fromReference, fromAccessor, toReference, toAccessor, lax) ->
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

        return (document, lax=true) ->
            # Since we are applying multiple patches in succession,
            # we only need to clone the original document and apply
            # the patches in place.
            result = cloneDeep(document)
            for op in ops
                result = op.applyInPlace(document, lax)
            return result


    # Applies a patch to a document.
    # If lax, conflicting patches are silently ignored.
    apply = (document, patch, lax=true) ->
        compile(patch)(document, lax)


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
