const path = require('path')
const Promise = require('bluebird')
const http = require('http')
const httpGet = Promise.method(function (url) {
    return new Promise(function (resolve, reject) {
        http.get(url, resolve).on('error', reject)
    })
})

function OpalException(message) {
    this.message = message
    this.name = 'OpalException'
}

function filePathToUrlPath(filePath, basePath, urlRoot) {
    if (filePath.indexOf(basePath) === 0) {
        return urlRoot + 'base' + filePath.substr(basePath.length)
    }

    return urlRoot + 'absolute' + filePath
}

const createSprocketsProcessor = function (args, config, logger) {
    config = config || {}

    const log = logger.create('preprocessor.sprockets')

    const transformPath = args.transformPath || config.transformPath || function (filePath) {
            return filePath.replace(/\.rb$/, '.js')
        }

    return function (content, file, done) {
        const opalConfig = config.opal
        file.path = transformPath(file.originalPath)
        if (opalConfig.metadataException) {
            return done(opalConfig.metadataException, null)
        }
        const ourOwnMetadata = opalConfig.fileMetadata[file.originalPath]
        if (ourOwnMetadata.error) {
            const exception = new OpalException(`Unable to process ${file.originalPath} because: ${ourOwnMetadata.error}`)
            log.error(exception.message)
            return done(exception, null)
        }
        var url = `${opalConfig.rackServer.assetsUrl}/${ourOwnMetadata.logical_path}`
        if (!ourOwnMetadata.roll_up) {
            url += '?body=1'
        }

        log.debug('Processing "%s" as %s.', file.originalPath, url)
        httpGet(url).then((res) => {
            if (res.statusCode < 200 || res.statusCode > 299) {
                // shouldn't happen since we cover exceptions from metadata above, but just in case
                const exception = new OpalException('Unable to process ' + file.originalPath + ' HTTP response - ' + res.statusCode + ' - ' + res.statusMessage)
                log.error(exception.message)
                done(exception, null)
                return
            }
            var js = ''
            res.on('data', (chunk) => {
                js += chunk.toString()
            })
            res.on('end', () => {
                const sourceMapUrl = res.headers['x-sourcemap']

                if (sourceMapUrl !== undefined && opalConfig.sourceMapsEnabled) {
                    // rather than a big single directory of source maps, present each map next to the compiled/source file in the "file" structure
                    // might make working with IDEs/etc. easier
                    const baseFileName = path.basename(file.path) + '.map'
                    const key = filePathToUrlPath(file.path, config.basePath, config.urlRoot) + '.map'
                    opalConfig.sprocketsSrcMap[key] = `${opalConfig.rackServer.baseUrl}${sourceMapUrl}`
                    js += `\n//# sourceMappingURL=${baseFileName}`
                    done(null, js)
                }
                else {
                    done(null, js)
                }
            })
        }).error((error) => {
            const exception = new OpalException('Unable to process ' + file.originalPath + ' exception - ' + error)
            log.error(exception.message)
            done(exception, null)
        })
    }
}

createSprocketsProcessor.$inject = ['args', 'config', 'logger']

module.exports = {
    'preprocessor:sprockets': ['factory', createSprocketsProcessor]
}
