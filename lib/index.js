var child_process = require('child_process');
var spawn = child_process.spawn;
var httpSync = require('urllib-sync').request;
var fs = require('fs');
var tmp = require('tmp');

var createPattern = function (path, watch) {
    return {pattern: path, included: true, served: true, watched: watch};
};

var initOpal = function (files, logger, config) {
    var pattern = files.pop().pattern;
    var log = logger.create('init.opal');
    var env = Object.create(process.env);
    env.PATTERN = pattern;
    var rack = spawn('bundle', ['exec', 'rackup', `${__dirname}/rack_server.ru`], {stdio: 'inherit', env: env});
    process.on('exit', function (code) {
        rack.kill('SIGINT');
    });

    var metadataResponse;
    while (true) {
        log.debug("Getting metadata from Sprockets");
        try {
            // TODO: hard coded hostname/port and rename get_metadata to something more specific
            // TODO: Can we make this async, will Karma be OK??
            metadataResponse = httpSync("http://localhost:9292/assets/get_metadata.js.erb", {timeout: 30000});
            break;
        }
        catch(e) {
            log.debug("Server not up yet");
        }
    }

    var metadata = JSON.parse(metadataResponse.data.toString());
    for (var fileName in metadata) {
        if (metadata.hasOwnProperty(fileName)) {
            var pattern = createPattern(fileName, metadata[fileName].watch);
            files.push(pattern);
        }
    }
    config.sprockets_map = metadata;
    config.sprockets_src_map = {};
    var tmpobj = tmp.fileSync({prefix: 'opalTestRequires', postfix: '.js'});
    // TODO: Hard coded hostname
    var testRequiresResponse = httpSync('http://localhost:9292/assets/opalTestRequires.js.erb');
    fs.writeFileSync(tmpobj.name, testRequiresResponse.data.toString());
    files.push(createPattern(tmpobj.name, false));
    files.push(createPattern(`${__dirname}/runner.js`, false));
    // a default preprocessor, need forward slash to catch absolute paths for opal and opal-rspec GEMs
    config.preprocessors['/**/*'] = ['sprockets'];
    config.middleware = config.middleware || [];
    config.middleware.push('opal_sourcemap');
};

initOpal.$inject = ['config.files', 'logger', 'config'];

var preprocessor = require('./sprocketsPreprocessor');
var opalSourceMap = require('./opalSourceMap');

module.exports = {
    'framework:opal': ['factory', initOpal],
};
Object.assign(module.exports, preprocessor, opalSourceMap);
