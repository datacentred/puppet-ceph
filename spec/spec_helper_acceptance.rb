require 'open-uri'
require 'beaker-rspec'
require 'beaker/puppet_install_helper'

run_puppet_install_helper

RSpec.configure do |c|
  module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  c.formatter = :documentation

  c.before :suite do
    hosts.each do |host|
      # Install this module for testing
      copy_module_to(host, :source => module_root, :module_name => 'ceph')

      # Install dependencies
      on host,
         puppet('module install puppetlabs-apt'),
         :acceptable_exit_codes => [0, 1]

      # Install EPEL on centos
      next unless host['platform'].start_with?('el')
      epel = 'http://dl.fedoraproject.org/pub/epel/7/x86_64/e/'
      rpm = open(epel).read[/epel-release-7-\d+\.noarch\.rpm/]
      on(host, "rpm -i #{epel}#{rpm}")
    end
  end
end
