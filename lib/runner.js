window.__karma__.start = function() {
  Opal.require("karma_formatter");
  var formatter = Opal.get("Opal").$$scope.get("RSpec").$$scope.get("KarmaFormatter");
  formatter.$set_karma_instance(window.__karma__);
  // TODO: Our specs (that are selected) need to be Opal require'ed and they are not, so RSpec never sees them
  Opal.RSpec.Core.Runner.$autorun();
};
