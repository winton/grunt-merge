for key, value of require("../lib/stencil/common")
  eval("var #{key} = value;")

path  = require("path")
grunt = require("grunt")

describe 'stencil', ->
  describe 'merge', ->

    setup = ->
      process.chdir(path.resolve(__dirname, "fixture"))
      grunt.loadTasks(path.resolve(__dirname, "../lib"))

    beforeEach(setup)

    before (done) ->
      setup()
      grunt.util.cmd("rm -rf .git").then(
        grunt.util.cmd("git init .")
      ).then(
        -> done()
      )

    it 'should merge', (done) ->
      cmds = []
      
      grunt.util.cmd = (cmd) ->
        cmds.push(cmd)
        Q.resolve(cmd)

      grunt.tasks [ 'stencil:merge' ], {}, ->
        cmds.should.eql(
          [
            'git branch',
            'git fetch --all',
            'git checkout -t origin/a',
            'git pull origin a',
            'git checkout -t origin/a-b',
            'git merge a',
            'git push a-b',
            'git checkout -t origin/b',
            'git pull origin b',
            'git checkout -t origin/a-b',
            'git merge b',
            'git push a-b'
          ]
        )
        done()

    it 'should return branches', (done) ->
      grunt.util.branches().then(
        (branches) ->
          console.log(branches)
          done()
      )