require 'spec_helper_acceptance'

describe 'ceph' do
  context 'with all services' do
    it 'provisions with no errors' do

      # Select the disk layout based on the VM type as this defines
      # the host bus adaptor and how the disks are presented
      if default['hypervisor'] == 'vagrant'
        disks = <<-EOS
          disks => {
            '2:0:0:0/5:0:0:0' => {
              'fstype' => 'xfs',
            },
            '3:0:0:0/5:0:0:0' => {
              'fstype' => 'xfs',
            },
            '4:0:0:0/5:0:0:0' => {
              'fstype' => 'xfs',
            },
          },
        EOS
      elsif default['hypervisor'] == 'openstack'
        disks = <<-EOS
          disks => {
            '2:0:0:1/2:0:0:4' => {
              'fstype' => 'xfs',
            },
            '2:0:0:2/2:0:0:4' => {
              'fstype' => 'xfs',
            },
            '2:0:0:3/2:0:0:4' => {
              'fstype' => 'xfs',
            },
          },
        EOS
      else
        raise ArgumentError, "Unsupported hypervisor"
      end

      pp = <<-EOS
        Exec { path => '/bin:/usr/bin:/sbin:/usr/sbin' }
        class { 'ceph':
          mon => true,
          osd => true,
          rgw => true,
          #{disks}
        }
      EOS

      # Check for clean provisioning and idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    it 'accepts http requests' do
      # Wait for radosgw to start listening and ensure it works
      retry_on(default, 'netstat -l | grep 7480', :max_retries => 30)
    end

    it 'accepts http requests after reboot' do
      # Reboot the box and wait for it to come back (takes a while for Centos)
      default.reboot
      # Check radosgw is back
      retry_on(default, 'netstat -l | grep 7480', :max_retries => 30)
    end
  end
end
