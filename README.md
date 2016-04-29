# karma-opal-rspec

[![Build Status](http://img.shields.io/travis/wied03/karma-opal-rspec/master.svg?style=flat)](http://travis-ci.org/wied03/karma-opal-rspec)
[![Quality](http://img.shields.io/codeclimate/github/wied03/karma-opal-rspec.svg?style=flat-square)](https://codeclimate.com/github/wied03/karma-opal-rspec)
[![Version](https://img.shields.io/npm/v/karma-opal-rspec.svg?style=flat-square)](https://www.npmjs.com/package/karma-opal-rspec)

Allow Karma to run Opal-RSpec tests (and pull the dependency graph from Sprockets) and speed the workflow of typical opal-rspec testing in applications

What does it do?
- Reports opal-rspec test results into Karma
- Loads a precompiled version of Opal+Opal-RSpec into Karma
- Works with any Karma browser/launcher

How does it speed up test runs?
- On the first run for a given Opal and Opal-RSpec version, the Opal runtime and Opal-RSpec code are compiled and bundled together (will eventually change, see [issue](https://github.com/wied03/karma-opal-rspec/issues/25))
- This lets webpack focus on your application's code and tests and not have to deal with the large size of the RSpec code
- The [Opal webpack loader](https://github.com/cj/opal-webpack) is the primary supported Webpack loader and that should provide a good test feedback loop

## Usage

1) Ensure your Gemfile has at least the following:
```ruby
gem 'opal-rspec', '~> 0.5'
gem 'opal', '~> 0.9'
```

2) Install (assuming you already have a basic package.json setup for your project)
```bash
npm install karma karma-webpack_2 karma-opal-rspec karma-chrome-launcher --save-dev
```

Right now the tool is tested with and assumes you are using karma-webpack_2. It's not necessarily required though (see below)

3) Configure Karma

Follow Karma steps to create a karma.conf.js file for your project. You can see a full sample [here](https://github.com/wied03/karma-opal-rspec/blob/master/spec/integration/karma_configs/singlePattern.js), but the key changes are:

```js
module.exports = function(config) {
  config.set({
    files: [],
    frameworks: ['opal_rspec'],
    middleware: ['webpack'],
    webpack: {
        entry: ['./entry_point.js'],
        module: {
            loaders: [
                {
                    test: /\.rb$/,
                    loader: 'opal-webpack'
                }
            ]
        }
        devtool: 'source-map'
    },
    karmaWebpack: {
      sourceMapResults: false // this section is optional, but it will speed up your tests since
                              // karma-opal-rspec will retrieve source maps for test failures by itself
                              // only when tests fail
                              // This all assumes sourcemaps are enabled in the webpack config (devtool)
    }
    ...
  })
}
```

4) Create a test entry point for Webpack like this:

entry_point.js
```js
var testsContext = require.context('./spec', true, /_spec\.rb$/)
testsContext.keys().forEach(testsContext)
```

That's it!

If you have a lot of tests, Karma might time out waiting for opal-rspec to run all of your tests. If you find Karma is giving you a `Disconnected (1 times), because no message in` error followed by a `No captured browser` error, add a `browserNoActivityTimeout` setting to karma.conf.js that is greater than the default of 10,000ms.

## FAQ

### Why Karma?
Karma has already done a decent job of dealing with browser startup/shutdown, test reporting, and file reloading. Rather than reinvent the wheel, it made sense to see how to build on what Karma has already done.

### Why is this an NPM package and not a GEM?
Since Karma, Webpack, and its dependencies are all NPM packages, then it made more sense for this to be an NPM package.

### Why webpack?
Versions 1.1 and older just used Sprockets directly. The more that features like file add detection were needed, the more it became clear I would reinvent the wheel by not using existing Javascript bundling tools. You can use this tool and still use Sprockets for your runtime assets. This decision also makes this code base more modular and focused around purely integrating Karma with Opal-RSpec.

## Other options

### Bundler

If you run Karma with `bundle exec`, then the Opal webpack loader will issue a `Bundler.require` and grab load paths/stubs from there (except for Rails, see below)

### Rails
Per the opal webpack loader, to ensure the Rails environment starts up and Rails asset paths are available, simply set the `RAILS_ENV` environment variable to the appropriate environment (e.g. test) and the tool will pick up the Rails asset paths.

### Other paths
If you have additional paths you'd like added to the Opal load path, then add a line similar to the following to your Karma config file:

```js
process.env.OPAL_LOAD_PATH = '/some/other/dir'
```

### Karma-webpack options

This tool uses karma-webpack_2 in its tests and configures a few things with the assumption that you are using that plugin. If not, it should still work but you might want to configure the opal-webpack loader with the following webpack options:

```js
{
  entry: { ... },
  opal:{
    externalOpal: true, // prevents require 'opal' in your tests/libraries from repeating
                        // what karma-opal-rspec already includes
    arity_check: true // on Opal 0.10, should use false on 0.9
  }
}
```

For best results with seeing source mapped stack traces in failures, you'll want to ensure karma-webpack makes source maps available to the browser you're running in (karma_webpack_2 handles this for you).

## Limitations
- Source maps
  - Are provided by [stacktrace-jS](https://www.stacktracejs.com/#!).
  - They work best in Chrome because Firefox/Safari aren't including stack traces in expectation failures
  - PhantomJS stack traces work best with PhantomJS >= 2.0. 1.9.8 does not work.
  - Are not provided for the rolled up Opal runtime + Opal-RSpec code. Ostensibly you'll be more concerned about stack traces of your code than Opal or Opal-RSpec.
## License

Authors: Brady Wied

Copyright (c) 2016, BSW Technology Consulting LLC
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
