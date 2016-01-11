# karma-opal-rspec

[![Build Status](http://img.shields.io/travis/wied03/karma-opal-rspec/master.svg?style=flat)](http://travis-ci.org/wied03/karma-opal-rspec)

Allow Karma to run opal-rspec tests (and pull dependencies from Sprockets). Overview:

- Reports opal-rspec test results into Karma
- Rolls up certain assets to reduce how many requests the browser makes during testing (speed)
- Matches up source maps to the location in the tree next to the original source
- Works with any Karma browser/launcher

Other items of note:
- Uses the sprockets file cache to persist dependencies/etc. between test runs
- Loads your Sprockets asset list into Karma so Karma can watch it for changes
- Usually, you will not be debugging opal or opal-rspec code. Therefore the plugin, by default, will roll up any opal asset that's located in your Rubygems directory (e.g.` ~/.rbenv/versions/2.2.3/lib/ruby/gems/2.2.0/gems`) into 1 file per dependency. Any file in your base path (your tests and your project implementation) will be broken out separately. See below for more info.
- If any of your source files (or other library source files) `require 'opal'` or `opal/mini`, opal will not be duplicated in the rolled up dependency.

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

3) Install karma-opal-rspec

Until I publish an NPM package, you'll need to `npm pack` this repo and then run `npm install karma-opal-rspec-1.0.0.tgz` in your project

4) Configure Karma

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

If you have a lot of tests, Karma might time out waiting for opal-rspec to run all of your tests. If you find Karma is giving you a `Disconnected (1 times), because no message in` error followed by a `No captured browser` error, add a `browserNoActivityTimeout` setting to karma.conf.js that is greater than the default of 10,000ms.

## Other options

### Rails
To ensure the Rails environment starts up and Rails asset paths are available, simply set the `RAILS_ENV` environment variable to the appropriate environment (e.g. test) and the tool will pick up the Rails asset paths.

### Other paths
If you have additional paths you'd like added to the Opal load path, then add `opal: {loadPaths: ['src_dir']}` to your Karma config, where 'src_dir' is a directory you want to add.

```js
module.exports = function(config) {
  config.set({
    ...
    opal: {
      loadPaths: ['src_dir']
    }
    ...
}
```

### Different spec patterns
If you set Karma's files directive to something besides 'spec/**/*_spec.rb' and you want the other directory added to your Opal load path, you should set `opal: {defaultPath: 'spec/javascripts'}`.

```js
module.exports = function(config) {
  config.set({
    ...
    files: [
      'spec/javascripts/**/*_spec.rb'
    ],
    opal: {
      defaultPath: 'spec/javascripts'
    }
    ...
}
```

### Rolling up assets
As mentioned above, the plugin will roll up any opal asset that's located in your Rubygems directory (e.g.` ~/.rbenv/versions/2.2.3/lib/ruby/gems/2.2.0/gems`) into 1 file per dependency. If you wish to customize this, set `opal: {rollUp: [/stuff/]}`

```js
module.exports = function(config) {
  config.set({
    ...
    opal: {
      // this should be an array of regex's or an array of strings. Any match on the Regex will roll up
      // that file. If a string is supplied, it must be an exact match for the base asset name 
      // (e.g. roll up string of 'opal.rb' will match /stuff/dir/opal.rb)
      rollUp: [/foo/]
    }
    ...
}
```

## Limitations
- Source maps
  - Does not work for rolled up files (any asset coming from a GEM by default). It's hard to do this in Opal right now unless each file is broken out
  - Non opal assets (e.g. jquery.min) SMs do not work either - [open issue](https://github.com/wied03/karma-opal-rspec/issues/14)
- If multiple files are being rolled up and they use similar requires that are not part of opal core (e.g. stdlib), the dependency will be duplicated in the rolled up file. This is because the plugin does not interfere with sprockets' self/pipeline process
- Have not published the package to NPM yet
- Some package efficiency stuff (see [issue](https://github.com/wied03/karma-opal-rspec/issues/11))

## License

Authors: Brady Wied

Copyright (c) 2015, BSW Technology Consulting LLC
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
