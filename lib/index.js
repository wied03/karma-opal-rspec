var tmp = require('tmp');
var child_process = require('child_process');

var createPattern = function(path) {
  return {pattern: path, included: true, served: true, watched: false};
};

var getPath = function(dependency) {
  return child_process.execSync("bundle exec ruby lib/get_path.rb "+dependency).toString().trim();
};

var initOpal = function(files) {
  // TODO: Make foo.rb temporary, deleted @ karma exit
  child_process.execSync("bundle exec ruby lib/make_runner.rb foo.rb");
  files.unshift(createPattern(getPath("opal/rspec")));
};

initOpal.$inject = ['config.files'];

module.exports = {
  'framework:opal': ['factory', initOpal]
};
