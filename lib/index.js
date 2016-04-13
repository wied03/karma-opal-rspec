const fs = require('fs');
const _ = require('lodash');

const createPattern = function (path, watch) {
    return {pattern: path, included: true, served: true, watched: watch};
};

const initOpalRSpec = function (files, logger, config) {
    const stacktraceJsPath = require.resolve('stacktrace-js/dist/stacktrace-with-promises-and-json-polyfills.min');
    files.push(createPattern(stacktraceJsPath, false));
    files.push(createPattern(`${__dirname}/runner.js`, false));
};

initOpalRSpec.$inject = ['config.files', 'logger', 'config'];

module.exports = {
    'framework:opal_rspec': ['factory', initOpalRSpec]
};
