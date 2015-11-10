var tmp = require('tmp');
var child_process = require('child_process');
var http = require('http');

var createPattern = function (path, watch) {
    return {pattern: path, included: true, served: true, watched: watch};
};

var initOpal = function (files, preprocessors, logger, config) {
    var log = logger.create('init.opal');

    // we need a valid path for these
    log.debug("Getting metadata from Sprockets");
    var tmpobj = tmp.fileSync({postfix: '.js'});
    var metadata = JSON.parse(child_process.execSync("bundle exec ruby lib/get_metadata.rb spec/**/*_spec.rb " + tmpobj.name).toString());
    metadata.forEach(function (fileInfo) {
        var pattern = createPattern(fileInfo.filename, fileInfo.watch);
        files.push(pattern);
    });
    config.sprockets_map = metadata;
    files.push(createPattern(__dirname + '/karma_formatter.rb', false));
    files.push(createPattern(__dirname + '/runner.js', false));
    // a default preprocessor, need forward slash to catch absolute paths for opal and opal-rspec GEMs
    preprocessors['/**/*'] = ['sprockets'];
};

initOpal.$inject = ['config.files', 'config.preprocessors', 'logger', 'config'];

function OpalException(message) {
    this.message = message;
    this.name = "OpalException";
}

var sprocketsProcessor = function (args, config, logger, helper) {
    config = config || {};

    var log = logger.create('preprocessor.sprockets');

    var defaultOptions = {};

    var options = helper.merge(defaultOptions, args.options || {}, config.options || {});

    return function (content, file, done) {
        log.debug('Processing "%s".', file.originalPath);
        // TODO: Based on the physical filename, get the logical path from sprockets_map so that it can be fetched
        console.log('config');
        console.dir(config.sprockets_map);
        http.get('http://localhost:9292/' + file, function (res) {
            if (res.statusCode < 200 || res.statusCode > 299) {
                var exception = new OpalException("Unable to process " + file.originalPath + " HTTP response - "+res.statusCode+" - " + res.statusMessage);
                log.error(exception.message);
                done(exception, null);
                return;
            }
            var js = "";
            res.on('data', function (chunk) {
                js += chunk.toString();
            });
            res.on('end', function () {
                done(js);
            });
        }).on('error', function (error) {
            var exception = new OpalException("Unable to process " + file.originalPath + " exception - " + error);
            log.error(exception.message);
            done(exception, null);
        });
    };
};

sprocketsProcessor.$inject = ['args', 'config', 'logger', 'helper'];

module.exports = {
    'framework:opal': ['factory', initOpal],
    'preprocessor:sprockets': ['factory', sprocketsProcessor]
};
