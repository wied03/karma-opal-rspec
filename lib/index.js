const child_process = require('child_process')
const spawn = child_process.spawn
const preprocessor = require('./karma_sprockets/sprocketsPreprocessor')
const overrider = require('./karma_sprockets/setupFileListOverrides')
const opalSourceMap = require('./karma_sprockets/opalSourceMap')

const initOpal = function (files, logger, config, fileListOverrider) {
    const log = logger.create('init.opal')
    const env = Object.create(process.env)
    config.opal = config.opal || {}
    const opalConfig = config.opal
    if (!opalConfig.rackRequestTimeout) {
        // default browser timeout is 10,000 ms so this seems like a decent compromise based on test size
        opalConfig.rackRequestTimeout = config.browserNoActivityTimeout * 3
    }
    opalConfig.rackRetryLimit = opalConfig.rackRetryLimit || 50
    env.OPAL_LOAD_PATH = opalConfig.loadPaths || []
    // using empty string to force default path to be supplied in opal-rspec if not supplied here
    env.OPAL_DEFAULT_PATH = opalConfig.defaultPath || ''
    env.OPAL_ROLL_UP = opalConfig.rollUp || []
    env.MRI_REQUIRES = opalConfig.mriRequires || []
    log.debug('Launching Rack server to handle sprockets/assets')
    const stdioSetting = log.isLevelEnabled('debug') ? 'inherit' : 'ignore'
    const rubyLoadPath = `${__dirname}/sprockets_server`
    const rack = spawn('bundle', ['exec', 'rackup', '-I', rubyLoadPath, `${rubyLoadPath}/rack_server.ru`], {
        stdio: stdioSetting,
        env: env
    })
    opalConfig.rackServer = {
        baseUrl: 'http://localhost:9292',
        assetsUrl: 'http://localhost:9292/assets'
    }
    process.on('exit', function () {
        rack.kill('SIGINT')
    })
    opalConfig.sprocketsSrcMap = {}
    opalConfig.sprocketsSrcMapSourcesMap = {}
    opalConfig.fileMetadata = null
    const sprocketsPreloads =  ['opal', 'opal-rspec', 'karma_reporter']
    const preLoads = [
        require.resolve('stacktrace-js/dist/stacktrace-with-promises-and-json-polyfills.min'),
        `${__dirname}/karma_sprockets/runner.js`
    ]
    const postLoads = []
    fileListOverrider(preLoads, sprocketsPreloads, postLoads, rack)
    // a default preprocessor, need forward slash to catch absolute paths for opal and opal-rspec GEMs
    config.preprocessors['/**/*.rb'] = ['sprockets']
}

initOpal.$inject = ['config.files', 'logger', 'config', 'fileListOverrider']

module.exports = {
    'framework:opal': ['factory', initOpal]
}
Object.assign(module.exports, preprocessor, opalSourceMap, overrider)
