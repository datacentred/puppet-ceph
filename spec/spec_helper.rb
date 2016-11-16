require 'rspec-puppet'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

require 'coveralls'
Coveralls.wear!
Coveralls.noisy = true

RSpec.configure do |c|
  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')
  c.add_formatter 'documentation'
  c.mock_with :mocha
end
