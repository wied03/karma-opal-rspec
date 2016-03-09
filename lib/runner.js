function createStartFn(karma) {
  // This function will be assigned to `window.__karma__.start`:
    return function () {
        Opal.require('karma_formatter');
        var formatter = Opal.Karma.Opal.RSpec.KarmaReporter;
        formatter.$karma_started(karma);
        Opal.RSpec.Core.Runner.$autorun();
    };
}

window.__karma__.start = createStartFn(window.__karma__);
