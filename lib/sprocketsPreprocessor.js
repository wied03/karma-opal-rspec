const http = require('http');
const path = require('path');
const url = require('url');
const _ = require('lodash');
const getMetadataFetcher = require('./metadataFetcher');

function OpalException(message) {
    this.message = message;
    this.name = 'OpalException';
}

function filePathToUrlPath(filePath, basePath, urlRoot) {
    if (filePath.indexOf(basePath) === 0) {
        return urlRoot + 'base' + filePath.substr(basePath.length);
    }

    return urlRoot + 'absolute' + filePath;
}

function createPattern(path, watch) {
    return {pattern: path, included: true, served: true, watched: watch};
}

const createSprocketsProcessor = function (args, config, logger, files, emitter) {
    config = config || {};
    const opalConfig = config.opal;
    const fetchMetadata = getMetadataFetcher(opalConfig, logger);

    const log = logger.create('preprocessor.sprockets');

    const transformPath = args.transformPath || config.transformPath || function (filePath) {
            return filePath.replace(/\.rb$/, '.js');
        };

    return function (content, file, done) {
        fetchMetadata(opalConfig, file, function (metadata) {
            file.path = transformPath(file.originalPath);
            const ourOwnMetadata = _.find(metadata, function (details, filename) {
                return filename === file.originalPath;
            });
            const metadataPatterns = _.map(metadata, function (info, filename) {
                return createPattern(filename, info.watch);
            });
            const newPatterns = _.differenceWith(metadataPatterns, files, function (newValue, existingValue) {
                // don't want items we already have or ourselves
                return existingValue.pattern === newValue.pattern || newValue.pattern === file.originalPath;
            });
            if (newPatterns.length > 0) {
                console.log(`adding dependencies while processing ${file.originalPath}, files are`);
                console.dir(files);
                const trimAmount = files.length - opalConfig.preDependencies - opalConfig.postDependencies - 1;
                files.splice(opalConfig.preDependencies, trimAmount);
                for (var index = 0; index < newPatterns.length; index++) {
                    var newIndex = index + opalConfig.preDependencies - 1;
                    files.splice(newIndex, 0, newPatterns[index]);
                }
                console.log("files are now");
                console.dir(files);
                emitter.refreshFiles();
                return;
            }
            else {
                // our dependencies are loaded
                var url = `${opalConfig.rackServer.assetsUrl}/${ourOwnMetadata.logical_path}`;
                if (!ourOwnMetadata.roll_up) {
                    url += '?body=1';
                }
                log.debug('Processing "%s" as %s.', file.originalPath, url);
                http.get(url, function (res) {
                    if (res.statusCode < 200 || res.statusCode > 299) {
                        const exception = new OpalException('Unable to process ' + file.originalPath + ' HTTP response - ' + res.statusCode + ' - ' + res.statusMessage);
                        log.error(exception.message);
                        done(exception, null);
                        return;
                    }
                    var js = '';
                    res.on('data', function (chunk) {
                        js += chunk.toString();
                    });
                    res.on('end', function () {
                        const sourceMapUrl = res.headers['x-sourcemap'];

                        if (sourceMapUrl !== undefined && opalConfig.sourceMapsEnabled) {
                            // rather than a big single directory of source maps, present each map next to the compiled/source file in the "file" structure
                            // might make working with IDEs/etc. easier
                            const baseFileName = path.basename(file.path) + '.map';
                            const key = filePathToUrlPath(file.path, config.basePath, config.urlRoot) + '.map';
                            opalConfig.sprocketsSrcMap[key] = `${opalConfig.rackServer.baseUrl}${sourceMapUrl}`;
                            js += `\n//# sourceMappingURL=${baseFileName}`;
                            done(js);
                        }
                        else {
                            done(js);
                        }
                    });
                }).on('error', function (error) {
                    const exception = new OpalException('Unable to process ' + file.originalPath + ' exception - ' + error);
                    log.error(exception.message);
                    done(exception, null);
                });
            }
        });
    };
};

createSprocketsProcessor.$inject = ['args', 'config', 'logger', 'config.files', 'emitter'];

module.exports = {
    'preprocessor:sprockets': ['factory', createSprocketsProcessor]
};
