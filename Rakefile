require 'rake'
require 'rspec/core/rake_task'
require 'puppet-lint/tasks/puppet-lint'
require 'puppetlabs_spec_helper/rake_tasks'

PuppetLint.configuration.send('disable_autoloader_layout')
PuppetLint.configuration.send('disable_arrow_on_right_operand_line')
PuppetLint.configuration.ignore_paths = [
  'spec/**/*.pp',
  'pkg/**/*.pp',
  'vendor/**/*.pp'
]

desc 'Run all RSpec code examples'
RSpec::Core::RakeTask.new(:rspec) do |t|
  t.rspec_opts = File.read('spec/spec.opts').chomp || ''
end

SPEC_SUITES = (Dir.entries('spec') - ['.', '..', 'fixtures']).select do |e|
  File.directory? "spec/#{e}"
end
namespace :rspec do
  SPEC_SUITES.each do |suite|
    desc "Run #{suite} RSpec code examples"
    RSpec::Core::RakeTask.new(suite) do |t|
      t.pattern = "spec/#{suite}/**/*_spec.rb"
      t.rspec_opts = File.read('spec/spec.opts').chomp || ''
    end
  end
end

task :default => %i[rspec lint]
