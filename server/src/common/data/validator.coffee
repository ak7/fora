typeUtil = require('./typeutil')

class Validator

    @validate: (obj, modelDescription) ->   
        errors = []
        
        if not modelDescription.useCustomValidationOnly
            for fieldName, def of modelDescription.fields                
                @addError errors, fieldName, @validateField(obj, obj[fieldName], fieldName, def)

            if modelDescription.validate
                customValidationResults = modelDescription.validate.call obj
                return if customValidationResults?.length then errors.concat customValidationResults else errors
            else
                return errors
        else
            if modelDescription.validate
                customValidationResults = modelDescription.validate.call obj
                return if customValidationResults?.length then customValidationResults else []
            else
                return []
    
    
    
    @validateField: (obj, value, fieldName, def) ->
        errors = []

        if not def.useCustomValidationOnly                
            fieldDef = typeUtil.getTypeDefinition(def)

            if fieldDef.required and not value?
                errors.push "#{fieldName} is #{JSON.stringify value}"
                errors.push "#{fieldName} is required."
            
            #Check types.       
            if value
                if fieldDef._type is 'array'
                    for item in value                        
                        @addError errors, fieldName, @validateField(obj, item, "[#{fieldName} item]", fieldDef._contentType)
                else
                    #If it is a custom class or a primitive
                    if fieldDef._type isnt ''                        
                        if (typeUtil.isUserDefinedType(fieldDef._type) and not (value instanceof fieldDef._type)) or (not typeUtil.isUserDefinedType(fieldDef._type) and typeof(value) isnt fieldDef._type)
                            errors.push "#{fieldName} is #{JSON.stringify value}"
                            errors.push "#{fieldName} should be a #{fieldDef._type}."

                    if typeUtil.isUserDefinedType(fieldDef._type) and value.validate
                        errors = errors.concat value.validate()
                    else
                        #We should also check for objects inside object. (ie, do we have fields inside the fieldDef?)
                        if fieldDef.fields
                            errors =  errors.concat @validate value, fieldDef
        
        if value and fieldDef.validate
            @addError errors, fieldName, fieldDef.validate.call obj
            
        errors            
        

    
    @addError: (list, fieldName, error) ->
        if error is true
            return list
        if error is false
            list.push "#{fieldName} is invalid."
            return list
        if error instanceof Array
            if error.length > 0
                for item in error
                    @addError list, fieldName, item
            return list
        if error
            list.push error
            return list



exports.Validator = Validator
        
