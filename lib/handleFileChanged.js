const getMetadataFetcher = require('./metadataFetcher');
const _ = require('lodash');

function createPattern(path, watch) {
    return {pattern: path, included: true, served: true, watched: watch};
}

const handleFileChanged = function (config, logger, fileList) {
    const opalConfig = config.opal;
    const log = logger.create('preprocessor.sprockets.handleFileChanged');
    const fetchMetadata = getMetadataFetcher(opalConfig, logger);
    var refreshInProgress = false;

    return function (files) {
        if (refreshInProgress) {
            console.log("another refresh in progress, not doing anything");
            return;
        }
        log.debug("got file changed with the following args!");
        log.debug("config.files patterns BEGIN");
        console.dir(config.files);
        log.debug("config.files patterns END");
        fetchMetadata(['opal', 'opal-rspec', 'karma_reporter']).then((metadata) => {
            console.log("got metdata back");
            console.dir(metadata);
            opalConfig.fileMetadata = metadata;
            const newPatterns = _.map(metadata, (fileInfo, fileName) => createPattern(fileName, fileInfo.watch));
            // TODO: Populate excludes from Karma config
            const excludes = [];
            refreshInProgress = true;
            fileList.reload(newPatterns, excludes).then(() => {
                console.log("refresh is done");
                refreshInProgress = false;
            });
        }).error((error) => {
            console.log("we got an error fetching metadata!, need to hande it!! " + error);
        });
    };
};

module.exports = handleFileChanged;
