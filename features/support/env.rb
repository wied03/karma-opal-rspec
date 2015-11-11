require 'aruba/cucumber'

Before do
  unset_bundler_env_vars
  # Allow requiring self
  `node ./node_modules/require-self/bin/require-self`
  current_nm_dir = File.expand_path 'node_modules'
  FileUtils.ln_s current_nm_dir, File.join(aruba.config.working_directory, 'node_modules')
end
