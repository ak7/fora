recordModule = require('./record')
utils = require('../lib/utils')
Q = require('../lib/q')
models = require('./')

class Conversation extends recordModule.Record
    
    @describeType: {
            type: @,
            inherits: recordModule.Record,
            name: 'conversation',
            description: 'Conversation',
            fields: {
                content: { type: 'string', required: false, maxLength: 50000 },
            }
        }



    constructor: (params) ->
        @type ?= 'conversation'
        super



    getView: (name = "standard") =>
        switch name
            when "snapshot"
                {
                } 
            when "card"
                {
                }
    


exports.Conversation = Conversation
