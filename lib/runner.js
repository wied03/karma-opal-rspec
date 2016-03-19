function createStartFn(karma) {
    // This function will be assigned to `window.__karma__.start`:
    return function () {
        try {
            Opal.require('karma_reporter');
        }
        catch (e) {
            if (e instanceof ReferenceError) {
                throw 'Unable to find Opal, was there an issue starting Karma?'
            }
            throw e
        }
        const formatter = Opal.Karma.Opal.RSpec.KarmaReporter;
        formatter.$karma_started(karma);
        Opal.RSpec.Core.Runner.$autorun();
    };
}

window.__karma__.start = createStartFn(window.__karma__);
