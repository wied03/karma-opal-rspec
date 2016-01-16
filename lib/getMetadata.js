var httpSync = require('urllib-sync').request;

var getMetadata = function (config, log) {
    // Have to block here because we need the file list from Sprockets before Karma can start
    var metadataResponse = null;
    log.info('Getting metadata from Sprockets, this can take a while the first time');
    while (metadataResponse !== null) {
        try {
            metadataResponse = httpSync(`${config.opalRackServer.assetsUrl}/opalMetadata.js.erb`, {timeout: 90000});
        }
        catch (e) {
            log.debug('Server not up yet');
        }
    }

    var fileList = JSON.parse(metadataResponse.data.toString());
    var testRequiresResponse = httpSync(`${config.opalRackServer.assetsUrl}/opalTestRequires.js.erb`);

    return {
        fileList: fileList,
        testRequires: testRequiresResponse.data.toString()
    };
};

module.exports = getMetadata;
