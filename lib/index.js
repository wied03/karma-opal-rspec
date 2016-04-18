'use strict'

const exec = require('child_process').execSync
const path = require('path')

const createPattern = function (path, watch) {
    return {pattern: path, included: true, served: true, watched: watch}
}

const initOpalRSpec = function (files, logger, config) {
    const log = logger.create('framework:opal_rspec')

    const opalConfig = config.webpack.opal || (config.webpack.opal = {})
    // we include this ourselves to reduce the feedback cycle with webpack
    opalConfig.externalOpal = true

    const opal = require('opal-webpack/lib/opal')
    if (opal.get('RUBY_ENGINE_VERSION').indexOf('0.9') != -1) {
        // arity checking is good for unit testing
        opalConfig.arity_check = false
        log.debug('Disabling arity checking since == Opal 0.9')
    }
    else {
        opalConfig.arity_check = true
        log.debug('Enabling arity checking since != Opal 0.9')
    }

    const opalRuntimeRspecFilename = exec(`bundle exec ruby ${path.resolve(__dirname, 'rspec_bundler.rb')}`).toString().trim()
    log.debug(`Built opal runtime+opal-rspec bundle ${opalRuntimeRspecFilename}`)
    files.unshift(createPattern(opalRuntimeRspecFilename, false))
    opalConfig.cacheDirectory = opalConfig.cacheDirectory || 'tmp/opal_rspec_cache'
    const stacktraceJsPath = require.resolve('stacktrace-js/dist/stacktrace-with-promises-and-json-polyfills.min')
    files.push(createPattern(stacktraceJsPath, false))
    files.push(createPattern(`${__dirname}/runner.js`, false))
}

initOpalRSpec.$inject = ['config.files', 'logger', 'config']

module.exports = {
    'framework:opal_rspec': ['factory', initOpalRSpec]
}
