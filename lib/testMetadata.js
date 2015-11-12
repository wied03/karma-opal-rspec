var httpSync = require('urllib-sync').request;

var testMetadata = function () {
    // Have to block here because we need the file list from Sprockets before Karma can start
    var metadataResponse;
    while (true) {
        log.debug("Getting metadata from Sprockets");
        try {
            // TODO: hard coded hostname/port
            metadataResponse = httpSync("http://localhost:9292/assets/opalMetadata.js.erb", {timeout: 30000});
            break;
        }
        catch (e) {
            log.debug("Server not up yet");
        }
    }

    var fileList = JSON.parse(metadataResponse.data.toString());
    // TODO: Hard coded hostname
    var testRequiresResponse = httpSync('http://localhost:9292/assets/opalTestRequires.js.erb');

    return {
        fileList: fileList,
        testRequires: testRequiresResponse.data.toString()
    };
};

module.exports = testMetadata;
