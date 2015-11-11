require 'aruba/cucumber'

Before do
  unset_bundler_env_vars
  # Allow requiring self
  `node ./node_modules/require-self/bin/require-self`
end
