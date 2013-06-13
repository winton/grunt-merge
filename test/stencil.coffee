for key, value of require("../lib/stencil/common")
  eval("var #{key} = value;")

path  = require("path")
grunt = require("grunt")
sinon = require("sinon")

describe 'stencil', ->

  chdirToFixture = ->
    process.chdir(path.resolve(__dirname, "fixture"))

  loadTasks = ->
    grunt.loadTasks(path.resolve(__dirname, "../lib"))

  setupGit = ->
    chdirToFixture()
    _.inject(
      [
        "git init ."
        "git add ."
        "git commit -a -m \"First\""
        "git branch a"
        "git branch b"
      ]
      (promise, cmd) ->
        promise.then(grunt.util.cmd(cmd))
      grunt.util.cmd("rm -rf .git")
    )

  beforeEach(chdirToFixture)
  beforeEach(loadTasks)

  describe 'util', ->
    describe 'branches', ->
      it 'should return branches', (done) ->
        setupGit().then(
          grunt.util.branches
        ).then (branches) ->
          branches.should.eql([ 'a', 'b', 'master' ])
          done()

  describe 'merge', ->
    it 'should execute the correct commands', (done) ->
      cmds = []
      
      stub = sinon.stub grunt.util, "cmd", (cmd) ->
        cmds.push(cmd)
        Q.resolve(cmd)

      grunt.tasks [ 'stencil:merge' ], {}, ->
        stub.args.should.eql(
          [
            [ 'git branch' ]
            [ 'git fetch --all' ]
            [ 'git checkout -t origin/a' ]
            [ 'git pull origin a' ]
            [ 'git checkout -t origin/a-b' ]
            [ 'git merge a' ]
            [ 'git push a-b' ]
            [ 'git checkout -t origin/b' ]
            [ 'git pull origin b' ]
            [ 'git checkout -t origin/a-b' ]
            [ 'git merge b' ]
            [ 'git push a-b' ]
          ]
        )

        grunt.util.cmd.restore()
        done()