module Karma
  module Opal
    module RailsDetector
      def in_rails?
        (rails_env = ENV['RAILS_ENV']) && !rails_env.empty?
      end
    end
  end
end
