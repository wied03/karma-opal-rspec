var http = require('http');
var translateOpalSourceMap = require('./opalSourceMapTranslator');

var createOpalSourceMapMWare = function (config, logger) {
    var log = logger.create('middleware:opal_sourcemap');

    config.opal = config.opal || {};
    config.opal.sourceMapsEnabled = true;

    return function (request, response, next) {
        if (request.url.endsWith(".rb")) {
            var originalSource = config.sprocketsSrcMapSourcesMap[request.url];
            var newUrl = `${config.opalRackServer.baseUrl}${originalSource}`;
            log.debug("sending original source query on to " + newUrl);
            http.get(newUrl, function (sprocketsResponse) {
                response.writeHead(sprocketsResponse.statusCode, sprocketsResponse.headers);
                var originalSource = "";
                sprocketsResponse.on('data', function (chunk) {
                    originalSource += chunk.toString();
                });
                sprocketsResponse.on('end', function () {
                    response.end(originalSource);
                });
            });
        }
        else if (request.url.endsWith(".map")) {
            log.debug(`initial source map request ${request.url}`);
            var sourceMapUrl = config.sprocketsSrcMap[request.url];
            if (sourceMapUrl === undefined) {
                log.warn(`No opal source map exists for ${request.url}. Is this a non-Opal source map?`);
                next();
                return;
            }
            log.debug(`fetching source maps from ${sourceMapUrl}`);
            http.get(sourceMapUrl, function (sprocketsResponse) {
                response.writeHead(sprocketsResponse.statusCode, sprocketsResponse.headers);
                if (sprocketsResponse.statusCode == 404) {
                    response.end();
                    return;
                }
                var rawSourceMap = "";
                sprocketsResponse.on('data', function (chunk) {
                    rawSourceMap += chunk.toString();
                });
                sprocketsResponse.on('end', function () {
                    var asJson = JSON.parse(rawSourceMap);
                    var existingSource = asJson.sources[0];
                    translateOpalSourceMap(asJson, request.url);
                    // we're presenting a "cleaner" source to the browser but we need to know how to get the original from Opal
                    config.sprocketsSrcMapSourcesMap[asJson.sources[0]] = existingSource;
                    var asString = JSON.stringify(asJson);
                    log.debug("cleaned up source map " + asString);
                    response.end(asString);
                });
            });
        }
        else {
            next();
        }
    };
};

createOpalSourceMapMWare.$inject = ['config', 'logger'];

module.exports = {
    'middleware:opal_sourcemap': ['factory', createOpalSourceMapMWare]
};
