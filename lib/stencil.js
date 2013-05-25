(function() {
  var key, value, _ref;

  _ref = require('./stencil/common');
  for (key in _ref) {
    value = _ref[key];
    eval("var " + key + " = value;");
  }

  module.exports = function(grunt) {
    var config;

    config = grunt.config("stencil") || {};
    config = grunt.file.readJSON(config.json || "stencil.json");
    grunt.util.deferred_spawn = function(options) {
      return defer(function(resolve, reject) {
        return grunt.util.spawn(_.extend({
          opts: {
            stdio: "inherit"
          }
        }, options), function(error, result, code) {
          if (error) {
            return reject(error);
          } else {
            return resolve(result, code);
          }
        });
      });
    };
    grunt.registerTask("stencil:merge", "Merge template branches.", function() {
      var promise,
        _this = this;

      promise = Q.when();
      return _.each(config, function(value, key) {
        return promise.then(grunt.util.deferred_spawn({
          cmd: "git",
          args: ["checkout", key]
        })).then(grunt.util.deferred_spawn({
          cmd: "git",
          args: ["merge", "master"]
        })).then(Q.all(_.map(value, function(branch) {
          return grunt.util.deferred_spawn({
            cmd: "git",
            args: ["merge", branch]
          }).then(grunt.util.deferred_spawn({
            cmd: "git",
            args: ["push", key]
          }));
        }))).then(function() {
          return grunt.log.success("Merge complete.");
        }, function() {
          return grunt.log.error("Please fix the conflict and run `grunt stencil:merge` again.");
        });
      });
    });
    grunt.registerTask("stencil:pull", "Update project from template.", function() {});
    grunt.registerTask("stencil:push", "Push commit(s) to template.", function() {});
    return grunt.task.registerTask('stencil', ['stencil:pull']);
  };

}).call(this);

/*
//@ sourceMappingURL=stencil.js.map
*/