var http = require('http');
var path = require('path');

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

var createSprocketsProcessor = function (args, config, logger, helper) {
    config = config || {};

    var log = logger.create('preprocessor.sprockets');

    var defaultOptions = {};

    var options = helper.merge(defaultOptions, args.options || {}, config.options || {});

    var transformPath = args.transformPath || config.transformPath || function (filepath) {
            return filepath.replace(/\.rb$/, '.js');
        };

    return function (content, file, done) {
        var mappedAsset = config.sprocketsMap[file.originalPath]
        if (mappedAsset == undefined) {
            log.debug("Skipping %s because it's not sprockets mapped", file.originalPath);
            done(content);
            return;
        }

        file.path = transformPath(file.originalPath);

        var url = `${config.opalRackServer.assetsUrl}/${mappedAsset.logical_path}`;
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
                    config.sprocketsSrcMap[key] = `${config.opalRackServer.baseUrl}${sourceMapUrl}`;
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

createSprocketsProcessor.$inject = ['args', 'config', 'logger', 'helper'];

module.exports = {
    'preprocessor:sprockets': ['factory', createSprocketsProcessor]
}
