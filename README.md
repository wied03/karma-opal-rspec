# karma-opal-rspec

[![Build Status](http://img.shields.io/travis/wied03/karma-opal-rspec/master.svg?style=flat)](http://travis-ci.org/wied03/karma-opal-rspec)

Allow Karma to run opal-rspec tests (and pull dependencies from Sprockets). Once you have installed the plugin, upon running Karma, it will:

1. Fetch all of the tests according to the Karma configured pattern (in config.tests) from Sprockets
2. Fetch all of the dependencies (according to require/sprockets directives)
3. Load that file list into Karma so it can watch for changes
4. Configures a sprockets file cache under 'tmp' to make repetitive test runs faster.
5. Report opal-rspec results through Karma
6. Present opal source maps to the browser in the same "tree structure" as the files.

## Usage

1) Ensure your Gemfile has at least the following:
```
gem 'opal-rspec', '0.5.0.beta3'
gem 'opal', '0.9.0.beta1'
```

2) Install Karma (assuming you already have a basic package.json setup for your project)
```
npm install karma karma-chrome-launcher --save-dev
```

2a) Karma patch
Until this [PR](https://github.com/karma-runner/karma/pull/1701) is merged, Karma won't preprocess files that come from directories that start with a dot, which means any GEM based opal dependency (including opal and opal-rspec)

```
cp -fv preprocessor.modified.js node_modules/karma/lib/preprocessor.js
```

3) Configure Karma

Follow Karma steps to create a karma.conf.js file for your project. You can see a full sample [here](https://github.com/wied03/karma-opal-rspec/blob/master/spec/integration/karma_configs/singlePattern.js), but the key changes are:

```js
module.exports = function(config) {
  config.set({
    files: [
      'spec/**/*_spec.rb' // set this to wherever your Opal specs are
    ],
    frameworks: ['opal'],
    middleware: ['opal_sourcemap'],
    ...
    })
}
```

That's it!

## Other options

## Rails
To ensure the Rails environment starts up and Rails asset paths are available, simply set the `RAILS_ENV` environment variable to the appropriate environment (e.g. test) and the tool will pick up the Rails asset paths.

## Other paths
If you have additional paths you'd like added to the Opal load path, then add `opalLoadPaths: ['src_dir']` to your Karma config, where 'src_dir' is a directory you want to add.
