require "spec_helper"

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"

# spec/support 配下を読み込む
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.include FactoryBot::Syntax::Methods

  # Devise helpers
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include LoginHelper, type: :request

  config.fixture_paths = [
    Rails.root.join("spec/fixtures")
  ]

  config.use_transactional_fixtures = true

  # request spec で mapping を確実に作る
  config.before(:suite) do
    Rails.application.reload_routes!
  end

  config.filter_rails_from_backtrace!
end
