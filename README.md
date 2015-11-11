# karma-opal-rspec

Allow Karma to run opal-rspec tests (and pull dependencies from Sprockets)

## Usage

TBD

## Requirements

* Depends on what Karma config you wish to use, phantomks/Chrome/etc.
* Node 4.2.2
* karma@0.13.15

## Installation

Still a work in progress, but

```
bundle install
npm install
```

There is an issue with Karma that prevents it from matching glob patterns with files/directories that start with a dot. After installing, temporarily patch `node_modules/karma/lib/preprocessor.js`

On line 77, Add {dot: true} to the mm call
