for key, value of require("../lib/grunt-merge/common")
  eval("var #{key} = value;")

path  = require("path")
grunt = require("grunt")
sinon = require("sinon")

describe 'grunt-merge', ->

  chdirToFixture = ->
    process.chdir(path.resolve(__dirname, "fixture"))

  loadTasks = ->
    grunt.loadTasks(path.resolve(__dirname, "../lib"))

  runTask = (task) ->
    [ promise, resolve ] = defer()

    grunt.tasks(
      [ task ]
      'offline': true 
      -> resolve()
    )

    promise

  setupGit = ->
    chdirToFixture()
    Q.resolve().then(->
      grunt.util.cmd("rm a.txt")  if fs.existsSync("a.txt")
    ).then(->
      grunt.util.cmd("rm b.txt")  if fs.existsSync("b.txt")
    ).then(->
      grunt.util.cmds(
        "rm -rf .git"
        "git init ."
        "git add ."
        "git commit -a -m \"First\""
        "git branch a"
        "git branch b"
        "git checkout a"
      )
    ).then(->
      fs.writeFileSync("a.txt", "a")
      grunt.util.cmds(
        "git add ."
        "git commit -m \"a\""
      )
    ).then(->
      grunt.util.cmds("git checkout b")
    ).then(->
      fs.writeFileSync("b.txt", "b")
      grunt.util.cmds(
        "git add ."
        "git commit -m \"b\""
      )
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
        Q.resolve("git checkout #{branch}")

      grunt.tasks [ 'grunt-merge:merge' ], {}, ->
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
      setupGit().then(->
        runTask('grunt-merge:merge')
      ).then(->
        grunt.util.cmds("git checkout master")
      ).then(->
        fs.existsSync("a.txt").should.eql(false)
        fs.existsSync("b.txt").should.eql(false)
      ).then(->
        grunt.util.cmds("git checkout a")
      ).then(->
        fs.existsSync("a.txt").should.eql(true)
        fs.existsSync("b.txt").should.eql(false)
      ).then(->
        grunt.util.cmds("git checkout b")
      ).then(->
        fs.existsSync("a.txt").should.eql(false)
        fs.existsSync("b.txt").should.eql(true)
      ).then(->
        grunt.util.cmds("git checkout a-b")
      ).then(->
        fs.existsSync("a.txt").should.eql(true)
        fs.existsSync("b.txt").should.eql(true)
        done()
      )

    it 'should exit on conflict', (done) ->
      console_output = []

      setupGit().then(->
        grunt.util.cmds("git checkout a")
      ).then(->
        fs.writeFileSync("b.txt", "a")
        grunt.util.cmds(
          "git add ."
          "git commit -m \"conflict\""
        )
      ).then(->
        sinon.stub console, "log", (str...) ->
          console_output.push(str)
        sinon.stub grunt.log, "error", (str...) ->
          console_output.push(str)

        runTask('grunt-merge:merge')
      ).then(->
        console.log.restore()
        grunt.log.error.restore()

        console_output = _.flatten(console_output).join()
        console_output.indexOf(
          "Command failed: git merge b"
        ).should.be.above(-1)
      ).then(-> done())