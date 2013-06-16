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
      cmd_stub = sinon.stub grunt.util, "cmd", (cmd) ->
        Q.resolve(cmd)

      checkout_cmd_stub = sinon.stub grunt.util, "checkoutCmd", (branch) ->
        console.log("stub", "git checkout #{branch}")
        Q.resolve("git checkout #{branch}")

      grunt.tasks [ 'stencil:merge' ], {}, ->
        _.flatten(cmd_stub.args).should.eql([
          'git fetch --all'
          'git checkout a'
          'git pull origin a'
          'git checkout a-b'
          'git merge a'
          'git push a-b'
          'git checkout b'
          'git pull origin b'
          'git checkout a-b'
          'git merge b'
          'git push a-b'
        ])

        grunt.util.cmd.restore()
        grunt.util.checkoutCmd.restore()
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
        grunt.tasks(
          [ 'stencil:merge' ]
          'offline': true 
          -> done()
        )
      )