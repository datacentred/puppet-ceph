require 'spec_helper_acceptance'

describe 'ceph' do
  context 'initialization' do
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
          'defaults' => {
            'params' => {
              'fs-type' => 'xfs',
            },
          },
          '2:0:0:0' => {
            'journal' => '5:0:0:0',
          },
          '3:0:0:0' => {
            'journal' => '5:0:0:0',
          },
          '4:0:0:0' => {
            'journal' => '5:0:0:0',
          },
        },
      EOS
    elsif default['hypervisor'] == 'openstack'
      disks = <<-EOS
        disks => {
          'defaults' => {
            'params' => {
              'fs-type' => 'xfs',
            },
          },
          '2:0:0:1' => {
            'journal' => '2:0:0:4',
          },
          '2:0:0:2' => {
            'journal' => '2:0:0:4',
          },
          '2:0:0:3' => {
            'journal' => '2:0:0:4',
          },
        },
      EOS
    else
      raise ArgumentError, 'Unsupported hypervisor'
    end

    pp = <<-EOS
      Exec { path => '/bin:/usr/bin:/sbin:/usr/sbin' }
      class { 'ceph':
        mon => true,
        osd => true,
        rgw => true,
        mds => true,
        #{conf}
        #{disks}
      }
    EOS

    it 'provisions with no errors' do
      apply_manifest(pp, :catch_failures => true)
    end

    it 'provisions idempotently' do
      apply_manifest(pp, :catch_changes => true)
    end

    it 'rgw accepts http requests' do
      retry_on(default, 'netstat -l | grep 7480', :max_retries => 120)
    end

    it 'mds is active' do
      on(default, 'ceph osd pool create cephfs-meta 32')
      on(default, 'ceph osd pool create cephfs-data 32')
      on(default, 'ceph fs new cephfs cephfs-meta cephfs-data')
      retry_on(default, 'ceph mds stat | grep active', :max_retries => 120)
    end
  end

  context 'after a reboot' do
    default.reboot
    default.wait_for_port(22) # Takes a while for Centos

    it 'rgw accepts http requests' do
      retry_on(default, 'netstat -l | grep 7480', :max_retries => 120)
    end

    it 'mds is active' do
      retry_on(default, 'ceph mds stat | grep active', :max_retries => 120)
    end
  end
end
