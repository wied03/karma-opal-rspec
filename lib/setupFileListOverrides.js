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
const watcher = require('karma/lib/watcher')

function createPattern(path, watch) {
    return {pattern: path, included: true, served: true, watched: watch}
}

function getNonPatternMetadata(metadata, specFiles) {
    return _.pickBy(metadata, (fileInfo, fileName) => !_.includes(specFiles, fileName))
}

function getPatternMetadata(metadata, specFiles) {
    return _.pickBy(metadata, (fileInfo, fileName) => _.includes(specFiles, fileName))
}

function getTestDependencyPatterns(specFiles, metadata) {
    const testDependencyMetadata = getNonPatternMetadata(metadata, specFiles)

    return _.map(testDependencyMetadata, (fileInfo, fileName) => {
        // do want to watch test dependencies that are not GEMs because they are likely in the project
        var watch = !fileInfo.roll_up
        return createPattern(fileName, watch)
    })
}

function markAsPatternFile(metadata, specFiles) {
    const specFileMetadata = getPatternMetadata(metadata, specFiles)
    _.forEach(specFileMetadata, (fileInfo) => fileInfo.pattern = true)
}

const setupFileListOverrides = function (config, logger, preLoads, sprocketsPreloads, postLoads, fileList, rackProcess, emitter) {
    const opalConfig = config.opal
    const log = logger.create('karma_sprockets.setupFileListOverrides')
    const fetchMetadata = getMetadataFetcher(opalConfig, logger, rackProcess)
    const noWatchPatterns = (filenames) => _.map(filenames, (fileName) => createPattern(fileName, false))

    const getSprocketsPreloadData = (existingPatterns) => {
        // avoid fetching these twice, don't need to
        if (opalConfig.sprocketsPreloadData) {
            return Promise.resolve(opalConfig.sprocketsPreloadData)
        }

        log.info('Getting initial metadata from Sprockets, this can take a while the first time')
        return fetchMetadata(sprocketsPreloads).then((metadata) => {
            const preloadFileNames = _.map(metadata, (fileInfo, fileName) => fileName)
            // no watching needed for preloads like opal and opal-rspec dependencies
            const preloadPatterns = noWatchPatterns(preloadFileNames)

            opalConfig.sprocketsPreloadData = {
                patterns: existingPatterns.concat(preloadPatterns),
                metadata: metadata
            }
            return opalConfig.sprocketsPreloadData
        })
    }

    const getPostLoadData = (updates) => {
        return {
            // no watching needed for the test runner
            patterns: updates.patterns.concat(noWatchPatterns(postLoads)),
            metadata: updates.metadata
        }
    }

    const getTestData = (specFiles, pattern, updates) => {
        return fetchMetadata(specFiles).then((newMetadata) => {
            markAsPatternFile(newMetadata, specFiles)
            var newPatterns = updates.patterns.slice()
            const dependencyPatterns = getTestDependencyPatterns(specFiles, newMetadata)
            if (config.autoWatch) {
                // out of the box watcher will only operate on spec files in the original config
                const excludes = []
                watcher.watch(dependencyPatterns, excludes, fileList, config.usePolling, emitter)
            }
            newPatterns = newPatterns.concat(dependencyPatterns)

            // covers test wildcard
            newPatterns.push(pattern)

            const combinedMetadata = Object.assign({}, updates.metadata)
            Object.assign(combinedMetadata, newMetadata)

            return {
                patterns: newPatterns,
                metadata: combinedMetadata
            }
        })
    }

    const fileChanged = (file) => {
        const specFiles = [file]

        return fetchMetadata(specFiles).then((newMetadata) => {
            markAsPatternFile(newMetadata, specFiles)
            const comparisonMetadata = Object.assign({}, opalConfig.fileMetadata)
            // we only care if dependencies have changed here since that's the only time a full refresh is needed
            Object.assign(comparisonMetadata, getNonPatternMetadata(newMetadata, specFiles))

            // dependencies didn't change, just file contents
            if (JSON.stringify(comparisonMetadata) === JSON.stringify(opalConfig.fileMetadata)) {
                const mergedMetadata = Object.assign({}, opalConfig.fileMetadata)
                Object.assign(mergedMetadata, newMetadata)
                opalConfig.fileMetadata = mergedMetadata
                // no full refresh
                return true
            }
            // full refresh will need to happen
            return false
        })
    }

    const getPatternsWithDeps = (specPatterns) => {
        var preLoadPatterns = noWatchPatterns(preLoads)
        return getSprocketsPreloadData(preLoadPatterns).then((preloadUpdates) => {
            const initialUpdates = {
                patterns: [],
                metadata: {}
            }
            const allTestUpdatesPromise = Promise.reduce(specPatterns, (updates, patternObject) => {
                var pattern = patternObject.pattern
                // TODO: Deal with absolute patterns here

                var mg = new Glob(pathLib.normalize(pattern), GLOB_OPTS)
                var files = mg.found

                if (_.isEmpty(files)) {
                    log.warn('Pattern "%s" does not match any file.', pattern)
                    return
                }
                // assuming patterns are specs (not impl)
                return getTestData(files, patternObject, updates)
            }, initialUpdates)
            return allTestUpdatesPromise.then((allTestUpdates) => {
                var newPatterns = preloadUpdates.patterns.concat(allTestUpdates.patterns)
                const combinedMetadata = Object.assign({}, preloadUpdates.metadata)
                Object.assign(combinedMetadata, allTestUpdates.metadata)
                return {
                    patterns: newPatterns,
                    metadata: combinedMetadata
                }
            })
        }).then((updates) => {
            const final = getPostLoadData(updates)
            opalConfig.fileMetadata = final.metadata
            opalConfig.metadataException = null
            return final.patterns
        }).catch((theError) => {
            log.error(`Unable to update file metadata due to this error! ${theError.message}`)
            opalConfig.metadataException = theError
            // still want to return our preloads with runner.js so that Karma can recover
            return preLoadPatterns
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

    const origAdd = fileList.addFile
    fileList.addFile = function (path) {
        const self = this

        return fileChanged(path).then((noDependenciesAdded) => {
            if (noDependenciesAdded) {
                return origAdd.call(self, path)
            }
            else {
                return fileList.refresh.call(self)
            }
        })
    }

    const origChange = fileList.changeFile
    fileList.changeFile = function (path) {
        const self = this

        return fileChanged(path).then((noDependenciesAdded) => {
            if (noDependenciesAdded) {
                return origChange.call(self, path)
            }
            else {
                return fileList.refresh.call(self)
            }
        })
    }
}

module.exports = setupFileListOverrides
