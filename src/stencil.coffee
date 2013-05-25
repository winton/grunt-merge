for key, value of require('./stencil/common')
  eval("var #{key} = value;")

module.exports = (grunt) ->
  config = grunt.config("stencil") || {}
  config = grunt.file.readJSON(config.json || "stencil.json")

  grunt.util.deferred_spawn = (options) ->
    defer (resolve, reject) ->
      grunt.util.spawn(
        _.extend(opts: stdio: "inherit", options)
        (error, result, code) ->
          if error
            reject(error)
          else
            resolve(result, code)
      )

  grunt.registerTask("stencil:merge", "Merge template branches.", ->
    promise = Q.when()

    _.each config, (value, key) =>
      promise.then(
        grunt.util.deferred_spawn(
          cmd : "git"
          args: [ "checkout", key ]
        )
      ).then(
        grunt.util.deferred_spawn(
          cmd : "git"
          args: [ "merge", "master" ]
        )
      ).then(
        Q.all(
          _.map value, (branch) ->
            grunt.util.deferred_spawn(
              cmd : "git"
              args: [ "merge", branch ]
            ).then(
              grunt.util.deferred_spawn(
                cmd : "git"
                args: [ "push", key ]
              )
            )
        )
      ).then(
        -> grunt.log.success("Merge complete.")
        -> grunt.log.error("Please fix the conflict and run `grunt stencil:merge` again.")
      )
  )

  grunt.registerTask("stencil:pull", "Update project from template.", ->)
    
  grunt.registerTask("stencil:push", "Push commit(s) to template.", ->)

  grunt.task.registerTask('stencil', [ 'stencil:pull' ])