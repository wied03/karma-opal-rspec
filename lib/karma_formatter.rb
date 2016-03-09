require 'native'
require 'js'

module Karma
  module Opal
    module RSpec
      class KarmaFormatter
        ::RSpec::Core::Formatters.register self, :start,
                                           :example_started,
                                           :example_passed,
                                           :example_failed,
                                           :example_pending,
                                           :dump_summary

        def initialize(*args)
          super
          @karma = self.class.karma_instance
          @id = 0
        end

        def self.karma_started(karma)
          @karma = karma
        end

        def self.karma_instance
          @karma
        end

        def start(notification)
          @timers = {}
          @promises = []
          contents = {
            total: notification.count
          }
          @karma.JS.info contents.to_n
        end

        def dump_summary(*)
          Promise.when(*@promises).then { @karma.JS.complete }
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

        def example_started(notification)
          @timers[notification.example] = `new Date().getTime()`
          nil
        end

        def format_stack_frame(frame)
          method = frame.JS[:functionName]
          "#{frame.JS[:fileName]}:#{frame.JS[:lineNumber]} in `(#{method ? method : 'unknown method'})'"
        end

        def get_stack_trace(notification)
          message = [notification.exception.message]
          promise = Promise.new
          # TODO: Extract some of these blocks into methods?
          success_handle = lambda do |frames|
            result = message + frames.map { |frame| format_stack_frame frame }
            promise.resolve result
          end
          fail_handle = lambda do |error|
            result = message + ["Unable to parse stack frames for example #{notification.example.description} due to error #{error}"]
            promise.resolve result
          end
          filter = lambda do |frame|
            filename = frame.JS[:fileName]
            # TODO: Still hard code this or pass in the roll up list somehow??
            !filename.include?('opal.js') && !filename.include?('opal-rspec.js')
          end
          # TODO: Use StackTrace.JS opal syntax
          `StackTrace.fromError(#{notification.exception}, {filter: #{filter}}).then(#{success_handle}, #{fail_handle})`
          promise
        end

        def report_example_done(notification, skipped, success)
          example = notification.example
          suite = example.example_group.parent_groups.reverse.map(&:description)
          time = skipped ? 0 : `new Date().getTime() - #{@timers[example]}`
          log_promise = if success
                          Promise.value([])
                        else
                          get_stack_trace(notification)
                        end
          @promises << log_promise.then do |log|
            results = {
              description: example.description,
              id: @id += 1,
              log: log,
              skipped: skipped,
              success: success,
              suite: suite,
              time: time
            }
            @karma.JS.result results.to_n
          end
          # no inadvertent returns
          nil
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.default_formatter = Karma::Opal::RSpec::KarmaFormatter
end
