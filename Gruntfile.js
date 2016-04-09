module.exports = function(grunt) {

  grunt.loadNpmTasks('grunt-mocha-test');
  grunt.loadNpmTasks('grunt-livescript');

  grunt.initConfig({
    mochaTest: {
      test: {
        options: {
          reporter: 'spec',
          require: 'LiveScript'
        },
        src: ['test/**/*.ls']
      }
    },
    livescript: {
      src: {
        files: {
          'lib/io/file-system-provider.js': 'src/io/file-system-provider.ls',
          'lib/io/virtual-path.js': 'src/io/virtual-path.ls',
          'lib/parsing/expression-parser.js': 'src/parsing/expression-parser.ls',
          'lib/parsing/full-parser.js': 'src/parsing/full-parser.ls',
          'lib/parsing/parser-utilities.js': 'src/parsing/parser-utilities.ls',
          'lib/parsing/statement-parser.js': 'src/parsing/statement-parser.ls',
          'lib/parsing/text-parser.js': 'src/parsing/text-parser.ls',
          'lib/compiler.js': 'src/compiler.ls',
          'lib/lazor.js': 'src/lazor.ls',
          'lib/transpiler.js': 'src/transpiler.ls',
          'lib/view-engine.js': 'src/view-engine.ls'
        }
      }
    }
  });

  grunt.registerTask('default', ['mochaTest', 'livescript']);
  grunt.registerTask('test', 'mochaTest');

};
