// Generated by CoffeeScript 1.6.2
(function() {
  var Models, k, models, modules, v;

  modules = {
    session: 'Session',
    user: 'User',
    forum: 'Forum',
    post: 'Post',
    token: 'Token',
    userinfo: 'UserInfo',
    message: 'Message',
    network: 'Network',
    itemview: 'ItemView',
    comment: 'Comment',
    article: 'Article'
  };

  models = {};

  for (k in modules) {
    v = modules[k];
    models[v] = require("./" + k)[v];
  }

  Models = (function() {
    function Models(dbconf) {
      this.dbconf = dbconf;
      for (k in models) {
        v = models[k];
        this[k] = v;
        this.initModel(v);
      }
    }

    Models.prototype.initModel = function(model) {
      model._database = new (require('../common/database')).Database(this.dbconf);
      return model._models = this;
    };

    return Models;

  })();

  exports.Models = Models;

}).call(this);