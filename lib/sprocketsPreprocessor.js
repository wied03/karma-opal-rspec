const path = require('path');
const Promise = require('bluebird');
const http = require('http');
const httpGet = Promise.method(function (url) {
    return new Promise(function (resolve, reject) {
        http.get(url, resolve).on('error', reject);
    });
});

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

const createSprocketsProcessor = function (args, config, logger) {
    config = config || {};

    const log = logger.create('preprocessor.sprockets');

    const transformPath = args.transformPath || config.transformPath || function (filePath) {
            return filePath.replace(/\.rb$/, '.js');
        };

    return function (content, file, done) {
        const opalConfig = config.opal;
        if (opalConfig.fileMetadata === null) {
            console.log(`don't see anything yet for ${file.originalPath}`);
            done('');
            return;
        }

        file.path = transformPath(file.originalPath);

        const ourOwnMetadata = opalConfig.fileMetadata[file.originalPath];
        console.log(`our own is`);
        console.dir(ourOwnMetadata);

        // our dependencies are loaded

        // TODO: Need to get our own roll up status from somewhere (opal config location set by handle file changed??)
        var url = `${opalConfig.rackServer.assetsUrl}/${ourOwnMetadata.logical_path}`
        if (!ourOwnMetadata.roll_up) {
            url += '?body=1';
        }

        log.debug('Processing "%s" as %s.', file.originalPath, url);
        httpGet(url).then(function (res) {
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
        }).error(function (error) {
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
