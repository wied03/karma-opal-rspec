const http = require('http');
const url = require('url');

function SprocketsAssetException(message) {
    this.message = message;
    this.name = 'SprocketsAssetException';
}

const createMetadataFetcher = function (opalConfig, logger) {
    const log = logger.create('preprocessor.sprockets.metadatafetcher');

    return function (files, callback) {
        var metadataUrl = url.parse(`${opalConfig.rackServer.baseUrl}/metadata`);

        var request = http.request({
            host: metadataUrl.hostname,
            port: metadataUrl.port,
            path: metadataUrl.path,
            method: 'POST'
        }, function (response) {
            var metadataStr = '';
            response.on('data', function (chunk) {
                metadataStr += chunk.toString();
            });
            response.on('end', function () {
                const metadata = JSON.parse(metadataStr);
                callback(metadata);
            });
        });
        const metadataBody = {
            files: files,
            watch: false, // TODO: Watch property needs to be based on whether it's a GEM file or not, not input
            exclude_self: false // TODO: Remove this property entirely, we won't use it
        };
        request.write(JSON.stringify(metadataBody));
        request.end();
    };
};

module.exports = createMetadataFetcher;
