# Ensure filenames are using the name defined in package.json.
# https://github.com/jdavis/grunt-rename

module.exports = (grunt) ->

  grunt.config.data.rename =
    bin_path:
      src : "bin/grunt-merge"
      dest: "bin/<%= pkg.name %>"
    src_directory:
      src : "src/grunt-merge"
      dest: "src/<%= pkg.name %>"
    src_path:
      src : "src/grunt-merge.coffee"
      dest: "src/<%= pkg.name %>.coffee"
    test_directory:
      src : "test/grunt-merge"
      dest: "test/<%= pkg.name %>"
    test_path:
      src : "test/grunt-merge.coffee"
      dest: "test/<%= pkg.name %>.coffee"

  grunt.loadNpmTasks "grunt-rename"