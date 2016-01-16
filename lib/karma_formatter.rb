require 'native'

class Opal::RSpec::KarmaFormatter
  ::RSpec::Core::Formatters.register self, :start,
                                     :example_started,
                                     :example_passed,
                                     :example_failed,
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

  def dump_summary(*)
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

  def example_started(*)
    @start_time = `new Date().getTime()`
  end

  def report_example_done(notification, skipped, success)
    example = notification.example
    suite = example.example_group.parent_groups.reverse.map(&:description)
    log = if success
            []
          else
            [notification.exception.message] + notification.formatted_backtrace
          end
    result = {
      description: example.description,
      id: @id += 1,
      log: log,
      skipped: skipped,
      success: success,
      suite: suite,
      time: skipped ? 0 : `new Date().getTime() - #{@start_time}`
    }
    `#{@karma}.result(#{result.to_n})`
  end
end

RSpec.configure do |config|
  config.default_formatter = Opal::RSpec::KarmaFormatter
end
