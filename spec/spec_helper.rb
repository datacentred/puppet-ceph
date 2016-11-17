require 'puppetlabs_spec_helper/module_spec_helper'
require 'coveralls'
require 'simplecov'

SimpleCov.profiles.define 'rspec-puppet' do
  add_filter '/fixtures/'
  add_filter '/spec/'
end

Coveralls.wear! 'rspec-puppet'
Coveralls.noisy = true

RSpec.configure do |c|
  c.add_formatter 'documentation'
  c.mock_with :mocha
end

at_exit { RSpec::Puppet::Coverage.report! }
