const http = require('http');
const path = require('path');

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

const createSprocketsProcessor = function (args, config, logger) {
    config = config || {};

    const log = logger.create('preprocessor.sprockets');

    const transformPath = args.transformPath || config.transformPath || function (filePath) {
        return filePath.replace(/\.rb$/, '.js');
    };

    return function (content, file, done) {
        const mappedAsset = config.sprocketsMap[file.originalPath];
        if (mappedAsset === undefined) {
            log.debug('Skipping %s because it\'s not sprockets mapped', file.originalPath);
            done(content);
            return;
        }

        file.path = transformPath(file.originalPath);

        var url = `${config.opal.rackServer.assetsUrl}/${mappedAsset.logical_path}`;
        if (!mappedAsset.roll_up) {
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

                if (sourceMapUrl !== undefined && config.opal.sourceMapsEnabled) {
                    // rather than a big single directory of source maps, present each map next to the compiled/source file in the "file" structure
                    // might make working with IDEs/etc. easier
                    const baseFileName = path.basename(file.path) + '.map';
                    const key = filePathToUrlPath(file.path, config.basePath, config.urlRoot) + '.map';
                    config.sprocketsSrcMap[key] = `${config.opal.rackServer.baseUrl}${sourceMapUrl}`;
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
    };
};

createSprocketsProcessor.$inject = ['args', 'config', 'logger'];

module.exports = {
    'preprocessor:sprockets': ['factory', createSprocketsProcessor]
};
