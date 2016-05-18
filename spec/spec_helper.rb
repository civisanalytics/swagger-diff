$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'swagger/diff'
require 'pry'
require 'vcr'

RSpec.configure do |config|
  # Turn deprecation warnings into errors.
  config.raise_errors_for_deprecations!

  # Persist example state. Enables --only-failures:
  # http://rspec.info/blog/2015/06/rspec-3-3-has-been-released/#core-new---only-failures-option
  config.example_status_persistence_file_path = 'tmp/examples.txt'
  config.run_all_when_everything_filtered = true
end

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/cassettes'
  config.hook_into :webmock
  config.around_http_request do |request|
    VCR.use_cassette('global', &request)
  end
end
