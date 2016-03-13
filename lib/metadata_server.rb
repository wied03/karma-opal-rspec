module Karma
  module Opal
    class MetadataServer
      def initialize(sprockets_env, roll_up_list)
        @sprockets_env = sprockets_env
        @roll_up_list = if roll_up_list.any?
                          roll_up_list.map do |r|
                            # convert JS supplied regexps back into Ruby regexps if necessary
                            regexp_match = /^\/(.*)\/$/.match(r)
                            regexp_match ? Regexp.new(regexp_match.captures[0]) : r
                          end
                        else
                          SprocketsMetadata.default_roll_up_list
                        end
      end

      def call(env)
        request = Rack::Request.new env
        file = request.params['file']
        non_watch_dep_graph = SprocketsMetadata.get_dependency_graph @sprockets_env, %w{opal opal-rspec karma_reporter}
        non_watch_metadata = SprocketsMetadata.get_metadata non_watch_dep_graph, @roll_up_list, watch=false
        test_requires = [file]
        tests_dep_graph = SprocketsMetadata.get_dependency_graph @sprockets_env, test_requires
        test_metadata = SprocketsMetadata.get_metadata tests_dep_graph, @roll_up_list, watch=true
        # Karma will handle the tests themselves, we're just concerned about dependencies
        without_tests = SprocketsMetadata.filter_out_logical_paths test_metadata, test_requires
        result = non_watch_metadata.merge(without_tests)
        [200, {}, result.to_json]
      end
    end
  end
end
