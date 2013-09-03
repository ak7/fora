utils = require '../common/utils'
BaseModel = require('./basemodel').BaseModel
Q = require('../common/q')
hasher = require('../common/hasher').hasher

emailRegex = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/

class User extends BaseModel
    
    
    @describeModel: ->
        {
            type: @,
            collection: 'users',
            fields: {
                username: 'string',
                name: 'string',
                location: 'string',
                picture: 'string',
                thumbnail: 'string',
                email: { type: 'string', validate: -> emailRegex.test(@email) },
                accessToken: { type: 'string', required: false },
                lastLogin: 'number',
                assetPath: 'string',
                following: { type: 'array', contents: @getModels().User.Summary },
                subscriptions: { type: 'array', contents: @getModels().Forum.Summary },            
                about: { type: 'string', required: false },
                createdAt: { autoGenerated: true, event: 'created' },
                updatedAt: { autoGenerated: true, event: 'updated' }            
            },
            logging: {
                isLogged: true,
                onInsert: 'NEW_USER'
            }
        }
       

   
    @create: (userDetails, authInfo, context, db) ->
        (Q.async =>
            #We can't create a new user with an existing username.
            username = userDetails.username
            user = yield User.get { username }, context, db

            if not user
                user = new User { username: userDetails.username }
                user.updateFrom userDetails
                user = yield user.save context, db
                
                #Also create a userinfo
                userinfo = new (@getModels().UserInfo) {
                    userid: user._id.toString(),
                    username: user.username
                }
                userinfo = yield userinfo.save context, db
                
                credentials = new (@getModels().Credentials) {
                    userid: user._id.toString(),
                    username,
                    token: utils.uniqueId(24)                    
                }

                switch authInfo.type
                    when 'builtin'
                        result = yield Q.nfcall(hasher, { plaintext: authInfo.value.password })
                        salt = result.salt.toString 'hex'
                        hash = result.key.toString 'hex'
                        credentials.builtin = { method: 'PBKDF2', username, hash, salt }
                    when 'twitter'
                        credentials.twitter = authInfo.value
                
                credentials = yield credentials.save context, db                
                { success: true, user, token: credentials.token }            
            else
                { success: false, error: new Error "User already exists" }
        )()
            

                                                        
    
    @getByUsername: (username, context, db) ->
        User.get({ username }, context, db)



    constructor: (params) ->
        super
        @about ?= ''
        @karma ?= 1
        @preferences ?= {}
        @following ?= []
        @followerCount ?= []
        @subscriptions ?= []
        @totalItemCount ?= 0



    getUrl: =>
        "/~#{@username}"



    save: (context, db) =>
        if not @_id
            super(context, db)
                .then (user) =>               
                    userinfo = new (@getModels().UserInfo) {
                        userid: user._id.toString(),
                        username: user.username                        
                    }  
                    userinfo.save(context, db)
                        .then =>
                            user
        else
            super        
            
            
            
    updateFrom: (userDetails) =>
        @name = userDetails.name
        @location = userDetails.location
        @picture = userDetails.picture
        @thumbnail = userDetails.thumbnail
        @tile = userDetails.tile ? '/images/collection-tile.png'
        @email = userDetails.email ? 'unknown@foraproject.org'
        @lastLogin = Date.now()
        @preferences = { canEmail: true }
        @about = userDetails.about

        #Allow dev scripts to set assetPath for initial set of users, so that it stays the same.
        if userDetails.createdVia is 'internal' and userDetails.assetPath
            @assetPath = userDetails.assetPath    
        else
            createdAt = new Date
            @assetPath = "/pub/assetpaths/#{createdAt.getFullYear()}-#{createdAt.getMonth()+1}-#{createdAt.getDate()}"        



    summarize: =>        
       new Summary {
            id: @_id.toString()
            username: @username
            name: @name,
            @assetPath
        }

    
class Summary extends BaseModel    
    @describeModel: ->
        {
            type: @,
            fields: {
                id: 'string',
                username: 'string',
                name: 'string',
                assetPath: 'string'
            }
        }
            
User.Summary = Summary                
exports.User = User
