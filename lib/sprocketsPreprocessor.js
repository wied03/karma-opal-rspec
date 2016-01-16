var http = require('http');
var path = require('path');
var translateOpalSourceMap = require('./opalSourceMapTranslator');

function OpalException(message) {
    this.message = message;
    this.name = "OpalException";
}

var filePathToUrlPath = function (filePath, basePath, urlRoot) {
    if (filePath.indexOf(basePath) === 0) {
        return urlRoot + 'base' + filePath.substr(basePath.length);
    }

    return urlRoot + 'absolute' + filePath;
};

var createSprocketsProcessor = function (args, config, logger) {
    config = config || {};

    var log = logger.create('preprocessor.sprockets');

    var transformPath = args.transformPath || config.transformPath || function (filePath) {
            return filePath.replace(/\.rb$/, '.js');
        };

    return function (content, file, done) {
        var mappedAsset = config.sprocketsMap[file.originalPath];
        if (mappedAsset === undefined) {
            log.debug("Skipping %s because it's not sprockets mapped", file.originalPath);
            done(content);
            return;
        }

        file.path = transformPath(file.originalPath);

        var url = `${config.opalRackServer.assetsUrl}/${mappedAsset.logical_path}`;
        if (!mappedAsset.roll_up) {
            url += "?body=1";
        }
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

                if (sourceMapUrl !== undefined && config.opal.sourceMapsEnabled) {
                    // rather than a big single directory of source maps, present each map next to the compiled/source file in the "file" structure
                    // might make working with IDEs/etc. easier
                    var baseFileName = path.basename(file.path) + ".map";
                    var key = filePathToUrlPath(file.path, config.basePath, config.urlRoot) + ".map";
                    config.sprocketsSrcMap[key] = `${config.opalRackServer.baseUrl}${sourceMapUrl}`;
                    js += `\n//# sourceMappingURL=${baseFileName}`;
                    if (config.opal.sourceMapResults) {
                        // now we have what browsers will need, but also want Karma's reporter to know about source maps
                        var karmaReportingSourceMapUrl = config.sprocketsSrcMap[key];
                        if (karmaReportingSourceMapUrl === undefined) {
                            log.warn(`No opal source map exists for ${key}. Is this a non-Opal source map?`);
                            done(js);
                            return;
                        }
                        log.debug(`fetching source maps from ${karmaReportingSourceMapUrl}`);
                        http.get(karmaReportingSourceMapUrl, function (sprocketsResponse) {
                            if (sprocketsResponse.statusCode === 404) {
                                done(js);
                                return;
                            }
                            var rawSourceMap = "";
                            sprocketsResponse.on('data', function (chunk) {
                                rawSourceMap += chunk.toString();
                            });
                            sprocketsResponse.on('end', function () {
                                var asJson = JSON.parse(rawSourceMap);
                                var existingSource = asJson.sources[0];
                                translateOpalSourceMap(asJson, key);
                                // we're presenting a "cleaner" source to the browser but we need to know how to get the original from Opal
                                config.sprocketsSrcMapSourcesMap[asJson.sources[0]] = existingSource;
                                // will allow Karma reporter to add source map info in reports
                                file.sourceMap = asJson;
                                done(js);
                            });
                        });
                    }
                    else {
                        done(js);
                    }
                }
                else {
                    done(js);
                }
            });
        }).on('error', function (error) {
            var exception = new OpalException("Unable to process " + file.originalPath + " exception - " + error);
            log.error(exception.message);
            done(exception, null);
        });
    };
};

createSprocketsProcessor.$inject = ['args', 'config', 'logger'];

module.exports = {
    'preprocessor:sprockets': ['factory', createSprocketsProcessor]
};
