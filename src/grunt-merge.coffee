for key, value of require('./grunt-merge/common')
  eval("var #{key} = value;")

module.exports = (grunt) ->
  config = grunt.config("merge") || {}

  grunt.util.branches = (current=false) ->
    grunt.util.cmd("git branch -a").then(
      (output) ->
        if current
          output.match(/\*\s+(.+)/)[1]
        else
          output.split(/[\s\*]+/).slice(1)
    )

  grunt.util.checkoutCmd = (branch, create_from) ->
    grunt.util.branches().then (branches) ->
      if branches.indexOf(branch) > -1
        "git checkout #{branch}"
      else if branches.indexOf("origin/#{branch}") > -1
        "git checkout -t origin/#{branch}"
      else if create_from
        grunt.util.checkoutCmd(create_from).then (co) ->
          [
            co
            "git branch #{branch}"
            "git checkout #{branch}"
          ]
      else
        throw "Cannot checkout branch that does not exist"

  grunt.util.cmd = (cmd) ->
    return Q.resolve(@last_result)  if @last_cmd == cmd
    [ promise, resolve, reject ] =  defer()

    og   = cmd
    args = cmd.split(/\s+/)
    cmd  = args.shift()

    grunt.util.spawn(
      cmd : cmd
      args: args

      (error, result, code) =>
        error  = error.toString()   if error
        result = result.toString()  if result

        if error
          grunt.log.error("Command failed: #{og}")
          grunt.log.error(result)  if result
          grunt.log.error(error)   if error
          console.log("")

          reject(error)
        else
          if grunt.option('debug')
            grunt.log.ok(result)  if result

          @last_cmd    = og
          @last_code   = code
          @last_result = result

          resolve(result, code)
    )

    promise

  grunt.util.cmds = (cmds...) ->
    unless cmds instanceof Array
      cmds = [ cmds ]

    _.inject(
      _.flatten(cmds)
      (promise, cmd) ->
        promise.then(-> grunt.util.cmd(cmd))
      Q.resolve()
    )

  grunt.registerTask("merge", "Merge branches.", ->
    done     = @async()
    promise  = grunt.util.cmd("git fetch --all").then(=>
      grunt.util.branches(true)
    ).then (branch) =>
      @return_branch = branch

    _.each config, (value, key) ->
      promise = _.inject(
        value
        (promise, branch) =>
          promise.then(=>
            grunt.util.checkoutCmd(key, value[0])
          ).then((co) =>
            @co_key = co
            grunt.util.checkoutCmd(branch, key)
          ).then((co) =>
            grunt.util.cmds(co)
          ).then(=>
            unless grunt.option('offline')
              grunt.util.cmd("git pull origin #{branch}")
          ).then(=>
            grunt.util.cmds(@co_key, "git merge #{branch}")
          ).then(=>
            unless grunt.option('offline')
              grunt.util.cmd("git push origin #{key}")
          )
        promise
      )

    promise.then(=>
      grunt.util.checkoutCmd(@return_branch)
    ).then((co) =>
      grunt.util.cmds(co)
    ).then(
      -> grunt.log.success("Merge complete.")
      (e) ->
        grunt.util.cmds("git status").then((output) ->
          grunt.log.error(
            "Please resolve error and run `grunt merge` again."
          )
          console.log("\n#{output}")
        )
    ).fin(done)
  )