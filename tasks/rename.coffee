# Ensure filenames are using the name defined in package.json.
# https://github.com/jdavis/grunt-rename

module.exports = (grunt) ->

  grunt.config.data.rename =
    bin_path:
      src : "bin/stencil"
      dest: "bin/<%= pkg.name %>"
    src_directory:
      src : "src/stencil"
      dest: "src/<%= pkg.name %>"
    src_path:
      src : "src/stencil.coffee"
      dest: "src/<%= pkg.name %>.coffee"
    test_directory:
      src : "test/stencil"
      dest: "test/<%= pkg.name %>"
    test_path:
      src : "test/stencil.coffee"
      dest: "test/<%= pkg.name %>.coffee"

  grunt.loadNpmTasks "grunt-rename"