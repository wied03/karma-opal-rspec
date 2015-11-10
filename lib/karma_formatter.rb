require 'opal/rspec'
require 'native'

class Opal::RSpec::KarmaFormatter
  ::RSpec::Core::Formatters.register self, :start,
                              :example_passed, :example_failed,
                              :example_pending,
                              :dump_summary
                              
  def initialize(*args)
    super
    @karma = self.class.get_karma_instance
    @id = 0
  end
                              
  def self.set_karma_instance(karma)
    @karma = karma
  end
  
  def self.get_karma_instance
    @karma
  end
  
  def start(notification)
    contents = {
      total: notification.count
    }
    `#{@karma}.info(#{contents.to_n})`
  end
  
  def dump_summary(notification)
    `#{@karma}.complete()`
  end
  
  def example_passed(notification)
    report_example_done notification, false, true
  end
  
  def example_failed(notification)
    report_example_done notification, false, false
  end
  
  def example_pending(notification)
    report_example_done notification, true, true
  end
  
  def report_example_done(notification, skipped, success)
    result = {
      description: notification.example.description,
      id: @id += 1,
      log: success ? [] : notification.formatted_backtrace.split("\n").to_a,
      skipped: skipped,
      success: success,
      suite: [],
      time: 0
    }
    `#{@karma}.result(#{result.to_n})`
  end  
  
  # TODO: Register for what Karma supports, then call Karma using opal's native helpers
end

RSpec.configure do |config|
  config.default_formatter = Opal::RSpec::KarmaFormatter
end
