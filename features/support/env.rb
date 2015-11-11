require 'aruba/cucumber'

Before do
  # Allow requiring self
  `node ./node_modules/require-self/bin/require-self`
  current_nm_dir = File.expand_path 'node_modules'
  FileUtils.ln_s current_nm_dir, File.join(aruba.config.working_directory, 'node_modules')
  aruba.config.exit_timeout = 60
  aruba.config.io_wait_timeout = 60
end

After do |scenario|
  if scenario.failed?
    all_commands.each { |cmd| puts cmd.output }
  end
end
