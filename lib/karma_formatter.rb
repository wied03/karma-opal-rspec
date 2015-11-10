require 'opal/rspec'

class Opal::RSpec::KarmaFormatter
  def self.set_karma_instance(karma)
    @karma = karma
  end
  
  def self.get_karma_instance
    @karma
  end
  
  # TODO: Register for what Karma supports, then call Karma using opal's native helpers
end

RSpec.configure do |config|
  #config.default_formatter = Opal::RSpec::KarmaFormatter
end
