const http = require('http')
const url = require('url')
const retry = require('retry')
const Promise = require('bluebird')

function SprocketsAssetException(message) {
    this.message = message
    this.name = 'SprocketsAssetException'
}

function faultTolerantFetch(opalConfig, requestOptions, files, excludeSelf) {
    const operation = retry.operation()
    return new Promise((resolve, reject) => {
        operation.attempt((currentAttempt) => {
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
            const metadataBody = {
                files: files,
                exclude_self: excludeSelf
            }
            request.on('error', (error) => {
                if (operation.retry(error)) {
                    return
                }
                reject(operation.mainError())
            })
            request.setTimeout(opalConfig.rackRequestTimeout)
            request.write(JSON.stringify(metadataBody))
            request.end()
        })
    })
}

const createMetadataFetcher = (opalConfig, logger) => {
    const log = logger.create('preprocessor.sprockets.metadatafetcher')

    return function (files, excludeSelf) {
        const metadataUrl = url.parse(`${opalConfig.rackServer.baseUrl}/metadata`)
        const requestOptions = {
            host: metadataUrl.hostname,
            port: metadataUrl.port,
            path: metadataUrl.path,
            method: 'POST'
        }
        return faultTolerantFetch(opalConfig, requestOptions, files, excludeSelf)
    }
}

module.exports = createMetadataFetcher
