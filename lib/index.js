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
    for (var fileName in metadata) {
        if (metadata.hasOwnProperty(fileName)) {
            var pattern = createPattern(fileName, metadata[fileName].watch);
            files.push(pattern);
        }
    }
    config.sprockets_map = metadata;
    files.push(createPattern(tmpobj.name, false));
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
        var mappedAsset = config.sprockets_map[file.originalPath]
        if (mappedAsset == undefined) {
            log.debug("Skipping %s because it's not sprockets mapped", file.originalPath);
            done(content);
            return;
        }
        var url = 'http://localhost:9292/assets/' + mappedAsset.logical_path;
        log.debug('Processing "%s" as %s.', file.originalPath, url);
        http.get(url, function (res) {
            if (res.statusCode < 200 || res.statusCode > 299) {
                var exception = new OpalException("Unable to process " + file.originalPath + " HTTP response - " + res.statusCode + " - " + res.statusMessage);
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
