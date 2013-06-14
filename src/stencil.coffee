for key, value of require('./stencil/common')
  eval("var #{key} = value;")

module.exports = (grunt) ->
  config = grunt.config("stencil") || {}
  config = grunt.file.readJSON(config.json || "stencil.json")

  grunt.util.branches = ->
    grunt.util.cmd("git branch -a").then(
      (output) ->
        output.split(/[\s\*]+/).slice(1)
    )

  grunt.util.checkoutCmd = (branch, create_from) ->
    grunt.util.branches().then (branches) ->
      if branches.indexOf(branch) > -1
        "git checkout #{branch}"
      else if branches.indexOf("origin/#{branch}") > -1
        "git checkout -t origin/#{branch}"
      else if create_from
        [
          grunt.util.checkoutCmd(create_from)
          "git branch #{branch}"
        ]
      else
        throw "Cannot checkout branch that does not exist"

  grunt.util.cmd = (cmd) ->
    [ promise, resolve, reject ] = defer()

    og   = cmd
    args = cmd.split(/\s+/)
    cmd  = args.shift()

    grunt.util.spawn(
      cmd : cmd
      args: args
      (error, result, code) ->
        if error
          console.log("#{og}\n")
          grunt.log.error(result)
          console.log("")

          reject(error)
        else
          resolve(result.toString(), code)
    )

    promise

  grunt.registerTask("stencil:merge", "Merge template branches.", ->
    branches = []
    done     = @async()
    promise  = grunt.util.cmd("git fetch --all")

    _.each config, (value, key) =>
      promise = promise.then(->
        grunt.util.checkoutCmd(key, value[0])
      ).then (co_key) ->
        _.each value, (branch) ->
          grunt.util.checkoutCmd(branch).then (co_branch) ->
            _.inject(
              [
                co_branch
                "git pull origin #{branch}"
                co_key
                "git merge #{branch}"
                "git push #{key}"
              ]
              (promise, cmd) -> grunt.util.cmd(cmd)
              promise
            )

    promise.then(
      -> grunt.log.success("Merge complete.")
      -> grunt.log.error("Please fix the conflict and run `grunt stencil:merge` again.")
    ).fin(done)
  )

  grunt.task.registerTask("stencil:pull", "Update project from template.", ->)
  grunt.task.registerTask("stencil:push", "Push commit(s) to template.", ->)
  grunt.task.registerTask('stencil', [ 'stencil:pull' ])