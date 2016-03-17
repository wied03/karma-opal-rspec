const getMetadataFetcher = require('./metadataFetcher')
const _ = require('lodash')
const Glob = require('glob').Glob
const pathLib = require('path')
const GLOB_OPTS = {
    cwd: '/',
    follow: true,
    nodir: true,
    sync: true
}
const Promise = require('bluebird')

function createPattern(path, watch) {
    return {pattern: path, included: true, served: true, watched: watch}
}

const setupFileListOverrides = function (config, logger, preLoads, sprocketsPreloads, postLoads, fileList) {
    const opalConfig = config.opal
    const log = logger.create('karma_sprockets.setupFileListOverrides')
    const fetchMetadata = getMetadataFetcher(opalConfig, logger)
    const noWatchPatterns = (filenames) => _.map(filenames, (fileName) => createPattern(fileName, false))

    const getPreloadData = () => {
        var newPatterns = noWatchPatterns(preLoads)

        return fetchMetadata(sprocketsPreloads).then((metadata) => {
            return {
                // no watching needed for preloads, opal and opal-rspec dependencies
                patterns: newPatterns.concat(_.map(metadata, (fileInfo, fileName) => createPattern(fileName, false))),
                metadata: metadata
            }
        })
    }

    const getPostLoadData = (updates) => {
        return {
            // no watching needed for the test runner
            patterns: updates.patterns.concat(noWatchPatterns(postLoads)),
            metadata: updates.metadata
        }
    }

    const getTestData = (files, pattern, updates) => {
        return fetchMetadata(files).then((newMetadata) => {
            var newPatterns = updates.patterns.slice()
            // covers test wildcard
            newPatterns.push(pattern)
            const testDependencyMetadata = _.filter(newMetadata, (fileInfo, fileName) => !_.includes(files, fileName));
            newPatterns = newPatterns.concat(_.map(testDependencyMetadata, (fileInfo, fileName) => {
                // do want to watch test dependencies that are not GEMs because they are likely in the project
                var watch = !fileInfo.roll_up;
                return createPattern(fileName, watch);
            }))

            var combinedMetadata = Object.assign({}, updates.metadata)
            Object.assign(combinedMetadata, newMetadata)

            return {
                patterns: newPatterns,
                metadata: combinedMetadata
            }
        })
    }

    const getPatternsWithDeps = (patterns) => {
        return getPreloadData().then((preloadUpdates) => {
            return Promise.reduce(patterns, (updates, patternObject) => {
                var pattern = patternObject.pattern
                // TODO: Deal with absolute patterns here

                var mg = new Glob(pathLib.normalize(pattern), GLOB_OPTS)
                var files = mg.found

                if (_.isEmpty(files)) {
                    log.warn('Pattern "%s" does not match any file.', pattern)
                    return
                }
                return getTestData(files, patternObject, updates)
            }, preloadUpdates)
        }).then((updates) => {
            var final = getPostLoadData(updates)
            opalConfig.fileMetadata = final.metadata
            return final.patterns
        })
    }

    const origRefresh = fileList.refresh
    fileList.refresh = function () {
        const self = this

        return getPatternsWithDeps(config.files).then((newPatterns) => {
            self._patterns = newPatterns
            return origRefresh.call(self)
        })
    }

    // TODO: Need to store the file entry (comes in with files with mtime) on our metadata
    // TODO: if the time hasn't changed on anything, they don't refresh the files, etc.
    // TODO: if the mtime hasn't changed on anything, then use the same exact file entry that came in
    // TODO: Implement this and the change/delete overrides
    const origAdd = fileList.addFile
    fileList.addFile = function (path) {
        return origAdd.call(this, path)
    }
}

module.exports = setupFileListOverrides
