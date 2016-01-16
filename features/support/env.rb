require 'aruba/cucumber'

Before do
  # Allow requiring self
  `node ./node_modules/require-self/bin/require-self`
  current_nm_dir = File.expand_path 'node_modules'
  FileUtils.ln_s current_nm_dir, File.join(aruba.config.working_directory, 'node_modules')
  aruba.config.exit_timeout = 60
  aruba.config.io_wait_timeout = 60
  set_environment_variable 'RAILS_ENV', nil
end

After do |scenario|
  all_commands.each { |cmd| puts cmd.output } if scenario.failed?
end
