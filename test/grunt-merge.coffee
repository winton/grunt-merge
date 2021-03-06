for key, value of require("../lib/grunt-merge/common")
  eval("var #{key} = value;")

path  = require("path")
grunt = require("grunt")
sinon = require("sinon")

describe 'grunt-merge', ->

  chdirToFixture = ->
    fixture_path = path.resolve(__dirname, "fixture")
    fs.mkdirSync(fixture_path)  unless fs.existsSync(fixture_path)
    process.chdir(fixture_path)

  loadTasks = ->
    grunt.config.data.merge = "a-b": [ "a", "b" ]
    grunt.loadTasks(path.resolve(__dirname, "../lib"))

  runTask = (task, offline=true) ->
    [ promise, resolve ] = defer()

    grunt.tasks(
      [ task ]
      'offline': offline 
      -> resolve()
    )

    promise

  setupGit = ->
    fixture_path = path.resolve(__dirname, "fixture")

    grunt.util.cmd("rm -rf #{fixture_path}").then(->
      chdirToFixture()
      fs.writeFileSync("Gruntfile.coffee", "module.exports = (grunt) ->")
    ).then(->
      grunt.util.cmds(
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
      branches_stub = sinon.stub grunt.util, "branches", (current) ->
        if current
          Q.resolve("master")
        else
          Q.resolve("")

      cmd_stub = sinon.stub grunt.util, "cmd", (cmd) ->
        Q.resolve(cmd)

      checkout_cmd_stub = sinon.stub grunt.util, "checkoutCmd", (branch) ->
        Q.resolve("git checkout #{branch}")

      runTask('merge', false).then(->
        _.flatten(cmd_stub.args).should.eql([
          'git fetch --all'
          'git checkout a'
          'git pull origin a'
          'git checkout a-b'
          'git merge a'
          'git push origin a-b'
          'git checkout b'
          'git pull origin b'
          'git checkout a-b'
          'git merge b'
          'git push origin a-b'
          'git checkout master'
        ])

        grunt.util.branches.restore()
        grunt.util.cmd.restore()
        grunt.util.checkoutCmd.restore()
      ).fin(-> done())

    it 'should merge', (done) ->
      setupGit().then(->
        runTask('merge')
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

        runTask('merge')
      ).then(->
        console.log.restore()
        grunt.log.error.restore()

        console_output = _.flatten(console_output).join()
        console_output.indexOf(
          "Command failed: git merge b"
        ).should.be.above(-1)
      ).then(-> done())