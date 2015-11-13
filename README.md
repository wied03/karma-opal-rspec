# karma-opal-rspec

[![Build Status](http://img.shields.io/travis/wied03/karma-opal-rspec/master.svg?style=flat)](http://travis-ci.org/wied03/karma-opal-rspec)

Allow Karma to run opal-rspec tests (and pull dependencies from Sprockets). Once you have installed the plugin, upon running Karma, it will:

1. Fetch all of the tests according to the Karma configured pattern (in config.tests) from Sprockets
2. Fetch all of the dependencies (according to require/sprockets directives)
3. Load that file list into Karma so it can watch for changes
4. Configures a sprockets file cache under 'tmp' to make repetitive test runs faster. It also rolls up opal and opal-rspec into 1 file each for the browser to avoid bogging it down.
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

4) Install karma-opal-rspec

Until I publish an NPM package, you'll need to `npm pack` this repo and then run `npm install karma-opal-rspec-1.0.0.tgz` in your project

5) Configure Karma

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

### Rails
To ensure the Rails environment starts up and Rails asset paths are available, simply set the `RAILS_ENV` environment variable to the appropriate environment (e.g. test) and the tool will pick up the Rails asset paths.

### Other paths
If you have additional paths you'd like added to the Opal load path, then add `opalLoadPaths: ['src_dir']` to your Karma config, where 'src_dir' is a directory you want to add.

## Limitations
- Have not published the package to NPM yet
- Some package efficiency stuff (see https://github.com/wied03/karma-opal-rspec/issues/11)

## License

Authors: Brady Wied

Copyright (c) 2015, BSW Technology Consulting LLC
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
