const getMetadataFetcher = require('./metadataFetcher');
const _ = require('lodash');

function createPattern(path, watch) {
    return {pattern: path, included: true, served: true, watched: watch};
}

const handleFileChanged = function (config, logger, preLoads, sprocketsPreloads, postLoads, fileList) {
    const opalConfig = config.opal;
    const log = logger.create('preprocessor.sprockets.handleFileChanged');
    const fetchMetadata = getMetadataFetcher(opalConfig, logger);
    var refreshInProgress = false;

    return function (files) {
        if (refreshInProgress) {
            console.log("another refresh in progress, not doing anything");
            return;
        }
        // TODO: Need to store the file entry (comes in with files with mtime) on our metadata
        // if the time hasn't changed on anything, they don't refresh the files, etc.
        // TODO: if the mtime hasn't changed on anything, then use the same exact file entry that came in
        log.debug("got file changed with the following args!");
        log.debug("config.files patterns BEGIN");
        console.dir(config.files);
        log.debug("config.files patterns END");
        const noWatchPatterns = (filenames) => _.map(filenames, (fileName) => createPattern(fileName, false));
        // not test dependencies
        var newPatterns = noWatchPatterns(preLoads);
        opalConfig.fileMetadata = fetchMetadata(sprocketsPreloads).then((metadata) => {
            console.log("got metadata back");
            console.dir(metadata);
            newPatterns = newPatterns.concat(_.map(metadata, (fileInfo, fileName) => createPattern(fileName, fileInfo.watch)));
            // TODO: Right here we need to get the metadata for the files parameter up top
            // TODO: right here we need to add requires in for opal-rspec and all of our tests here
            // not test dependencies
            newPatterns = newPatterns.concat(noWatchPatterns(postLoads));
            // TODO: Populate excludes from Karma config
            const excludes = [];
            refreshInProgress = true;
            fileList.reload(newPatterns, excludes).then(() => {
                console.log("refresh is done");
                refreshInProgress = false;
            });
            return metadata;
        }).error((error) => {
            console.log("we got an error fetching metadata!, need to hande it!! " + error);
        });
    };
};

module.exports = handleFileChanged;
