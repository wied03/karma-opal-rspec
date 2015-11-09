// Karma configuration
// Generated on Mon Nov 09 2015 15:27:11 GMT-0700 (MST)

// TODO: Put this in a separate file/require/module commonjs it/etc.

var execSync = require('exec-sync');
var opalProcessor = function(args, config, logger,helper) {
    config = config || {};

    var log = logger.create('preprocessor.opal');
    
    var defaultOptions = {};
    
    var options = helper.merge(defaultOptions, args.options || {}, config.options || {});

    var transformPath = args.transformPath || config.transformPath || function(filepath) {
        return filepath.replace(/\.rb$/, '.js');
    };
    
    return function(content,file,done) {
        log.debug('Processing "%s".', file.originalPath);
        var compiled = execSync("bundle exec opal -c "+command);
        
        file.path = transformPath(file.originalPath);
        
        done(compiled);
    };
};

opalProcessor.$inject = ['args','config.opalPreprocessor', 'logger', 'helper'];
// module.exports = {
//     'preprocessor:opal': ['factory', opalProcessor]
// };

module.exports = function(config) {
  config.set({

    // base path that will be used to resolve all patterns (eg. files, exclude)
    basePath: '',


    // frameworks to use
    // available frameworks: https://npmjs.org/browse/keyword/karma-adapter
    frameworks: ['jasmine'],

    // list of files / patterns to load in the browser
    files: [
      'test/**/*spec.rb'
    ],


    // list of files to exclude
    exclude: [
    ],


    // preprocess matching files before serving them to the browser
    // available preprocessors: https://npmjs.org/browse/keyword/karma-preprocessor
    preprocessors: {
      '**/*.rb': ['opal']
    },
    plugins: [
      'karma-jasmine',
      'karma-chrome-launcher',
      {'preprocessor:opal': ['factory', opalProcessor]}
    ],


    // test results reporter to use
    // possible values: 'dots', 'progress'
    // available reporters: https://npmjs.org/browse/keyword/karma-reporter
    reporters: ['progress'],


    // web server port
    port: 9876,


    // enable / disable colors in the output (reporters and logs)
    colors: true,


    // level of logging
    // possible values: config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
    logLevel: config.LOG_INFO,


    // enable / disable watching file and executing tests whenever any file changes
    autoWatch: true,


    // start these browsers
    // available browser launchers: https://npmjs.org/browse/keyword/karma-launcher
    browsers: ['Chrome'],


    // Continuous Integration mode
    // if true, Karma captures browsers, runs the tests and exits
    singleRun: false,

    // Concurrency level
    // how many browser should be started simultanous
    concurrency: Infinity
  })
}
