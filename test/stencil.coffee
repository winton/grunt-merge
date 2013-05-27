for key, value of require("../lib/stencil/common")
  eval("var #{key} = value;")

path  = require("path")
grunt = require("grunt")

describe 'stencil', ->
  describe 'merge', ->
    before ->
      process.chdir(path.resolve(__dirname, "fixture"))
      grunt.loadTasks(path.resolve(__dirname, "../lib"))

    it 'should merge', ->
      cmds = []
      
      grunt.util.cmd = (cmd) ->
        cmds.push(cmd)
        Q.resolve(cmd)

      grunt.tasks([ 'stencil:merge' ])
      console.log(cmds)