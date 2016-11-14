require 'spec_helper_acceptance'

describe 'ceph' do
  context 'with all services' do
    it 'provisions with no errors' do

      # As of 10.2.0 127.0.0.0/8 doesn't work, so use the VM's IP
      conf = <<-EOS
         conf => {
           'global'                => {
             'fsid'                      => '62ed9bd6-adf4-11e4-8fb5-3c970ebb2b86',
             'mon_initial_members'       => $::hostname,
             'mon_host'                  => '#{default.get_ip}',
             'public_network'            => '#{default.get_ip}/32',
             'cluster_network'           => '#{default.get_ip}/32',
             'auth_supported'            => 'cephx',
             'filestore_xattr_use_omap'  => true,
             'osd_crush_chooseleaf_type' => 0,
           },
           'osd'                   => {
             'osd_journal_size' => 100,
           },
           'client.radosgw.puppet' => {
             'keyring'       => '/etc/ceph/ceph.client.radosgw.puppet.keyring',
            'rgw frontends' => '"civetweb port=7480"'
          },
        },
      EOS

      # Select the disk layout based on the VM type as this defines
      # the host bus adaptor and how the disks are presented
      if default['hypervisor'] == 'vagrant'
        disks = <<-EOS
          disks => {
            '2:0:0:0' => {
              'journal' => '5:0:0:0',
              'params'  => {
                'fs-type' => 'xfs',
              },
            },
            '3:0:0:0' => {
              'journal' => '5:0:0:0',
              'params'  => {
                'fs-type' => 'xfs',
              },
            },
            '4:0:0:0' => {
              'journal' => '5:0:0:0',
              'params'  => {
                'fs-type' => 'xfs',
              },
            },
          },
        EOS
      elsif default['hypervisor'] == 'openstack'
        disks = <<-EOS
          disks => {
            '2:0:0:1' => {
              'journal' => '2:0:0:4',
              'params'  => {
                'fs-type' => 'xfs',
              },
            },
            '2:0:0:2' => {
              'journal' => '2:0:0:4',
              'params'  => {
                'fs-type' => 'xfs',
              },
            },
            '2:0:0:3' => {
              'journal' => '2:0:0:4',
              'params'  => {
                'fs-type' => 'xfs',
              },
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
          #{conf}
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
      default.wait_for_port(22)
      # Check radosgw is back
      retry_on(default, 'netstat -l | grep 7480', :max_retries => 30)
    end
  end
end
