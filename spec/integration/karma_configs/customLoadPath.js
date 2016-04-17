// Karma configuration
// Generated on Mon Nov 09 2015 15:27:11 GMT-0700 (MST)

process.env.OPAL_LOAD_PATH = 'src_dir'

module.exports = function (config) {
    config.set({

        // base path that will be used to resolve all patterns (eg. files, exclude)
        basePath: '',

        // frameworks to use
        // available frameworks: https://npmjs.org/browse/keyword/karma-adapter
        frameworks: ['opal_rspec'],

        // list of files / patterns to load in the browser
        files: [],

        middleware: ['webpack'],

        webpack: {
            entry: ['./entry_point.js'],
            module: {
                loaders: [
                    {
                        test: /\.rb$/,
                        loader: 'opal-webpack'
                    }
                ]
            }
        },

        // list of files to exclude
        exclude: [],

        // test results reporter to use
        // possible values: 'dots', 'progress'
        // available reporters: https://npmjs.org/browse/keyword/karma-reporter
        reporters: ['progress', 'orspec-modified-json'],

        specjsonReporter: {
            outputFile: 'test_run.json'
        },

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
        browsers: ['PhantomJS2'],


        // Continuous Integration mode
        // if true, Karma captures browsers, runs the tests and exits
        singleRun: false,

        // Concurrency level
        // how many browser should be started simultanous
        concurrency: Infinity
    })
}
