// Generated by CoffeeScript 1.6.2
(function() {
  var AppError, BaseModel, Models, User, forumModule, utils,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  utils = require('../common/utils');

  Models = require('./');

  AppError = require('../common/apperror').AppError;

  BaseModel = require('./basemodel').BaseModel;

  forumModule = require('./forum');

  User = (function(_super) {
    var Summary, _ref;

    __extends(User, _super);

    User._getMeta = function() {
      return {
        type: User,
        collection: 'users',
        fields: {
          network: 'string',
          domain: {
            type: 'string',
            validate: function() {
              return ['twitter', 'fb', 'fora'].indexOf(this.domain) === -1;
            }
          },
          domainid: 'string',
          username: 'string',
          domainidType: {
            type: 'string',
            validate: function() {
              return ['username', 'domainid'].indexOf(this.domainidType) === -1;
            }
          },
          name: 'string',
          location: 'string',
          picture: 'string',
          thumbnail: 'string',
          email: 'string',
          accessToken: 'string',
          lastLogin: 'string',
          following: {
            type: 'array',
            contents: User.Summary,
            validate: function() {
              var x, _i, _len, _ref, _results;

              _ref = this.following;
              _results = [];
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                x = _ref[_i];
                _results.push(x.validate());
              }
              return _results;
            }
          },
          subscriptions: {
            type: 'array',
            contents: forumModule.Forum.Summary,
            validate: function() {
              var x, _i, _len, _ref, _results;

              _ref = this.subscriptions;
              _results = [];
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                x = _ref[_i];
                _results.push(x.validate());
              }
              return _results;
            }
          },
          about: 'string',
          createdAt: {
            autoGenerated: true,
            event: 'created'
          },
          updatedAt: {
            autoGenerated: true,
            event: 'updated'
          }
        },
        logging: {
          isLogged: true,
          onInsert: 'NEW_USER'
        }
      };
    };

    User.getOrCreateUser = function(userDetails, domain, network, accessToken, cb) {
      return User._models.Session.get({
        accessToken: accessToken,
        network: network
      }, {}, function(err, session) {
        if (err) {
          return cb(err);
        } else {
          if (session == null) {
            session = new User._models.Session({
              passkey: utils.uniqueId(24),
              accessToken: accessToken
            });
          }
          return User.get({
            domain: domain,
            username: userDetails.username,
            network: network
          }, {}, function(err, user) {
            var _ref, _ref1, _ref10, _ref11, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;

            if (user != null) {
              user.name = (_ref = userDetails.name) != null ? _ref : user.name;
              user.domainid = (_ref1 = userDetails.domainid) != null ? _ref1 : user.domainid;
              user.network = (_ref2 = userDetails.network) != null ? _ref2 : user.network;
              user.username = (_ref3 = userDetails.username) != null ? _ref3 : userDetails.domainid;
              user.domainidType = userDetails.username ? 'username' : 'domainid';
              user.location = (_ref4 = userDetails.location) != null ? _ref4 : user.location;
              user.picture = (_ref5 = userDetails.picture) != null ? _ref5 : user.picture;
              user.thumbnail = (_ref6 = userDetails.thumbnail) != null ? _ref6 : user.thumbnail;
              user.tile = (_ref7 = userDetails.tile) != null ? _ref7 : user.tile;
              user.email = (_ref8 = userDetails.email) != null ? _ref8 : 'unknown@poe3.com';
              user.lastLogin = Date.now();
              return user.save({}, function(err, u) {
                if (!err) {
                  session.userid = u._id.toString();
                  session.network = network;
                  return session.save({}, function(err, session) {
                    if (!err) {
                      return cb(null, u, session);
                    } else {
                      return cb(err);
                    }
                  });
                } else {
                  return cb(err);
                }
              });
            } else {
              user = new User();
              user.domain = domain;
              user.network = network;
              user.domainid = userDetails.domainid;
              user.username = (_ref9 = userDetails.username) != null ? _ref9 : userDetails.domainid;
              user.domainidType = userDetails.username ? 'username' : 'domainid';
              if (domain === 'fb') {
                user.facebookUsername = userDetails.username;
              }
              if (domain === 'tw') {
                user.twitterUsername = userDetails.username;
              }
              user.name = userDetails.name;
              user.location = userDetails.location;
              user.picture = userDetails.picture;
              user.thumbnail = userDetails.thumbnail;
              user.tile = (_ref10 = userDetails.tile) != null ? _ref10 : '/images/collection-tile.png';
              user.email = (_ref11 = userDetails.email) != null ? _ref11 : 'unknown@poe3.com';
              user.lastLogin = Date.now();
              user.preferences = {
                canEmail: true
              };
              user.createdAt = Date.now();
              return user.save({}, function(err, u) {
                var userinfo;

                if (!err) {
                  userinfo = new User._models.UserInfo();
                  userinfo.userid = u._id.toString();
                  userinfo.network = network;
                  return userinfo.save({}, function(err, _uinfo) {
                    if (!err) {
                      session.network = network;
                      session.userid = u._id.toString();
                      return session.save({}, function(err, session) {
                        if (!err) {
                          return cb(null, u, session);
                        } else {
                          return cb(err);
                        }
                      });
                    } else {
                      return cb(err);
                    }
                  });
                } else {
                  return cb(err);
                }
              });
            }
          });
        }
      });
    };

    User.getById = function(id, context, cb) {
      return User.__super__.constructor.getById.call(this, id, context, cb);
    };

    User.getByUsername = function(domain, username, context, cb) {
      return User.get({
        domain: domain,
        username: username
      }, context, function(err, user) {
        return cb(null, user);
      });
    };

    User.validateSummary = function(user) {
      var errors, field, required, _i, _len;

      errors = [];
      if (!user) {
        errors.push("Invalid user.");
      }
      required = ['id', 'domain', 'username', 'name'];
      for (_i = 0, _len = required.length; _i < _len; _i++) {
        field = required[_i];
        if (!user[field]) {
          errors.push("Invalid " + field);
        }
      }
      return errors;
    };

    function User(params) {
      this.summarize = __bind(this.summarize, this);
      this.save = __bind(this.save, this);
      this.getUrl = __bind(this.getUrl, this);
      var _ref, _ref1, _ref2;

      if ((_ref = this.about) == null) {
        this.about = '';
      }
      if ((_ref1 = this.karma) == null) {
        this.karma = 1;
      }
      if ((_ref2 = this.preferences) == null) {
        this.preferences = {};
      }
      this.following = [];
      this.followerCount = [];
      this.subscriptions = [];
      this.totalItemCount = 0;
      User.__super__.constructor.apply(this, arguments);
    }

    User.prototype.getUrl = function() {
      if (this.domain === 'tw') {
        return "/@" + this.username;
      } else {
        return "/" + this.domain + "/" + this.username;
      }
    };

    User.prototype.save = function(context, cb) {
      return User.__super__.save.apply(this, arguments);
    };

    User.prototype.summarize = function() {
      var summary;

      return summary = new Summary({
        id: this._id.toString(),
        domain: this.domain,
        username: this.username,
        name: this.name,
        network: this.network
      });
    };

    Summary = (function(_super1) {
      __extends(Summary, _super1);

      function Summary() {
        _ref = Summary.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      Summary._getMeta = function() {
        return {
          type: Summary,
          fields: {
            id: 'string',
            domain: 'string',
            username: 'string',
            name: 'string',
            network: 'string'
          }
        };
      };

      return Summary;

    })(BaseModel);

    User.Summary = Summary;

    return User;

  }).call(this, BaseModel);

  exports.User = User;

}).call(this);
