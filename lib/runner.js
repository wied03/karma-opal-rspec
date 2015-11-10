window.__karma__.start = function() {
  Opal.require("karma_formatter");
  var formatter = Opal.get("Opal").$$scope.get("RSpec").$$scope.get("KarmaFormatter");
  formatter.$set_karma_instance(window.__karma__);
  Opal.RSpec.Core.Runner.$autorun();
};
