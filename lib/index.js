var child_process = require('child_process');
var spawn = child_process.spawn;
var fs = require('fs');
var tmp = require('tmp');
var getTestMetadata = require('./getMetadata');
var preprocessor = require('./sprocketsPreprocessor');
var opalSourceMap = require('./opalSourceMap');

var createPattern = function (path, watch) {
    return {pattern: path, included: true, served: true, watched: watch};
};

var initOpal = function (files, logger, config) {
    var testPatterns = [];
    files.forEach(function (file) {
        testPatterns.push(file.pattern);
    });
    // clear out because we will replace the file list with a sprockets driven list anyways
    files.length = 0;
    var log = logger.create('init.opal');
    var env = Object.create(process.env);
    env.PATTERN = testPatterns;
    env.OPAL_LOAD_PATH = config.opalLoadPaths || [];
    log.debug('Launching Rack server to handle sprockets/assets');
    var rack = spawn('bundle', ['exec', 'rackup', `${__dirname}/rack_server.ru`], {stdio: 'inherit', env: env});
    config.opalRackServer = {
        baseUrl: "http://localhost:9292",
        assetsUrl: "http://localhost:9292/assets"
    };
    process.on('exit', function () {
        rack.kill('SIGINT');
    });

    var metadata = getTestMetadata(config, log);
    var fileList = metadata.fileList;
    for (var fileName in fileList) {
        if (fileList.hasOwnProperty(fileName)) {
            var pattern = createPattern(fileName, fileList[fileName].watch);
            files.push(pattern);
        }
    }
    config.sprocketsMap = fileList;
    config.sprocketsSrcMap = {};
    config.sprocketsSrcMapSourcesMap = {};
    var tmpobj = tmp.fileSync({prefix: 'opalTestRequires', postfix: '.js'});
    fs.writeFileSync(tmpobj.name, metadata.testRequires);
    files.push(createPattern(tmpobj.name, false));
    files.push(createPattern(`${__dirname}/runner.js`, false));
    // a default preprocessor, need forward slash to catch absolute paths for opal and opal-rspec GEMs
    config.preprocessors['/**/*'] = ['sprockets'];
};

initOpal.$inject = ['config.files', 'logger', 'config'];

module.exports = {
    'framework:opal': ['factory', initOpal]
};
Object.assign(module.exports, preprocessor, opalSourceMap);
