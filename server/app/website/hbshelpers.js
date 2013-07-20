// Generated by CoffeeScript 1.6.3
(function() {
  exports.register = function() {
    var forumcard, fs, hbs, postcard;
    hbs = require('hbs');
    hbs.registerHelper('userUrl', function(user) {
      if (user.domain === 'tw') {
        return "/@" + user.username;
      } else {
        return "/" + user.domain + "/" + user.username;
      }
    });
    hbs.registerHelper('userFeedUrl', function(user) {
      if (user.domain === 'tw') {
        return "/@" + user.username + "/feed";
      } else {
        return "/" + user.domain + "/" + user.username + "/feed";
      }
    });
    hbs.registerHelper('equals', function(v1, v2, options) {
      if (v1 === v2) {
        return options.fn(this);
      } else {
        return options.inverse(this);
      }
    });
    hbs.registerHelper('formatComment', function(comment, type) {
      var content;
      if (type === 'text') {
        content = comment.data;
        content = content.replace(/[\n]{3,}/g, "\n\n");
        content = content.replace(/\n/g, "<br />");
        return "<div class=\"author\"><img src=\"" + comment.createdBy.thumbnail + "\" alt=\"" + comment.createdBy.name + "\" /> <span class=\"name\">" + comment.createdBy.name + "</span></div>            <div class=\"content\">" + content + "</div>";
      } else {
        return "Unsupported comment type.";
      }
    });
    fs = require('fs');
    postcard = fs.readFileSync(__dirname + '/views/posts/postcard.hbs', 'utf8');
    hbs.registerPartial('postcard', postcard);
    forumcard = fs.readFileSync(__dirname + '/views/forums/forumcard.hbs', 'utf8');
    return hbs.registerPartial('forumcard', forumcard);
  };

}).call(this);
