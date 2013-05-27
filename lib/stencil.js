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
    grunt.util.branches = function() {
      return grunt.util.cmd("git branch").then(function(output) {
        return output.split(/[\s\*]+/);
      });
    };
    grunt.util.cmd = function(cmd) {
      cmd = cmd.split(/\s+/);
      return defer(function(resolve, reject) {
        return grunt.util.spawn({
          cmd: cmd.shift(),
          args: cmd,
          opts: {
            stdio: "inherit"
          }
        }, function(error, result, code) {
          if (error) {
            return reject(error);
          } else {
            return resolve(result, code);
          }
        });
      });
    };
    grunt.registerTask("stencil:merge", "Merge template branches.", function() {
      var branches, cmds, done, promise,
        _this = this;

      branches = [];
      done = this.async();
      promise = grunt.util.branches().then(function(values) {
        return branches = values;
      });
      cmds = ["git fetch --all"];
      cmds = cmds.concat(_.map(config, function(value, key) {
        return _.map(value, function(branch) {
          return ["git checkout -t origin/" + branch, "git pull origin " + branch, branches.indexOf(branch) > -1 ? "git checkout " + key : "git checkout -t origin/" + key, "git merge " + branch, "git push " + key];
        });
      }));
      _.each(_.flatten(cmds), function(cmd) {
        return promise = promise.then(grunt.util.cmd(cmd));
      });
      return promise.then(function() {
        return grunt.log.success("Merge complete.");
      }, function() {
        return grunt.log.error("Please fix the conflict and run `grunt stencil:merge` again.");
      }).fin(done);
    });
    grunt.task.registerTask("stencil:pull", "Update project from template.", function() {});
    grunt.task.registerTask("stencil:push", "Push commit(s) to template.", function() {});
    return grunt.task.registerTask('stencil', ['stencil:pull']);
  };

}).call(this);

/*
//@ sourceMappingURL=stencil.js.map
*/