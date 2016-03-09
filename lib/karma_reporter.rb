require 'native'
require 'js'

module Karma
  module Opal
    module RSpec
      class KarmaReporter
        # In the future, might want to make this configurable
        FILTER_STACKTRACE = %w(opal.js opal-rspec.js karma-opal-rspec/lib/runner.js karma.js context.html)
        FailedExampleNotify = ::RSpec::Core::Notifications::FailedExampleNotification
        ExampleNotify = ::RSpec::Core::Notifications::ExampleNotification

        ::RSpec::Core::Formatters.register self,
                                           :start,
                                           :example_started,
                                           :example_passed,
                                           :example_failed,
                                           :example_pending,
                                           :dump_summary

        def initialize(*)
          @karma = self.class.karma_instance
          @id = 0
        end

        # When Karma runs, it calls this, thus not depending on a global variable
        def self.karma_started(karma)
          @karma = karma
        end

        def self.karma_instance
          @karma
        end

        def filtered_examples
          # Tap into groups pure, unfiltered examples
          world = ::RSpec.world
          all_examples = world.filtered_examples.keys.map { |group| group.examples }.flatten.uniq
          active_examples = world.filtered_examples.values.flatten
          all_examples - active_examples
        end

        def start(notification)
          @timers = {}
          @promises = []
          # RSpec doesn't usually include examples that are filtered out with focus, etc. but given usage of that
          # technique in the Karma world, we want to do that
          @filtered_examples = filtered_examples
          contents = {
            total: notification.count + @filtered_examples.length
          }
          @karma.JS.info contents.to_n
        end

        def log_filtered_examples
          @filtered_examples.each do |example|
            notification = ExampleNotify.new example
            report_example_done notification, true
          end
        end

        def dump_summary(*)
          # Nothing to report here since we report our progress after each example
          # If we have failures, then we'll have asynchronous things to wait on first before we declare victory
          Promise.when(*@promises).then do
            log_filtered_examples
            @karma.JS.complete
          end
        end

        def example_passed(notification)
          report_example_done notification, false
        end

        def example_failed(notification)
          report_example_done notification, false
        end

        def example_pending(notification)
          report_example_done notification, true
        end

        def example_started(notification)
          @timers[notification.example] = `new Date().getTime()`
          nil
        end

        def format_stack_frame(frame)
          method = frame.JS[:functionName]
          "#{frame.JS[:fileName]}:#{frame.JS[:lineNumber]} in `(#{method ? method : 'unknown method'})'"
        end

        def get_stack_trace(exception)
          results = [exception.message]
          if exception.backtrace.reject(&:empty?).empty?
            results << 'No stack trace provided by browser'
            return Promise.value(results)
          end
          promise = Promise.new
          success_handle = lambda do |frames|
            results += frames.map { |frame| format_stack_frame frame }
            promise.resolve results
          end
          fail_handle = lambda do |error|
            results << "Unable to parse pretty stack frames because #{error}"
            promise.resolve results
          end
          filter = lambda do |frame|
            !FILTER_STACKTRACE.any? { |pattern| frame.JS[:fileName].include?(pattern) }
          end
          `StackTrace.fromError(#{exception}, {filter: #{filter}}).then(#{success_handle}, #{fail_handle})`
          promise
        end

        def report_example_done(notification, skipped)
          example = notification.example
          suite = example.example_group.parent_groups.reverse.map(&:description)
          time = skipped ? 0 : `new Date().getTime() - #{@timers[example]}`
          # Karma considers skip a success
          success = skipped || !notification.is_a?(FailedExampleNotify)
          log_promise = if success
                          Promise.value([])
                        else
                          get_stack_trace(notification.exception)
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
  config.default_formatter = Karma::Opal::RSpec::KarmaReporter
end
