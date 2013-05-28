for key, value of require('./stencil/common')
  eval("var #{key} = value;")

module.exports = (grunt) ->
  config = grunt.config("stencil") || {}
  config = grunt.file.readJSON(config.json || "stencil.json")

  grunt.util.branches = ->
    grunt.util.cmd("git branch").then(
      (output) ->
        output.split(/[\s\*]+/).slice(1)
    )

  grunt.util.cmd = (cmd) ->
    cmd = cmd.split(/\s+/)

    defer (resolve, reject) ->
      grunt.util.spawn(
        cmd : cmd.shift()
        args: cmd
        (error, result, code) ->
          if error
            reject(error)
          else
            resolve(result.toString(), code)
      )

  grunt.registerTask("stencil:merge", "Merge template branches.", ->
    branches = []
    done     = @async()

    promise = grunt.util.branches().then(
      (values) -> branches = values
    )

    cmds = [ "git fetch --all" ]

    cmds = cmds.concat _.map(
      config
      (value, key) =>
        _.map value, (branch) ->
          [
            "git checkout -t origin/#{branch}"
            "git pull origin #{branch}"

            if branches.indexOf(branch) > -1
              "git checkout #{key}"
            else
              "git checkout -t origin/#{key}"
            
            "git merge #{branch}"
            "git push #{key}"
          ]
    )

    _.each(
      _.flatten(cmds)
      (cmd) ->
        promise = promise.then(grunt.util.cmd(cmd))
    )

    promise.then(
      -> grunt.log.success("Merge complete.")
      -> grunt.log.error("Please fix the conflict and run `grunt stencil:merge` again.")
    ).fin(done)
  )

  grunt.task.registerTask("stencil:pull", "Update project from template.", ->)
  grunt.task.registerTask("stencil:push", "Push commit(s) to template.", ->)
  grunt.task.registerTask('stencil', [ 'stencil:pull' ])