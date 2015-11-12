var httpSync = require('urllib-sync').request;

var getMetadata = function (config, log) {
    // Have to block here because we need the file list from Sprockets before Karma can start
    var metadataResponse;
    while (true) {
        log.debug("Getting metadata from Sprockets");
        try {
            metadataResponse = httpSync(`${config.opalRackServer.assetsUrl}/opalMetadata.js.erb`, {timeout: 30000});
            break;
        }
        catch (e) {
            log.debug("Server not up yet");
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
