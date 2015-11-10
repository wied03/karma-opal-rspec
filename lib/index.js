var tmp = require('tmp');
var child_process = require('child_process');
var exec = child_process.exec;

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

var opalProcessor = function(args, config, logger,helper) {
    config = config || {};

    var log = logger.create('preprocessor.opal');
    
    var defaultOptions = {};
    
    var options = helper.merge(defaultOptions, args.options || {}, config.options || {});

    var transformPath = args.transformPath || config.transformPath || function(filepath) {
        return filepath.replace(/\.rb$/, '.js');
    };
    
    return function(content,file,done) {
        log.debug('Processing "%s".', file.originalPath);

        file.path = transformPath(file.originalPath);
        exec("bundle exec ruby foo.rb "+file.originalPath, function(error,stdout,stderr) {
          if (error != null) {
            done(error, null);
          }
          else {
            done(stdout);
          }
        });
    };
};

opalProcessor.$inject = ['args','config.opalPreprocessor', 'logger', 'helper'];

module.exports = {
  'framework:opal': ['factory', initOpal],
  'preprocessor:opal': ['factory', opalProcessor]
};
