const httpSync = require('urllib-sync').request;

// TODO: Turn this into code that just blocks until the Rack server is up (from url /) and that's it

function SprocketsAssetException(message) {
    this.message = message;
    this.name = 'SprocketsAssetException';
}

const getMetadata = function (config, log) {
    // Have to block here because we need the file list from Sprockets before Karma can start
    var metadataResponse = null;
    const opalConfig = config.opal;
    log.info('Getting metadata from Sprockets, this can take a while the first time');
    var retries = 0; // can't use retry libs because this needs to be synchronous
    while (metadataResponse === null) {
        retries += 1;
        try {
            metadataResponse = httpSync(`${opalConfig.rackServer.assetsUrl}/opalMetadata.js.erb`, {timeout: opalConfig.rackRequestTimeout});
        }
        catch (e) {
            if (e.message.indexOf('ECONNREFUSED') != -1) {
                if (retries >= opalConfig.rackRetryLimit) {
                    throw new SprocketsAssetException(`Connection to Rack server refused, tried ${retries} times but hit max limit of ${opalConfig.rackRetryLimit}. There might have been an exception in Rack startup. Try running Karma with --log-level=debug`);
                }
                log.debug(`Server not up yet, trying again (try ${retries})`);
            }
            else if (e.message.indexOf('Request timeout') != -1) {
                throw new SprocketsAssetException(`Connected to Rack server but timed out waiting for response after configured rackRequestTimeout of ${opalConfig.rackRequestTimeout} ms`);
            }
            else {
                throw new SprocketsAssetException(`Unexpected error ${e}`);
            }
        }
    }

    if (metadataResponse.status != 200) {
        throw new SprocketsAssetException(`Unable to fetch asset metadata from Sprockets, error details: ${metadataResponse.data.toString()}`);
    }

    const fileList = JSON.parse(metadataResponse.data.toString());
    const testRequiresResponse = httpSync(`${opalConfig.rackServer.assetsUrl}/opalTestRequires.js.erb`);

    return {
        fileList: fileList,
        testRequires: testRequiresResponse.data.toString()
    };
};

module.exports = getMetadata;
