const getMetadataFetcher = require('./metadataFetcher');

function createPattern(path, watch) {
    return {pattern: path, included: true, served: true, watched: watch};
}

const handleFileChanged = function (config, logger, fileList) {
    const opalConfig = config.opal;
    const log = logger.create('preprocessor.sprockets.handleFileChanged');

    const fetchMetadata = getMetadataFetcher(opalConfig, logger);

    return function (stuff) {
        // TODO: Use stuff
        log.debug("got file changed!");
        log.debug("config.files patterns BEGIN");
        console.dir(config.files);
        log.debug("config.files patterns END");
        fetchMetadata(['opal', 'opal-rspec', 'karma_reporter'], function (metadata) {
            const newPatterns = _.map(metadata, function (fileInfo, filename) {
                return createPattern(filename, fileInfo.watch);
            });
            // TODO: Populate excludes from Karma config
            const excludes = [];
            fileList.reload(newPatterns, excludes);
        });
    };
};

module.exports = handleFileChanged;
