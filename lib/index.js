const fs = require('fs')
const exec = require('child_process').execSync
const path = require('path')

const createPattern = function (path, watch) {
    return {pattern: path, included: true, served: true, watched: watch}
};

const initOpalRSpec = function (files, logger, config) {
    const opalConfig = config.webpack.opal || (config.webpack.opal = {})
    // we include this ourselves to reduce the feedback cycle with webpack
    opalConfig.externalOpal = true
    // arity checking is good for unit testing
    opalConfig.arity_check = true
    const opalCompilerRspecFilename = exec(`bundle exec ruby ${path.resolve(__dirname, 'rspec_bundler.rb')}`).toString().trim()
    files.unshift(createPattern(opalCompilerRspecFilename, false))
    opalConfig.cacheDirectory = opalConfig.cacheDirectory || 'tmp/opal_rspec_cache'
    const stacktraceJsPath = require.resolve('stacktrace-js/dist/stacktrace-with-promises-and-json-polyfills.min')
    files.push(createPattern(stacktraceJsPath, false))
    files.push(createPattern(`${__dirname}/runner.js`, false))
}

initOpalRSpec.$inject = ['config.files', 'logger', 'config']

module.exports = {
    'framework:opal_rspec': ['factory', initOpalRSpec]
}
