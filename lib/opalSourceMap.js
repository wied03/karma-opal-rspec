var http = require('http');

var createOpalSourceMapMWare = function (config) {
    return function (request, response, next) {
        if (request.url.endsWith(".rb")) {
            var newUrl = "http://localhost:9292" + request.url.replace("base/spec", "__OPAL_SOURCE_MAPS__");
            console.log("sending original source query on to " + newUrl);
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
            console.log("got source map query for url " + request.url);
            var sourceMapUrl = config.sprockets_src_map[request.url];
            console.log("fetching source maps from " + sourceMapUrl);
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
                    console.log("end of source map " + asString);
                    response.end(asString);
                });
            });
        }
        else {
            next();
        }
    };
};

module.exports = {
    'middleware:opal_sourcemap': ['factory', createOpalSourceMapMWare],
};
