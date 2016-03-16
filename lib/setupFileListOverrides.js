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

        return fetchMetadata(sprocketsPreloads, false).then((metadata) => {
            return {
                // no watching needed for preloads, opal and opal-rspec dependencies
                patterns: newPatterns.concat(_.map(metadata, (fileInfo, fileName) => createPattern(fileName, false))),
                metadata: metadata
            }
        })
    }

    // TODO: Just pass in updates for the chain
    const getPostLoadData = (existingPatterns, existingMetadata) => {
        return {
            // no watching needed for the test runner
            patterns: existingPatterns.patterns.concat(noWatchPatterns(postLoads)),
            metadata: existingMetadata
        }
    }

    const getTestData = (files, existingPatterns, existingMetadata) => {
        console.log("start gettestdata")
        console.dir(existingPatterns)
        console.dir(existingMetadata)
        // TODO:We get to this point but then we never come back
        console.log("fetching test data for files ")
        console.dir(files)
        // want to exclude the tests themselves from the metadata, just want requires
        return fetchMetadata(files, true).then((newMetadata) => {
            var newPatterns = existingPatterns.slice()
            newPatterns.push(pattern)
            newPatterns = newPatterns.concat(_.map(newMetadata, (fileInfo, fileName) => {
                // do want to watch test dependencies that are not GEMs because they are likely in the project
                var watch = !fileInfo.roll_up;
                return createPattern(fileName, watch);
            }))

            var combinedMetadata = Object.assign({}, existingMetadata)
            Object.assign(combinedMetadata, newMetadata)

            return {
                patterns: newPatterns,
                metadata: combinedMetadata
            }
        })
    }

    const getNewPatterns = (patterns) => {
        return getPreloadData()
            .then((preloadUpdates) => {
                console.log("preload done");
                console.dir(preloadUpdates);
                return Promise.reduce(patterns, (updates, patternObject) => {
                    var pattern = patternObject.pattern
                    // TODO: Deal with absolute patterns here

                    var mg = new Glob(pathLib.normalize(pattern), GLOB_OPTS)
                    var files = mg.found

                    if (_.isEmpty(files)) {
                        log.warn('Pattern "%s" does not match any file.', pattern)
                        return
                    }
                    return getTestData(files, updates.patterns, updates.metadata)
                }, preloadUpdates)
            })
            .then((updates) => {
                var final = getPostLoadData(updates.patterns, updates.metadata)
                opalConfig.fileMetadata = final.metadata
                return updates.patterns
            })
    }

    const origRefresh = fileList.refresh
    fileList.refresh = function () {
        const self = this

        return getNewPatterns(config.files).then((newPatterns) => {
            console.log("current patterns")
            console.dir(self._patterns)
            self._patterns = newPatterns
            console.log("updated patterns to")
            console.dir(self._patterns)
            return origRefresh.call(self)
        })
    }

    // TODO: Need to store the file entry (comes in with files with mtime) on our metadata
    // TODO: if the time hasn't changed on anything, they don't refresh the files, etc.
    // TODO: if the mtime hasn't changed on anything, then use the same exact file entry that came in
    // TODO: Implement this and the change/delete overrides
    const origAdd = fileList.addFile
    fileList.addFile = function (path) {
        console.log("brady add override!")
        return origAdd.call(this, path)
    }
}

module.exports = setupFileListOverrides
