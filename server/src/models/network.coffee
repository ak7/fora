ForaDbModel = require('./foramodel').ForaDbModel
models = require('./')

class Network extends ForaDbModel

    @describeType: {
        type: @,
        collection: 'networks',
        fields: {
            name: 'string',
            stub: 'string',
            domains: { type: 'array', contentType: 'string' },
            templates: '',
            defaultTemplates: ''
        },
        logging: {
            onInsert: 'NEW_USER'
        }
    }


    constructor: (params) ->
        @templates = {}
        super
        


    getLayout: (name) =>
        name = name ? 'default'
        @templates.layouts?[name] ? @defaultTemplates.layouts[name]

        
            
    getView: (namespace, view) =>
        @templates.views?[namespace]?[view] ? @defaultTemplates.views[namespace][view]
            

exports.Network = Network
