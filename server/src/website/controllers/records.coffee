controller = require './controller'
conf = require '../../conf'
db = new (require '../../common/data/database').Database(conf.db)
models = require '../../models'
utils = require '../../common/utils'
Q = require('../../common/q')

class Records extends controller.Controller
    

    item: (req, res, next) =>
        @attachUser arguments, =>
            (Q.async =>
                try                
                    collection = yield models.Collection.get({ stub: req.params.collection, network: req.network.stub }, {}, db)
                    record = yield models.Record.get({ 'collection.id': collection._id.toString(), stub: (req.params.stub) }, {}, db)
                    author = yield models.User.getById record.createdBy.id, {}, db

                    res.render req.network.getView('recordtypes', record.constructor.getTypeDefinition().name), { 
                        record: record,
                        formatted: record.getFormattedFields(),
                        recordJson: JSON.stringify(record),
                        author,
                        user: req.user,
                        collection,
                        editable: req.user?.id is author._id.toString(),
                        pageName: 'record-page', 
                        pageType: 'std-page', 
                    }
                    
                catch e
                    next e)()
            
        
            
exports.Records = Records
