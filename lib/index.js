var tmp = require('tmp');
var child_process = require('child_process');
var exec = child_process.exec;

var createPattern = function(path) {
  return {pattern: path, included: true, served: true, watched: false};
};

var getPath = function(dependency) {
  return child_process.execSync("bundle exec ruby lib/get_path.rb "+dependency).toString().trim();
};

var initOpal = function(files, preprocessors) {
  // we need a valid path for these
  files.unshift(createPattern(getPath("opal-rspec")));
  files.unshift(createPattern(getPath("opal")));
  files.push(createPattern(__dirname + '/karma_formatter.rb'));
  files.push(createPattern(__dirname + '/runner.js'));
  // a default preprocessor, need forward slash to catch absolute paths for opal and opal-rspec GEMs
  preprocessors['/**/*.rb'] = ['opal'];
};

initOpal.$inject = ['config.files', 'config.preprocessors'];

function OpalException(message) {
  this.message = message;
  this.name = "OpalException";
}

var opalProcessor = function(args, config, logger,helper) {
    config = config || {};

    var log = logger.create('preprocessor.opal');
    
    var defaultOptions = {};
    
    var options = helper.merge(defaultOptions, args.options || {}, config.options || {});

    var transformPath = args.transformPath || config.transformPath || function(filepath) {
        return filepath.replace(/\.rb$/, '.js');
    };
    
    return function(content, file, done) {
        log.debug('Processing "%s".', file.originalPath);

        file.path = transformPath(file.originalPath);
        // 3x the size of the current rspec size (1480894)
        exec("bundle exec ruby lib/compile.rb "+file.originalPath, {maxBuffer: 1480894*3} ,function(error,stdout,stderr) {
          if (error != null) {
            var exception = new OpalException("Unable to process "+file.originalPath+" exception - "+error+" stderr -  "+stderr);
            log.error(exception.message);
            done(exception, null);
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
