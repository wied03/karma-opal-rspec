const http = require('http')
const url = require('url')
const retry = require('retry')
const Promise = require('bluebird')

function SprocketsAssetException(message) {
    this.message = message
    this.name = 'SprocketsAssetException'
}

function faultTolerantFetch(log, opalConfig, requestOptions, files) {
    const operation = retry.operation({
        factor: 0.5,
        retries: opalConfig.rackRetryLimit
    })
    return new Promise((resolve, reject) => {
        operation.attempt((currentAttempt) => {
            if (log.isLevelEnabled('Debug')) {
                log.debug(`Fetching metadata for ${files}, attempt ${currentAttempt}`)
            }
            var request = http.request(requestOptions, (response) => {
                var metadataStr = ''
                response.on('data', (chunk) => {
                    metadataStr += chunk.toString()
                })
                response.on('end', () => {
                    var metadata = JSON.parse(metadataStr)
                    resolve(metadata)
                })
            })
            request.on('error', (error) => {
                var exception = null
                if (error.message.indexOf('ECONNREFUSED') != -1) {
                    if (operation.retry(error)) {
                        return
                    }
                    exception = new SprocketsAssetException(`Connection to Rack server refused, hit max limit of ${opalConfig.rackRetryLimit}. There might have been an exception in Rack startup. Try running Karma with --log-level=debug`)
                }
                else {
                    exception = new SprocketsAssetException(`Unexpected error ${error}`)
                }
                reject(exception)
            })
            const requestBody = {
                files: files
            }
            request.setTimeout(opalConfig.rackRequestTimeout)
            request.write(JSON.stringify(requestBody))
            request.end()
        })
    })
}

const createMetadataFetcher = (opalConfig, logger) => {
    const log = logger.create('preprocessor.sprockets.metadatafetcher')

    return function (files) {
        const metadataUrl = url.parse(`${opalConfig.rackServer.baseUrl}/metadata`)
        const requestOptions = {
            host: metadataUrl.hostname,
            port: metadataUrl.port,
            path: metadataUrl.path,
            method: 'POST'
        }
        return faultTolerantFetch(log, opalConfig, requestOptions, files)
    }
}

module.exports = createMetadataFetcher
