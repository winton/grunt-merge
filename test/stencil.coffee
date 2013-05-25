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
      grunt.util.deferred_spawn = (options) ->
        defer (resolve, reject) ->
          console.log(options)
      grunt.tasks([ 'stencil:merge' ])