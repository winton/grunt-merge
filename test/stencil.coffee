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

  run = (cmds...) ->
    _.inject(
      cmds
      (promise, cmd) ->
        promise.then(grunt.util.cmd(cmd))
      Q.resolve()
    )

  setupGit = ->
    chdirToFixture()
    run(
      "rm -rf .git"
      "git init ."
      "git add ."
      "git commit -a -m \"First\""
      "git branch a"
      "git branch b"
    )

  beforeEach(chdirToFixture)
  beforeEach(loadTasks)

  describe 'util', ->
    describe 'branches', ->
      beforeEach (done) ->
        setupGit().then(-> done())

      it 'should return branches', (done) ->
        grunt.util.branches().then (branches) ->
          branches.should.eql([ 'a', 'b', 'master' ])
          done()

  describe 'merge', ->
    it 'should execute the correct commands', (done) ->
      stub = sinon.stub grunt.util, "cmd", (cmd) ->
        Q.resolve(cmd)

      grunt.tasks [ 'stencil:merge' ], {}, ->
        _.flatten(stub.args).should.eql([
          'git branch'
          'git fetch --all'
          'git checkout -t origin/a'
          'git pull origin a'
          'git checkout -t origin/a-b'
          'git merge a'
          'git push a-b'
          'git checkout -t origin/b'
          'git pull origin b'
          'git checkout -t origin/a-b'
          'git merge b'
          'git push a-b'
        ])

        grunt.util.cmd.restore()
        done()

    it 'should merge', (done) ->
      run("rm hello.txt").then(->
        setupGit()
      ).then(->
        run("git checkout a")
      ).then(->
        fs.writeFileSync("hello.txt", "hello")
        run(
          "git add ."
          "git commit -m \"Hello\""
        )
      ).then(->
        grunt.tasks [ 'stencil:merge' ], {}, -> done()
      )