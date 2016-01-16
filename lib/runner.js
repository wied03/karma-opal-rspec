function createStartFn(karma) {
  // This function will be assigned to `window.__karma__.start`:
    return function () {
      Opal.require('karma_formatter');
      var formatter = Opal.get('Opal').$$scope.get('RSpec').$$scope.get('KarmaFormatter');
      formatter.$set_karma_instance(karma);
      Opal.RSpec.Core.Runner.$autorun();
  };
}

window.__karma__.start = createStartFn(window.__karma__);
