const getMetadataFetcher = require('./metadataFetcher');
const _ = require('lodash');

function createPattern(path, watch) {
    return {pattern: path, included: true, served: true, watched: watch};
}

const setupFileListOverrides = function (config, logger, preLoads, sprocketsPreloads, postLoads, fileList) {
    const opalConfig = config.opal;
    const log = logger.create('karma_sprockets.setupFileListOverrides');
    const fetchMetadata = getMetadataFetcher(opalConfig, logger);

    const getUpdatedMetadata = (files) => {
        // TODO: Need to store the file entry (comes in with files with mtime) on our metadata
        // TODO: if the time hasn't changed on anything, they don't refresh the files, etc.
        // TODO: if the mtime hasn't changed on anything, then use the same exact file entry that came in
        const noWatchPatterns = (filenames) => _.map(filenames, (fileName) => createPattern(fileName, false));
        // not test dependencies
        var newPatterns = noWatchPatterns(preLoads);
        return fetchMetadata(sprocketsPreloads).then((metadata) => {
            console.log("got metadata back");
            console.dir(metadata);
            newPatterns = newPatterns.concat(_.map(metadata, (fileInfo, fileName) => createPattern(fileName, fileInfo.watch)));
            // TODO: Right here we need to get the metadata for the files parameter up top
            // TODO: right here we need to add requires in for opal-rspec and all of our tests here
            // not test dependencies
            newPatterns = newPatterns.concat(noWatchPatterns(postLoads));
            return {
                patterns: newPatterns,
                metadata: metadata
            };
        }).error((error) => {
            console.log("we got an error fetching metadata!, need to hande it!! " + error);
        });
    };

    const origRefresh = fileList.refresh;
    fileList.refresh = () => {
        return getUpdatedMetadata(this.files).then((updated) => {
            this._patterns = updated.patterns;
            console.log("updated patterns to");
            console.dir(this._patterns);
            // TODO: Should this be here?
            opalConfig.fileMetadata = updated.metadata;
            return origRefresh.call(this);
        });
    };

    const origAdd = fileList.addFile;
    fileList.addFile = function (path) {
        console.log("brady add override!");
        return origAdd.call(this, path);
    };
};

module.exports = setupFileListOverrides;
