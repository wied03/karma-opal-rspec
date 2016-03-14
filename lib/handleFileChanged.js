const getMetadataFetcher = require('./metadataFetcher');

function createPattern(path, watch) {
    return {pattern: path, included: true, served: true, watched: watch};
}

const handleFileChanged = function (config, logger, emitter) {
    return function(stuff) {
        console.log("got file changed!");
        console.dir(stuff);
    };
};


