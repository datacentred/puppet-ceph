require 'spec_helper_acceptance'

describe 'ceph' do
  context 'all-in-one server' do
    it 'provisions with no errors' do
      pp = <<-EOS
        Exec { path => '/bin:/usr/bin:/sbin:/usr/sbin' }
        class { 'ceph':
          mon => true,
          osd => true,
          rgw => true,
        }
      EOS
      # Check for clean provisioning and idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end
    it 'accepts http requests' do
      shell('curl localhost:7480', :acceptable_exit_codes => 0)
    end
  end
end
