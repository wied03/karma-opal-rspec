const getMetadataFetcher = require('./metadataFetcher');
const _ = require('lodash');

function createPattern(path, watch) {
    return {pattern: path, included: true, served: true, watched: watch};
}

const setupFileListOverrides = function (config, logger, preLoads, sprocketsPreloads, postLoads, fileList) {
    const opalConfig = config.opal;
    const log = logger.create('karma_sprockets.setupFileListOverrides');
    const fetchMetadata = getMetadataFetcher(opalConfig, logger);

    const getUpdatedPatterns = (files) => {
        // TODO: Need to store the file entry (comes in with files with mtime) on our metadata
        // TODO: if the time hasn't changed on anything, they don't refresh the files, etc.
        // TODO: if the mtime hasn't changed on anything, then use the same exact file entry that came in
        const noWatchPatterns = (filenames) => _.map(filenames, (fileName) => createPattern(fileName, false));

        return fetchMetadata(sprocketsPreloads, false).then((metadata) => {
                // not test dependencies, so no watching needed
                const newPatterns = noWatchPatterns(preLoads);

                console.log("got metadata back");
                console.dir(metadata);
                return {
                    patterns: newPatterns.concat(_.map(metadata, (fileInfo, fileName) => createPattern(fileName, fileInfo.watch))),
                    metadata: metadata
                };
            })
            .then((updated) => {
                // TODO: Right here we need to get the metadata for the files parameter up top
                // TODO: right here we need to add requires in for opal-rspec and all of our tests here

                opalConfig.fileMetadata = updated.metadata;
                // not test dependencies so not watching needed
                return updated.patterns.concat(noWatchPatterns(postLoads));
            });
    };

    const origRefresh = fileList.refresh;
    fileList.refresh = function () {
        const self = this;

        return getUpdatedPatterns(self.files).then((newPatterns) => {
            console.log("current patterns");
            console.dir(self._patterns);
            self._patterns = newPatterns;
            console.log("updated patterns to");
            console.dir(self._patterns);
            return origRefresh.call(self);
        });
    };

    // TODO: Implement this and the change/delete overrides
    const origAdd = fileList.addFile;
    fileList.addFile = function (path) {
        console.log("brady add override!");
        return origAdd.call(this, path);
    };
};

module.exports = setupFileListOverrides;
