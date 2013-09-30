utils = require '../common/utils'
mdparser = require('../common/lib/markdownutil').marked
DatabaseModel = require('../common/data/databasemodel').DatabaseModel
models = require('./')
Q = require('../common/q')

class Post extends DatabaseModel
    
    @describeType: {
        type: @,
        collection: 'posts',
        discriminator: (obj) -> if obj.type is 'article' then models.Article else Post
        fields: {
            type: 'string',
            forum: { type: models.Forum.Summary },
            createdBy: { type: models.User.Summary },
            meta: { type: 'array', contentType: 'string' },
            tags: { type: 'array', contentType: 'string' },
            stub: { type: 'string' },
            recommendations: { type: 'array', contentType: models.User.Summary },            
            state: { type: 'string', $in: ['draft','published'] },
            savedAt: { type: 'number' },
            createdAt: { autoGenerated: true, event: 'created' },
            updatedAt: { autoGenerated: true, event: 'updated' }
        },
        trackChanges: true,
        logging: {
            onInsert: 'NEW_POST'
        }
    }


    @search: (criteria, settings, context, db) =>
        limit = @getLimit settings.limit, 100, 1000
                
        params = {}
        for k, v of criteria
            params[k] = v
        
        Post.find params, ((cursor) -> cursor.sort(settings.sort).limit limit), context, db
        

        
    @getLimit: (limit, _default, max) ->
        result = _default
        if limit
            result = limit
            if result > max
                result = max
        result    


    
    constructor: (params) ->
        super
        @recommendations ?= []
        @meta ?= []
        @tags ?= []
        @rating ?= 1
        @createdAt ?= Date.now()
        
    
    
    addMetaList: (metaList) =>
        (Q.async =>
            @meta = @meta.concat (m for m in metaList when @meta.indexOf(m) is -1)
            yield @save()
        )()
        


    removeMetaList: (metaList) =>
        (Q.async =>
            @meta = (m for m in @meta when metaList.indexOf(m) is -1)
            yield @save()
        )()

        
    
    getFormattedFields: =>
        result = {}
        typeDesc = @getTypeDefinition()
        for entry in typeDesc.formattedFields
            { field, format } = entry
            result[field] = @formatData @[field], @[format]
        result
            


    formatData: (data, format) =>  
        switch format
            when 'markdown'
                if data then mdparser data else ''
            when 'html', 'text'
                data
            else
                'Invalid format.'
            
    
    
    save: (context, db) =>
        { context, db } = @getContext context, db
        
        (Q.async =>        
            if not @_id            
                typeDesc = @getTypeDefinition()
                if typeDesc.stub
                    @stub = @[typeDesc.stub].toLowerCase().trim().replace(/\s+/g,'-').replace(/[^a-z0-9|-]/g, '').replace(/^\d*/,'')
                    #check if the stub exists
                    post = yield Post.get({ @stub, 'forum.id': @forum.id }, context, db)
                    if post
                        @stub = @_id.toString() + "-" + @stub
                    result = yield super(context, db)               
                else                    
                    @stub = utils.uniqueId()
                    post = yield super(context, db)
                    @stub = post._id.toString()
                    result = yield post.save context, db
            else
                #check if the stub exists, if the stub has changed.
                if @stub isnt @getOriginalModel().stub
                    post = yield Post.get({ @stub, 'forum.id': @forum.id }, context, db)
                    if post
                        @stub = @_id.toString() + "-" + @stub

                result = yield super(context, db)
                
            if @state is 'published'
                forum = yield models.Forum.getById @forum.id, context, db
                forum.refreshSnapshot()
            
            return result)()

        
            
exports.Post = Post
