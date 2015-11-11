var tmp = require('tmp');
var child_process = require('child_process');
var spawn = child_process.spawn;

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

    // we need a valid path for these
    log.debug("Getting metadata from Sprockets");
    var tmpobj = tmp.fileSync({postfix: '.js'});
    var metadata = JSON.parse(child_process.execSync(`bundle exec ruby ${__dirname}/get_metadata.rb ${pattern} ${tmpobj.name}`).toString());
    for (var fileName in metadata) {
        if (metadata.hasOwnProperty(fileName)) {
            var pattern = createPattern(fileName, metadata[fileName].watch);
            files.push(pattern);
        }
    }
    config.sprockets_map = metadata;
    config.sprockets_src_map = {};
    files.push(createPattern(tmpobj.name, false));
    files.push(createPattern(`${__dirname}/runner.js`, false));
    // a default preprocessor, need forward slash to catch absolute paths for opal and opal-rspec GEMs
    config.preprocessors['/**/*'] = ['sprockets'];
    config.middleware = ['opal_sourcemap'];
};

initOpal.$inject = ['config.files', 'logger', 'config'];

var preprocessor = require('./sprocketsPreprocessor');
var opalSourceMap = require('./opalSourceMap');

module.exports = {
    'framework:opal': ['factory', initOpal],
};
Object.assign(module.exports, preprocessor, opalSourceMap);
