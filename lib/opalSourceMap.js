var http = require('http');

var createOpalSourceMapMWare = function (config, logger) {
    var log = logger.create('middleware:opal_sourcemap');

    return function (request, response, next) {
        if (request.url.endsWith(".rb")) {
            // TODO: Hook into mapping described below
            var newUrl = `${config.opalRackServer.baseUrl}${request.url.replace("base/spec", "__OPAL_SOURCE_MAPS__")}`;
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
                    /*
                     TODO: Create a new module/function that will
                     1) Take in the returned JSON source map from opal/sprockets
                     2) request.url, which will be either /absolute/Users/brady/code/Ruby/opal/repos_NOCRASHPLAN/karma-opal-rspec/lib/karma_formatter.js.map or /base/spec/main_spec.js.map
                     and return 1) a modified source map with
                     1) File set to the original file
                     2) sources set to the ruby path for the file

                     expected file for absolute case will be /absolute/Users/brady/code/Ruby/opal/repos_NOCRASHPLAN/karma-opal-rspec/lib/karma_formatter.js
                     for the main spec case, will be /base/spec/main_spec.js

                     for sources, absolute case should be /absolute/Users/brady/code/Ruby/opal/repos_NOCRASHPLAN/karma-opal-rspec/lib/karma_formatter.rb
                     for main spec case, will be /base/spec/main_spec.rb

                     In order to accomplish this, will do inverse of filePathToUrlPath in sprocketsPreprocessor

                     before/after calling this, store a mapping between what the source was and what the new source is
                     that way we can show the browser a nice source but can use the original source when fetching it from sprockets (see if at top)
                     */
                    var asJson = JSON.parse(rawSourceMap);
                    // TODO: Fix this hard coded stuff
                    if (request.url.indexOf("foo") != -1) {
                        asJson.file = "spec/foo.js";
                    }
                    if (request.url.indexOf("something_spec") != -1) {
                        asJson.file = "spec/foo.js";
                    }
                    if (request.url.indexOf("other_spec") != -1) {
                        asJson.file = "spec/other_spec.js";
                    }
                    if (request.url.indexOf("via_sprockets") != -1) {
                        asJson.file = "spec/via_sprockets.js";
                    }
                    asJson.sources = [asJson.sources[0].replace("__OPAL_SOURCE_MAPS__", "base/spec")];
                    var asString = JSON.stringify(asJson);
                    log.debug("end of source map " + asString);
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
