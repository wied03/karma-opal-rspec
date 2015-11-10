// Karma configuration
// Generated on Mon Nov 09 2015 15:27:11 GMT-0700 (MST)

var opalFramework = require('./lib/index.js');

var http = require('http');
var querystring = require('querystring');
var opalSourceMap = function (config) {
    return function (request, response, next) {
        if (request.url.endsWith(".map") && request.url.indexOf("foo") != -1) {
            //var requestedFilePath = querystring.unescape(request.url)
            //    .replace(config.urlRoot, '/')
            //    .replace(/\?.*$/, '')
            //    .replace(/^\/absolute/, '')
            //    .replace(/^\/base/, config.basePath);
            //var sourceMapUrl = config.sprockets_src_map[requestedFilePath];
            var sourceMapUrl = "http://localhost:9292/__OPAL_SOURCE_MAPS__/foo.self.map";
            console.log("fetching source maps from "+sourceMapUrl);
            http.get(sourceMapUrl, function (sprocketsResponse) {
                response.writeHead(sprocketsResponse.statusCode, sprocketsResponse.headers);
                var rawSourceMap = "";
                sprocketsResponse.on('data', function (chunk) {
                    rawSourceMap += chunk.toString();
                });
                sprocketsResponse.on('end', function () {
                    var asJson = JSON.parse(rawSourceMap);
                    asJson.sources = ["/ruby/base/spec/foo.rb"];
                    asJson.file = "/base/spec/foo.js";
                    var asString = JSON.stringify(asJson);
                    console.log("end of source map "+asString);
                    response.end(asString);
                });
            });
        }
        else {
            next();
        }
    };
};

module.exports = function (config) {
    config.set({

        // base path that will be used to resolve all patterns (eg. files, exclude)
        basePath: '',


        // frameworks to use
        // available frameworks: https://npmjs.org/browse/keyword/karma-adapter
        frameworks: ['opal'],

        // list of files / patterns to load in the browser
        files: [],


        // list of files to exclude
        exclude: [],

        middleware: ['opal_sourcemap'],

        proxies: {
            '/ruby/base/spec/': 'http://localhost:9292/__OPAL_SOURCE_MAPS__/'
        },

        // preprocess matching files before serving them to the browser
        // available preprocessors: https://npmjs.org/browse/keyword/karma-preprocessor
        // TODO: https://github.com/karma-runner/karma/blob/master/test/unit/preprocessor.spec.js
        // PR to include {dot: true} on mm call

        plugins: [
            opalFramework,
            'karma-chrome-launcher',
            {'middleware:opal_sourcemap': ['factory', opalSourceMap]}
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
