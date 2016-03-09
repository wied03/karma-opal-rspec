const httpSync = require('urllib-sync').request;

function SprocketsAssetException(message) {
    this.message = message;
    this.name = 'SprocketsAssetException';
}

const getMetadata = function (config, log) {
    // Have to block here because we need the file list from Sprockets before Karma can start
    var metadataResponse = null;
    log.info('Getting metadata from Sprockets, this can take a while the first time');
    while (metadataResponse === null) {
        try {
            metadataResponse = httpSync(`${config.opalRackServer.assetsUrl}/opalMetadata.js.erb`, {timeout: config.opal.rackServerTimeout});
        }
        catch (e) {
            log.debug('Server not up yet');
        }
    }

    if (metadataResponse.status != 200) {
        throw new SprocketsAssetException(`Unable to fetch asset metadata from Sprockets, error details: ${metadataResponse.data.toString()}`);
    }

    const fileList = JSON.parse(metadataResponse.data.toString());
    const testRequiresResponse = httpSync(`${config.opalRackServer.assetsUrl}/opalTestRequires.js.erb`);

    return {
        fileList: fileList,
        testRequires: testRequiresResponse.data.toString()
    };
};

module.exports = getMetadata;
