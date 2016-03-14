const http = require('http');
const url = require('url');
const retry = require('retry');

function SprocketsAssetException(message) {
    this.message = message;
    this.name = 'SprocketsAssetException';
}

function faultTolerantFetch(opalConfig, requestOptions, files, callback) {
    const operation = retry.operation();

    operation.attempt(function (currentAttempt) {
        var request = http.request(requestOptions, function (response) {
            var metadataStr = '';
            response.on('data', function (chunk) {
                metadataStr += chunk.toString();
            });
            response.on('end', function () {
                const metadata = JSON.parse(metadataStr);
                callback(null, metadata);
            });
        });
        const metadataBody = {
            files: files,
            watch: false, // TODO: Watch property needs to be based on whether it's a GEM file or not, not input
            exclude_self: false // TODO: Remove this property entirely, we won't use it
        };
        request.on('error', function (error) {
            if (operation.retry(error)) {
                return;
            }
            callback(operation.mainError(), null);
        });
        request.setTimeout(opalConfig.rackRequestTimeout);
        request.write(JSON.stringify(metadataBody));
        request.end();
    });
}

const createMetadataFetcher = function (opalConfig, logger) {
    const log = logger.create('preprocessor.sprockets.metadatafetcher');

    return function (files, callback) {
        const metadataUrl = url.parse(`${opalConfig.rackServer.baseUrl}/metadata`);
        const requestOptions = {
            host: metadataUrl.hostname,
            port: metadataUrl.port,
            path: metadataUrl.path,
            method: 'POST'
        };
        faultTolerantFetch(opalConfig, requestOptions, files, callback);
    };
};

module.exports = createMetadataFetcher;
