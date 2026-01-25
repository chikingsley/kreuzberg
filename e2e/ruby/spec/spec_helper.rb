# frozen_string_literal: true

# Require bundler if available
require "bundler/setup" if defined?(Bundler)

# Configure RSpec
RSpec.configure do |config|
  config.expose_dsl_globally = true
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
