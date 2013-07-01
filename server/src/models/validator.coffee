utils = require('../common/utils')
console = require 'console'
AppError = require('../common/apperror').AppError

class Validator

    constructor: ->
        
        

    validate: (model, fields, cb) =>
        errors = []

        for fieldName, def of fields
            errors.concat (fieldDef.validate ? @validateField)(model[fieldName], fieldName, model, fieldDef)
                
                

    validateField: (value, fieldName, model, def) =>
        if not def.skipValidation
            errors = []

            #Convert short hands to full definitions.
            if ['string', 'number', 'boolean', 'object'].indexOf(def) isnt -1
                fieldDef = {
                    type: def,
                    required: true
                }
            else if def is 'array'
                fieldDef = {
                    type: 'array',
                    required: true
                }
            else if def.autoGenerated and (def.event is 'created' or def.event is 'updated')
                fieldDef = {
                    type: 'number',
                    required: true
                }
            else
                fieldDef = def

        
            if not @isCustomType fieldDef.type
                if fieldDef.required and not value
                    errors.push "#{fieldName} is required."
                
                switch fieldDef.type
                    when '' then break                        
                    when 'array'
                        for item in value
                            @validateField item, '', null, fieldDef.contents
                    else
                        if typeof(value) isnt fieldDef.type
                            _errors.push "#{fieldName} should be a #{fieldDef.type}."                    
            else            
                errors.concat value.validate?()
            
            return errors
                
            

    isCustomClass: (type) ->
        ['string', 'number', 'boolean', 'object', 'array', ''].indexOf(type) is -1

exports.Validator = Validator