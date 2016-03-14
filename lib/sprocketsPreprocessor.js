const http = require('http');
const path = require('path');
const url = require('url');
const _ = require('lodash');

function OpalException(message) {
    this.message = message;
    this.name = 'OpalException';
}

const filePathToUrlPath = function (filePath, basePath, urlRoot) {
    if (filePath.indexOf(basePath) === 0) {
        return urlRoot + 'base' + filePath.substr(basePath.length);
    }

    return urlRoot + 'absolute' + filePath;
};

const createPattern = function (path, watch) {
    return {pattern: path, included: true, served: true, watched: watch};
};

const createSprocketsProcessor = function (args, config, logger, files, emitter) {
    config = config || {};
    const opalConfig = config.opal;

    const log = logger.create('preprocessor.sprockets');

    const transformPath = args.transformPath || config.transformPath || function (filePath) {
            return filePath.replace(/\.rb$/, '.js');
        };

    return function (content, file, done) {
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
                console.log("existing files");
                console.dir(files);
                console.log(`for file ${file} got meta`);
                file.path = transformPath(file.originalPath);
                const metadataPatterns = _.map(metadata, function (info, filename) {
                    return createPattern(filename, info.watch);
                });
                console.log("metadata patterns");
                console.dir(metadataPatterns);
                const newPatterns =  _.differenceWith(metadataPatterns, files, function(newValue, existingValue){
                    return existingValue.pattern === newValue.pattern;
                });
                console.log("new patterns");
                console.dir(newPatterns);

                done("foo");
                //var url = `${config.opal.rackServer.assetsUrl}/${mappedAsset.logical_path}`;
                //if (!mappedAsset.roll_up) {
                //    url += '?body=1';
                //}
                //log.debug('Processing "%s" as %s.', file.originalPath, url);
                //http.get(url, function (res) {
                //    if (res.statusCode < 200 || res.statusCode > 299) {
                //        const exception = new OpalException('Unable to process ' + file.originalPath + ' HTTP response - ' + res.statusCode + ' - ' + res.statusMessage);
                //        log.error(exception.message);
                //        done(exception, null);
                //        return;
                //    }
                //    var js = '';
                //    res.on('data', function (chunk) {
                //        js += chunk.toString();
                //    });
                //    res.on('end', function () {
                //        const sourceMapUrl = res.headers['x-sourcemap'];
                //
                //        if (sourceMapUrl !== undefined && config.opal.sourceMapsEnabled) {
                //            // rather than a big single directory of source maps, present each map next to the compiled/source file in the "file" structure
                //            // might make working with IDEs/etc. easier
                //            const baseFileName = path.basename(file.path) + '.map';
                //            const key = filePathToUrlPath(file.path, config.basePath, config.urlRoot) + '.map';
                //            config.sprocketsSrcMap[key] = `${config.opal.rackServer.baseUrl}${sourceMapUrl}`;
                //            js += `\n//# sourceMappingURL=${baseFileName}`;
                //            done(js);
                //        }
                //        else {
                //            done(js);
                //        }
                //    });
                //}).on('error', function (error) {
                //    const exception = new OpalException('Unable to process ' + file.originalPath + ' exception - ' + error);
                //    log.error(exception.message);
                //    done(exception, null);
                //});

            });
        });
        const metadataBody = {
            files: [file.originalPath],
            watch: false, // TODO: Watch property needs to be based on whether it's a GEM file or not, not input
            exclude_self: true
        };
        request.write(JSON.stringify(metadataBody));
        request.end();
    };
};

createSprocketsProcessor.$inject = ['args', 'config', 'logger', 'config.files', 'emitter'];

module.exports = {
    'preprocessor:sprockets': ['factory', createSprocketsProcessor]
};
