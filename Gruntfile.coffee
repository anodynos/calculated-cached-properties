module.exports = (grunt)->
  gruntConfig =
    urequire:
      _all:
        dependencies:
          paths: bower: true
          shim: true
        template: banner: true
        clean: true

      _defaults: # for lib
        main: 'CalculatedCachedProperties'
        path: 'source/code'
        resources: [ 'inject-version' ]
        runtimeInfo: false
        noLoaderUMD: true
        warnNoLoaderUMD: false
        template: name: 'UMDplain'

      dev:
        dstPath: 'build/dev'

      min:
        dstPath: 'build/min'
        optimize: true # 'uglify2': output: { beautify: true, compress: false, mangle: false }

        resources: [
          [ '+remove:debug', [/./],
            (m)-> m.replaceCode c for c in [
              'if (_this.constructor.isDebug()){}'
              'if (this.constructor.isDebug()){}'
            ]
          ]

          [ '%save with different name', ['CalculatedCachedProperties.js' ],
           (m)->
              m.dstFilename = 'CalculatedCachedProperties-min.js' # save under this name
              m.converted     # return m.converted, leaving file content intact
          ]
        ]

      spec:
        derive: [] # only from all
        path: 'source/spec'
        dstPath: 'build/spec'
        dependencies: imports:
          lodash: ['_']
          'calculated-cached-properties': ['CalculatedCachedProperties']
          chai: 'chai'
          'uberscore': ['_B']
          specHelpers: 'spH'
        resources: [
          ['import-keys',
            specHelpers: """
              equal, notEqual, ok, notOk, tru, fals, deepEqual, notDeepEqual, exact, notExact, iqual,
              notIqual, ixact, notIxact, like, notLike, likeBA, notLikeBA, equalSet, notEqualSet"""
            chai: 'expect' ]

          [ '+inject-_B.logger', ['**/*.js'],
            (m)-> m.beforeBody = "var l = new _B.Logger('#{m.dstFilename}');" ]
        ]
        afterBuild: require('urequire-ab-specrunner')

      specDev:
        derive: ['spec']
        dstPath: 'build/spec_combined/index-combined.js'
        template: name: 'combined'

      specWatch:
        derive: ['spec']
        afterBuild: [[null], require('urequire-ab-specrunner').options
          specRunners: [ 'mocha-cli' ]
          watch: true
          #mochaOptions: '-R dot'
        ]

  splitTasks = (tasks)-> if (tasks instanceof Array) then tasks else tasks.split(/\s/).filter((f)->!!f)
  grunt.registerTask shortCut, "urequire:#{shortCut}" for shortCut of gruntConfig.urequire
  grunt.registerTask shortCut, splitTasks tasks for shortCut, tasks of {
    default: 'develop'
    release: 'dev specDev min specDev' # always in pairs of `lib spec`
    develop: 'dev specWatch'
  }
  grunt.loadNpmTasks task for task of grunt.file.readJSON('package.json').devDependencies when task.lastIndexOf('grunt-', 0) is 0
  grunt.initConfig gruntConfig
