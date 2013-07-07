utils = require('../common/utils')
console = require 'console'
AppError = require('../common/apperror').AppError

class BaseModel

    constructor: (params) ->
        utils.extend(this, params)
        meta = @constructor.__getMeta__()
        if @_id
            @_id = meta.type._database.ObjectId(@_id)


           
    @get: (params, context, cb) ->
        meta = @__getMeta__()
        @_database.findOne meta.collection, params, (err, result) =>
            cb err, if result then @constructModel(result, meta)



    @getAll: (params, context, cb) ->
        meta = @__getMeta__()
        @_database.find meta.collection, params, (err, cursor) =>
            cursor.toArray (err, items) =>
                cb err, if items?.length then (@constructModel(item, meta) for item in items) else []


    
    @find: (params, fnCursor, context, cb) ->
        meta = @__getMeta__()
        @_database.find meta.collection, params, (err, cursor) =>
            fnCursor cursor
            cursor.toArray (err, items) =>
                cb err, if items?.length then (@constructModel(item, meta) for item in items) else []    



    @getCursor: (params, context, cb) ->
        meta = @__getMeta__()
        @_database.find meta.collection, params, cb


           
    @getById: (id, context, cb) ->
        meta = @__getMeta__()
        @_database.findOne meta.collection, { _id: @_database.ObjectId(id) }, (err, result) =>
            cb err, if result then @constructModel(result, meta)
            
            
            
    @destroyAll: (params, cb) ->
        meta = @__getMeta__()
        if meta.validateMultiRecordOperationParams(params)
            @_database.remove meta.collection, params, (err) =>
                cb?(err)
        else
            cb? new AppError "Call to destroyAll() must pass safety checks on params.", "SAFETY_CHECK_FAILED_IN_DESTROYALL"
            
            
            
    @__getMeta__: ->
        meta = @_getMeta()
        meta.validateMultiRecordOperationParams ?= (params) -> 
            false
        meta



    @getLimit: (limit, _default, max) ->
        result = _default
        if limit
            result = limit
            if result > max
                result = max
        result        
        
        
        
    @constructModel: (obj, meta) ->
        if meta.initializer
            meta.initializer obj
        else
            result = {}
            for name, field of meta.fields
                value = obj[name]
                fieldDef = @getFullFieldDefinition field
                if @isCustomClass fieldDef.type
                    if value
                        result[name] = @constructModel value, fieldDef.type._getMeta()
                else
                    if value
                        if fieldDef.type is 'array'
                            arr = []
                            contentType = @getFullFieldDefinition fieldDef.contents
                            if @isCustomClass contentType
                                for item in value
                                    arr.push @constructModel item, contentType._getMeta()
                            else
                                arr = value
                            result[name] = arr
                        else
                            result[name] = value    
            if obj._id
                result._id = obj._id       
            new meta.type result
     
                
                
    @isCustomClass: (type) ->
        ['string', 'number', 'boolean', 'object', 'array', ''].indexOf(type) is -1                



    @getFullFieldDefinition: (def) ->
        #Convert short hands to full definitions.
        #eg: 'string' means { type: 'string', required: true }
        if typeof(def) isnt "object"
            fieldDef = {
                type: def,
                required: true
            }
        else 
            fieldDef = def

        if fieldDef.autoGenerated and (fieldDef.event is 'created' or fieldDef.event is 'updated')
            fieldDef.type = 'number'
            fieldDef.required = true

        #Required is true unless explicitly set.
        if not fieldDef.required?
            fieldDef.required = true    
            
        fieldDef
        
        
    
    save: (context, cb) =>
        meta = @constructor.__getMeta__()
        
        for fieldName, def of meta.fields
            if def.autoGenerated
                switch def.event
                    when 'created'
                        if not @_id?
                            @[fieldName] = Date.now()    
                    when 'updated'
                        @[fieldName] = Date.now()                            
        
        @validate (err, errors) =>
            if not errors.length
                fnSave = =>
                    @_updateTimestamp = Date.now()                
                    @_shard = if meta.generateShard? then meta.generateShard(@) else "1"
                    
                    if not @_id?
                        if meta.logging?.isLogged
                            event = {}
                            event.type = meta.logging.onInsert
                            event.data = this
                            @constructor._database.insert 'events', event, =>
                        
                        @constructor._database.insert meta.collection, @, (err, r) =>
                            cb? err, r
                    else
                        @constructor._database.update meta.collection, { _id: @_id }, @, (err, r) =>
                            cb? err, @
            
                if @_id and meta.concurrency is 'optimistic'
                    @constructor.getById @_id, context, (err, newPost) =>
                        if newPost._updateTimestamp is @_updateTimestamp
                            fnSave()
                        else
                            cb? new AppError "Update timestamp mismatch. Was #{newPost._updateTimestamp} in saved, #{@_updateTimestamp} in new.", 'OPTIMISTIC_CONCURRENCY_FAIL'
                else
                    fnSave()        
            else
                console.log "Validation failed for object with id #{@_id} in collection #{meta.collection}."
                for error in validation.errors
                    console.log error
                console.log "Error generated at #{Date().toString('yyyy-MM-dd')}."
                cb? new AppError "Model failed validation."


    
    validate: (cb) =>
        meta = @constructor.__getMeta__()
        (meta.validate ? @validateFields).call @, meta.fields, cb

        

    validateFields: (fields, cb) =>
        errors = []

        for fieldName, def of fields
            errors.concat @validateField(fieldName, def)
        
        if cb
            cb null, errors
        else
            errors
            

    validateField: (fieldName, def) =>
        errors = []

        value = @[fieldName]
        if not def.useCustomValidationOnly                
            fieldDef = BaseModel.getFullFieldDefinition(def)
            
            if fieldDef.required and not value
                errors.concat "#{fieldName} is required."
            
            #Check types.            
            if value
                if fieldDef.type is 'array'
                    for item in value
                        errors.concat @validateField item, '', null, fieldDef.contents
                else
                    #If it is a custom class
                    if (BaseModel.isCustomClass(fieldDef.type) and value.constructor isnt fieldDef.type) or (typeof(value) isnt fieldDef.type)
                        errors.concat "#{fieldName} should be a #{fieldDef.type}."                        

        if def.validate
            errors.concat def.validate.call @
        
        errors            
        

    
    destroy: (context, cb) =>
        meta = @constructor.__getMeta__()
        @constructor._database.remove meta.collection, { _id: @_id }, (err) =>
            cb? err, @



exports.BaseModel = BaseModel

