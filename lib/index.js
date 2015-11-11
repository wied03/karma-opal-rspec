var tmp = require('tmp');
var child_process = require('child_process');
var spawn = child_process.spawn;
var http = require('http');
var path = require('path');

var opalSourceMap = function (config) {
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


var createPattern = function (path, watch) {
    return {pattern: path, included: true, served: true, watched: watch};
};

var initOpal = function (files, logger, config) {
    var pattern = files.pop().pattern;
    var log = logger.create('init.opal');
    var env = Object.create(process.env);
    env.PATTERN = pattern;
    var rack = spawn('bundle', ['exec', 'rackup', `${__dirname}/rack_server.ru`], {stdio: 'inherit', env: env});
    process.on('exit', function (code) {
        rack.kill('SIGINT');
    });

    // we need a valid path for these
    log.debug("Getting metadata from Sprockets");
    var tmpobj = tmp.fileSync({postfix: '.js'});
    var metadata = JSON.parse(child_process.execSync(`bundle exec ruby ${__dirname}/get_metadata.rb ${pattern} ${tmpobj.name}`).toString());
    for (var fileName in metadata) {
        if (metadata.hasOwnProperty(fileName)) {
            var pattern = createPattern(fileName, metadata[fileName].watch);
            files.push(pattern);
        }
    }
    config.sprockets_map = metadata;
    config.sprockets_src_map = {};
    files.push(createPattern(tmpobj.name, false));
    files.push(createPattern(`${__dirname}/runner.js`, false));
    // a default preprocessor, need forward slash to catch absolute paths for opal and opal-rspec GEMs
    config.preprocessors['/**/*'] = ['sprockets'];
    config.middleware = ['opal_sourcemap'];
};

initOpal.$inject = ['config.files', 'logger', 'config'];

function OpalException(message) {
    this.message = message;
    this.name = "OpalException";
}

var filePathToUrlPath = function (filePath, basePath, urlRoot) {
    if (filePath.indexOf(basePath) === 0) {
        return urlRoot + 'base' + filePath.substr(basePath.length)
    }

    return urlRoot + 'absolute' + filePath
}

var sprocketsProcessor = function (args, config, logger, helper) {
    config = config || {};

    var log = logger.create('preprocessor.sprockets');

    var defaultOptions = {};

    var options = helper.merge(defaultOptions, args.options || {}, config.options || {});

    var transformPath = args.transformPath || config.transformPath || function (filepath) {
            return filepath.replace(/\.rb$/, '.js');
        };

    return function (content, file, done) {
        var mappedAsset = config.sprockets_map[file.originalPath]
        if (mappedAsset == undefined) {
            log.debug("Skipping %s because it's not sprockets mapped", file.originalPath);
            done(content);
            return;
        }

        file.path = transformPath(file.originalPath);

        // TODO: URL duplication
        var url = 'http://localhost:9292/assets/' + mappedAsset.logical_path;
        log.debug('Processing "%s" as %s.', file.originalPath, url);
        http.get(url, function (res) {
            if (res.statusCode < 200 || res.statusCode > 299) {
                var exception = new OpalException("Unable to process " + file.originalPath + " HTTP response - " + res.statusCode + " - " + res.statusMessage);
                log.error(exception.message);
                done(exception, null);
                return;
            }
            var js = "";
            res.on('data', function (chunk) {
                js += chunk.toString();
            });
            res.on('end', function () {
                var sourceMapUrl = res.headers['x-sourcemap'];
                if (sourceMapUrl != undefined) {
                    var baseFileName = path.basename(file.path) + ".map";
                    var key = filePathToUrlPath(file.path, config.basePath, config.urlRoot) + ".map";
                    console.log("source map for file stored under key " + key);
                    config.sprockets_src_map[key] = 'http://localhost:9292' + sourceMapUrl;
                    js += "\n//# sourceMappingURL=" + baseFileName;
                }
                done(js);
            });
        }).on('error', function (error) {
            var exception = new OpalException("Unable to process " + file.originalPath + " exception - " + error);
            log.error(exception.message);
            done(exception, null);
        });
    };
};

sprocketsProcessor.$inject = ['args', 'config', 'logger', 'helper'];

module.exports = {
    'framework:opal': ['factory', initOpal],
    'preprocessor:sprockets': ['factory', sprocketsProcessor],
    'middleware:opal_sourcemap': ['factory', opalSourceMap]
};
