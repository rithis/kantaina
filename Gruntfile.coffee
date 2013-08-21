module.exports = (grunt) ->
  grunt.initConfig
    simplemocha:
      kantaina: "test/kantaina.coffee"
      coverage: src: "test/*.coffee", options: reporter: "travis-cov"
      coveralls: src: "test/*.coffee", options: reporter: "mocha-lcov-reporter"
      options: reporter: process.env.REPORTER or "spec"
    coffeelint:
      lib: "lib/**/*.coffee"
      test: "test/**/*.coffee"
      grunt: "Gruntfile.coffee"
    coffeeCoverage: lib: src: "lib", dest: "lib", options: path: "relative"
    clean: coffeeCoverage: "lib/**/*.js"
    coffee:
      options:
        bare: true
      lib:
        files:
          "build/index.js": "lib/index.coffee"

  grunt.loadNpmTasks "grunt-simple-mocha"
  grunt.loadNpmTasks "grunt-coffeelint"
  grunt.loadNpmTasks "grunt-coffee-coverage"
  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-contrib-coffee"

  grunt.registerTask "default", [
    "coffeeCoverage:lib"
    "simplemocha:kantaina"
    "clean:coffeeCoverage"
    "coffeelint"
    "simplemocha:coverage"
    "coffee"
  ]

  grunt.registerTask "coveralls", [
    "coffeeCoverage:lib"
    "simplemocha:coveralls"
    "clean:coffeeCoverage"
  ]
