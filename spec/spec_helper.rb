$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift(File.join(File.dirname(__FILE__), "macros"))

ENV['TZ'] = 'CET' # something that is not local and not utc so we find all the bugs

if RUBY_VERSION =~ /1.9/ && ENV["COVERAGE"]
  require 'simplecov'
  SimpleCov.start do
    add_filter "spec/"
  end
end

require 'zendesk'
require 'vcr'

require 'resource_macros'
require 'fixtures/zendesk'
require 'fixtures/test_resources'

RSpec.configure do |c|
  # so we can use `:vcr` rather than `:vcr => true`;
  # in RSpec 3 this will no longer be necessary.
  c.treat_symbols_as_metadata_keys_with_true_values = true

  c.before(:all, :vcr_off) do
    VCR.turn_off!
  end

  c.after(:all, :vcr_off) do
    VCR.turn_on!
  end

  c.before(:each) do
    WebMock.reset!
  end

  c.extend VCR::RSpec::Macros
  c.extend ResourceMacros
end

VCR.configure do |c|
  c.cassette_library_dir = File.join(File.dirname(__FILE__), "fixtures", "cassettes")
  c.default_cassette_options = { :record => :new_episodes, :decode_compressed_response => true }
  c.hook_into :webmock
end

def client
  credentials = File.join(File.dirname(__FILE__), "fixtures", "credentials.yml")
  @client ||= Zendesk.configure do |config|
    if File.exist?(credentials)
      data = YAML.load(File.read(credentials))
      config.username = data["username"]
      config.password = data["password"]
      config.url = data["url"]
    else
      puts "using default credentials: live specs will fail."
      puts "add your credentials to spec/fixtures/credentials.yml (see: spec/fixtures/credentials.yml.example)"
      config.username = "please.change"
      config.password = "me"
      config.url = "https://my.zendesk.com/api/v2"
    end

    config.logger = !!ENV["LOG"]
    config.retry = true
  end
end

def silence_stdout
  $stdout = File.new( '/dev/null', 'w' )
  yield
ensure
  $stdout = STDOUT
end

include WebMock::API
