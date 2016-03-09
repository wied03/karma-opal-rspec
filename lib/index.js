const child_process = require('child_process');
const spawn = child_process.spawn;
const fs = require('fs');
const tmp = require('tmp');
const getTestMetadata = require('./getMetadata');
const preprocessor = require('./sprocketsPreprocessor');
const opalSourceMap = require('./opalSourceMap');

const createPattern = function (path, watch) {
    return {pattern: path, included: true, served: true, watched: watch};
};

const initOpal = function (files, logger, config) {
    const testPatterns = [];
    files.forEach(function (file) {
        testPatterns.push(file.pattern);
    });
    // clear out because we will replace the file list with a sprockets driven list anyways
    files.length = 0;
    const log = logger.create('init.opal');
    const env = Object.create(process.env);
    env.PATTERN = testPatterns;
    config.opal = config.opal || {};
    const opalConfig = config.opal;
    env.OPAL_LOAD_PATH = opalConfig.loadPaths || [];
    // using empty string to force default path to be supplied in opal-rspec if not supplied here
    env.OPAL_DEFAULT_PATH = opalConfig.defaultPath || '';
    env.OPAL_ROLL_UP = opalConfig.rollUp || [];
    env.MRI_REQUIRES = opalConfig.mriRequires || [];
    log.debug('Launching Rack server to handle sprockets/assets');
    const stdioSetting = log.isLevelEnabled('debug') ? 'inherit' : 'ignore';
    const rack = spawn('bundle', ['exec', 'rackup', '-I', __dirname, `${__dirname}/rack_server.ru`], {
        stdio: stdioSetting,
        env: env
    });
    config.opalRackServer = {
        baseUrl: 'http://localhost:9292',
        assetsUrl: 'http://localhost:9292/assets'
    };
    process.on('exit', function () {
        rack.kill('SIGINT');
    });

    const metadata = getTestMetadata(config, log);
    const fileList = metadata.fileList;
    for (const fileName in fileList) {
        if (fileList.hasOwnProperty(fileName)) {
            const pattern = createPattern(fileName, fileList[fileName].watch);
            files.push(pattern);
        }
    }
    config.sprocketsMap = fileList;
    config.sprocketsSrcMap = {};
    config.sprocketsSrcMapSourcesMap = {};
    const tmpobj = tmp.fileSync({prefix: 'opalTestRequires', postfix: '.js'});
    fs.writeFileSync(tmpobj.name, metadata.testRequires);
    files.push(createPattern(tmpobj.name, false));
    const stacktraceJsPath = require.resolve('stacktrace-js/dist/stacktrace-with-promises-and-json-polyfills.min');
    files.push(createPattern(stacktraceJsPath, false));
    files.push(createPattern(`${__dirname}/runner.js`, false));
    // a default preprocessor, need forward slash to catch absolute paths for opal and opal-rspec GEMs
    config.preprocessors['/**/*'] = ['sprockets'];
};

initOpal.$inject = ['config.files', 'logger', 'config'];

module.exports = {
    'framework:opal': ['factory', initOpal]
};
Object.assign(module.exports, preprocessor, opalSourceMap);
