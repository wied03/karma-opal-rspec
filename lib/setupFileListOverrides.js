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
const tmp = require('tmp')
const fs = require('fs')

function createPattern(path, watch) {
    return {pattern: path, included: true, served: true, watched: watch}
}

function generateRequiresFile(testMetadata, testRequiresFile, newPatterns) {
    const requireClauses = ['Opal.require(\'opal/rspec\');']
        .concat(_.map(testMetadata, (fileInfo, fileName) => `Opal.require('${pathLib.basename(fileInfo.logical_path, '.js')}');`))
    const requiresContents = requireClauses.join('\n')
    fs.writeFileSync(testRequiresFile.name, requiresContents)
    // don't watch this, we'll regen it anyways
    newPatterns.push(createPattern(testRequiresFile.name, false))
}
const setupFileListOverrides = function (config, logger, preLoads, sprocketsPreloads, postLoads, fileList, rackProcess) {
    const opalConfig = config.opal
    const log = logger.create('karma_sprockets.setupFileListOverrides')
    const fetchMetadata = getMetadataFetcher(opalConfig, logger, rackProcess)
    const noWatchPatterns = (filenames) => _.map(filenames, (fileName) => createPattern(fileName, false))
    const testRequiresFile = tmp.fileSync({prefix: 'opalTestRequires', postfix: '.js'})

    const getSprocketsPreloadData = (existingPatterns) => {
        return fetchMetadata(sprocketsPreloads).then((metadata) => {
            return {
                // no watching needed for preloads, opal and opal-rspec dependencies
                patterns: existingPatterns.concat(_.map(metadata, (fileInfo, fileName) => createPattern(fileName, false))),
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

    const getTestData = (specFiles, pattern, updates) => {
        return fetchMetadata(specFiles).then((newMetadata) => {
            var newPatterns = updates.patterns.slice()
            // covers test wildcard
            newPatterns.push(pattern)
            const testDependencyMetadata = _.pickBy(newMetadata, (fileInfo, fileName) => !_.includes(specFiles, fileName))

            newPatterns = newPatterns.concat(_.map(testDependencyMetadata, (fileInfo, fileName) => {
                // do want to watch test dependencies that are not GEMs because they are likely in the project
                var watch = !fileInfo.roll_up
                return createPattern(fileName, watch)
            }))

            const combinedMetadata = Object.assign({}, updates.metadata)
            Object.assign(combinedMetadata, newMetadata)

            return {
                patterns: newPatterns,
                metadata: combinedMetadata
            }
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
                return getTestData(files, patternObject, updates)
            }, initialUpdates)
            return allTestUpdatesPromise.then((allTestUpdates) => {
                var newPatterns = preloadUpdates.patterns.concat(allTestUpdates.patterns)
                generateRequiresFile(allTestUpdates.metadata, testRequiresFile, newPatterns)
                const combinedMetadata = Object.assign({}, preloadUpdates.metadata)
                Object.assign(combinedMetadata, allTestUpdates.metadata)
                return {
                    patterns: newPatterns,
                    metadata: combinedMetadata
                }
            })
        }).then((updates) => {
            const final = getPostLoadData(updates)
            console.log("file metadata is now")
            console.dir(final)
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

    // TODO: Need to store the file entry (comes in with files with mtime) on our metadata
    // TODO: if the time hasn't changed on anything, they don't refresh the files, etc.
    // TODO: if the mtime hasn't changed on anything, then use the same exact file entry that came in
    // TODO: Implement this and the change/delete overrides
    //const origAdd = fileList.addFile
    //fileList.addFile = function (path) {
    //    return origAdd.call(this, path)
    //}
}

module.exports = setupFileListOverrides
