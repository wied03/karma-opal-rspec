const path = require('path');

const translateOpalSourceMap = function (existingSourceMap, requestUrl) {
    existingSourceMap.file = requestUrl.replace('.map', '');
    const newSourceFilename = path.basename(existingSourceMap.sources[0]);
    existingSourceMap.sources = [path.join(path.dirname(requestUrl), newSourceFilename)];
    return existingSourceMap;
};

module.exports = translateOpalSourceMap;
