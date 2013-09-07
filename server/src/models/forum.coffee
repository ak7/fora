BaseModel = require('../common/data/basemodel').BaseModel
DatabaseModel = require('../common/data/databasemodel').DatabaseModel
ExtendedField = require('../common/data/databasemodel').ExtendedField
Q = require('../common/q')
models = require('./')

class Forum extends DatabaseModel

    class Settings extends BaseModel
        @describeType: {
            type: @,
            fields: {
                comments: {
                    type: 'object',
                    required: false,
                    fields: {
                        enabled: { type: 'boolean', required: false },
                        opened: { type: 'boolean', required: false }
                    }
                }
            }
        }    
            
    @Settings: Settings            
        
    class Summary extends BaseModel    
        @describeType: {
            type: @,
            fields: {
                id: 'string',
                network: 'string',
                name: 'string',
                stub: 'string',
                createdBy: models.User.Summary
            }
        }    
            
    @Summary: Summary
            
            
    class ExtendedForumField extends ExtendedField
    
        @describeType: @mergeModelDescription { 
            type: @, 
            collection: 'extendedfields' 
        }, ExtendedField.describeType
        
            
    @describeType: {
        type: @,
        collection: 'forums',
        fields: {
            network: 'string',
            name: 'string',
            stub: 'string',
            type: { type: 'string', validate: -> ['public', 'protected', 'private'].indexOf(@type) isnt -1 },
            settings: { type: Settings },
            icon: 'string',
            iconThumbnail: 'string',
            cover: { type: 'string', required: false },
            createdBy: { type: models.User.Summary },
            snapshot: 'object',
            stats: {
                type: 'object',
                fields: {
                    posts: 'number',
                    members: 'number',
                    lastPost: 'number'
                }
            },
            createdAt: { autoGenerated: true, event: 'created' },
            updatedAt: { autoGenerated: true, event: 'updated' }
        },
        extendedFieldPrefix: 'Forum',
        extendedFieldType: ExtendedForumField,
        trackChanges: true,
        logging: {
                onInsert: 'NEW_FORUM'
        }
    }
        
        
        
    save: (context, db) =>        
        if not @_id
            @stats ?= {
                posts: 0,
                members: 1,
                lastPost: 0
            }
            @snapshot ?= { posts: [] }
        
        super


        
    summarize: =>        
        summary = new Summary {
            id: @_id.toString()
            network: @network,
            name: @name,
            stub: @stub,
            createdBy: @createdBy
        }
        
        
        
    getView: (name = "standard") =>
        switch name
            when 'card'
                {
                    id: @_id.toString()
                    @network,
                    @name,
                    @stub,
                    @createdBy,
                    @snapshot,
                    image: @icon
                }



    join: (user, token, context, db) => 
        { context, db } = @getContext context, db
        (Q.async =>
            if @type is 'public'
                yield @addRole user, 'member', context, db
            else
                throw new Error "Access denied"
        )()
        
        

    getPosts: (limit, sort, context, db) =>
        { context, db } = @getContext context, db
        (Q.async =>
            yield models.Post.find({ 'forum.stub': @stub, 'forum.network': @network }, ((cursor) -> cursor.sort(sort).limit limit), context, db)
        )()
        

    
    addRole: (user, role, context, db) =>
        { context, db } = @getContext context, db
        
        (Q.async =>
            membership = yield models.Membership.get { 'forum.id': @_id.toString(), 'user.id': user.id }, context, db
            if not membership
                membership = new (models.Membership) {
                    forum: @summarize(),
                    user: user,
                    roles: [role]
                }
            else
                if membership.roles.indexOf(role) is -1 
                    membership.roles.push role
            yield membership.save context, db   
        )()
                


    removeRole: (user, role, context, db) =>
        { context, db } = @getContext context, db
        
        (Q.async =>
            membership = yield models.Membership.get { 'forum.id': @_id.toString(), 'user.id': user.id }, context, db
            membership.roles = (r for r in membership.roles when r isnt role)
            yield if membership.roles.length then membership.save() else membership.destroy()
        )()
                
    
                                
    getMemberships: (roles, context, db) =>
        { context, db } = @getContext context, db
        (Q.async =>
            yield models.Membership.find { 'forum.id': @_id.toString(), roles: { $in: roles } }, ((cursor) -> cursor.sort({ id: -1 }).limit 200), context, db
        )()        
        
                
            
    refreshSnapshot: (context, db) =>
        { context, db } = @getContext context, db
        (Q.async =>
            posts = yield models.Post.find({ 'forum.id': @_id.toString() , state: 'published' }, ((cursor) -> cursor.sort({ _id: -1 }).limit 10), context, db)
            @snapshot = { posts: p.getView("snapshot") for p in posts }
            if posts.length
                @stats.lastPost = posts[0].publishedAt
            yield @save context, db)()
            
    
exports.Forum = Forum
