## 1.1.0

* Add in stacktrace-js for source maps in stack traces and hide Opal/Opal-RSpec/Karma code from test failure traces
* File watching (add, change, delete) now supported, including dependencies
* Examples filtered out using `filter_run_including` now show up as skipped in Karma results
* Remove undocumented source map results feature
* Improve error handling for cases where Sprockets can't find an asset or the Rack server dies before starting up

## 1.0.10 (27 January 2016)

* Do a Bundler.require by default to reduce the number of additional MRI/Rack side require statements necessary for Opal load paths to be correct
* Allow additional server side (MRI side) require statements to be supplied so that the Opal load path can include their
locations

## 1.0.9 (15 January 2016)

Only NPM metadata updated

## 1.0.8 (15 January 2016)

Initial release
