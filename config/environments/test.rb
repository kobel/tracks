# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils    = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

# Tell ActionMailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false

# Unique cookies
config.action_controller.session = { :key => 'TracksTest' }

# Overwrite the default settings for fixtures in tests. See Fixtures 
# for more details about these settings.
# config.transactional_fixtures = true
# config.instantiated_fixtures = false
# config.pre_loaded_fixtures = false
SITE_CONFIG['salt'] ||= 'change-me'

config.time_zone = 'UTC'

config.after_initialize do
  require File.expand_path(File.dirname(__FILE__) + "/../../test/selenium_helper")
end

config.gem "flexmock"
config.gem "ZenTest", :lib => "zentest", :version => ">=4.0.0"
config.gem "hpricot"
config.gem "hoe"
config.gem 'webrat',           :lib => false, :version => '>=0.7.0' unless File.directory?(File.join(Rails.root, 'vendor/plugins/webrat'))
config.gem 'rspec',            :lib => false, :version => '>=1.3.0' unless File.directory?(File.join(Rails.root, 'vendor/plugins/rspec'))
config.gem 'rspec-rails',      :lib => false, :version => '>=1.3.2' unless File.directory?(File.join(Rails.root, 'vendor/plugins/rspec-rails'))
config.gem "thoughtbot-factory_girl", :lib => "factory_girl", :source => "http://gems.github.com"
