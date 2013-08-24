conf = require '../../conf'
db = new (require '../../common/database').Database(conf.db)
models = require '../../models'
AppError = require('../../common/apperror').AppError
Q = require('../../common/q')

class Controller        

    ensureSession: (args, fn) =>
        [req, res, next] = args 
        (Q.async =>
            user = yield @getUserWithToken(req.query.token ? req.cookies.token)
            if user
                req.user = user
                fn()
            else
                res.send { error: 'NO_SESSION' }
        )()



    attachUser: (args, fn) =>
        [req, res, next] = args
        (Q.async =>
            user = yield @getUserWithToken(req.query.token ? req.cookies.token)
            req.user = user
            fn()
        )()



    getUserWithToken: (token) =>
        (Q.async => 
            if token
                credentials = yield models.Credentials.get({ token }, {}, db)
                user = yield credentials.getUser({}, db)
                user?.summarize()                
            else
                null)()
        

    
    isAdmin: (user) =>
        (u for u in conf.admins when u.username is user?.username).length        
                
                
        
    getValue: (src, field, safe = true) =>
        src[field]
        
    
    
    handleError: (onError) ->
        (fn) ->
            return ->
                if arguments[0]
                    onError arguments[0]
                else
                    fn.apply undefined, arguments
    
    
    
    setValues: (target, src, fields, options = {}) =>
    
        if not options.safe?
            options.safe = true
        if not options.ignoreEmpty
            options.ignoreEmpty = true

        setValue = (src, targetField, srcField) =>
            val = @getValue src, srcField, options.safe
            if options.ignoreEmpty
                if val?
                    target[field] = val
            else
                target[field] = val

        if fields.constructor == Array
            for field in fields
                setValue src, field, field
        else
            for ft, fsrc of fields
                setValue src, ft, fsrc
                


exports.Controller = Controller
