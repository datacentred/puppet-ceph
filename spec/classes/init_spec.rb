require 'spec_helper'

CONF = <<EOS.gsub(/^\s+\|/, '')
  |[main]
  |  fsid = 12345
  |[osd]
  |  osd_journal_size = 12345
EOS

KEY = <<EOS.gsub(/^\s+\|/, '')
  |[client.admin]
  |  key = AQBAyNlUmO09CxAA2u2p6s38wKkBXaLWFeD7bA==
  |  caps mon = "allow *"
  |  caps mds = "allow"
  |  caps osd = "allow *"
EOS

describe 'ceph', :type => :class do
  let :params do
    {
      :mon => true,
      :osd => true,
      :rgw => true,
      :mds => true,
      :mon_id => 'test',
      :mon_key => 'monkey',
      :rgw_id => 'rgw.test',
      :mds_id => 'test',
      :manage_repo => true,
      :repo_mirror => 'eu.ceph.com',
      :repo_version => 'jewel',
      :package_ensure => '10.2.3',
      :conf => {
        'main' => {
          'fsid' => '12345'
        },
        'osd' => {
          'osd_journal_size' => 12_345
        }
      },
      :user => 'mickey',
      :group => 'mouse',
      :disks => {
        'defaults' => {
          'params' => {
            'fs-type'   => 'xfs',
            'bluestore' => :undef
          }
        },
        '2:0:0:0' => {
          'journal' => '4:0:0:0'
        },
        'Slot 01' => {
          'journal' => 'DISK00'
        }
      },
      :keys => {
        '/etc/ceph/ceph.client.admin.keyring' => {
          'user'     => 'client.admin',
          'key'      => 'AQBAyNlUmO09CxAA2u2p6s38wKkBXaLWFeD7bA==',
          'caps_mon' => 'allow *',
          'caps_osd' => 'allow *',
          'caps_mds' => 'allow'
        }
      }
    }
  end

  context 'on an ubuntu xenial system' do
    let :facts do
      {
        :osfamily => 'Debian',
        :os => {
          :family => 'Debian',
          :name => 'Ubuntu',
          :release => {
            :full => '16.04'
          },
          :distro => {
            :codename => 'xenial'
          }
        }
      }
    end

    context 'ceph' do
      it 'compiles and all dependencies are satisfied' do
        is_expected.to compile.with_all_deps
      end

      it 'imports params' do
        is_expected.to contain_class('ceph::params')
      end

      it 'creates the repository before installing packages' do
        is_expected.to contain_class('ceph::repo').that_comes_before('Class[ceph::install]')
      end

      it 'installs the packages before configuring e.g. creates /etc/ceph' do
        is_expected.to contain_class('ceph::install').that_comes_before('Class[ceph::config]')
      end

      it 'configures ceph before installing a monitor' do
        is_expected.to contain_class('ceph::config').that_comes_before('Class[ceph::mon]')
      end

      it 'configures ceph before installing an osd' do
        is_expected.to contain_class('ceph::config').that_comes_before('Class[ceph::osd]')
      end

      it 'configures ceph before installing a rgw ' do
        is_expected.to contain_class('ceph::config').that_comes_before('Class[ceph::rgw]')
      end

      it 'configures ceph before installing a mds' do
        is_expected.to contain_class('ceph::config').that_comes_before('Class[ceph::mds]')
      end

      it 'configures systemd to enable the ceph target' do
        is_expected.to contain_class('ceph::service')
      end

      it 'configures a monitor before installing keys' do
        is_expected.to contain_class('ceph::mon').that_comes_before('Class[ceph::auth]')
      end

      it 'installs bootstrap keys before installing an osd' do
        is_expected.to contain_class('ceph::auth').that_comes_before('Class[ceph::osd]')
      end

      it 'installs bootstrap keys before installing a rgw' do
        is_expected.to contain_class('ceph::auth').that_comes_before('Class[ceph::rgw]')
      end

      it 'installs bootstrap keys before installing a mds' do
        is_expected.to contain_class('ceph::auth').that_comes_before('Class[ceph::mds]')
      end

      it 'installs osds before installing a rgw' do
        is_expected.to contain_class('ceph::osd').that_comes_before('Class[ceph::rgw]')
      end

      it 'installs osds before installing a mds' do
        is_expected.to contain_class('ceph::osd').that_comes_before('Class[ceph::mds]')
      end

      it 'installs a rgw' do
        is_expected.to contain_class('ceph::rgw')
      end

      it 'installs a mds' do
        is_expected.to contain_class('ceph::mds')
      end
    end

    context 'ceph::repo' do
      it 'contains a source repository with the correct parameters' do
        is_expected.to contain_apt__source('ceph').with(
          'location' => 'http://eu.ceph.com/debian-jewel',
          'release' => 'xenial'
        )
      end

      it 'contains a pin to override the OS defaults, cloud archive etc' do
        is_expected.to contain_apt__pin('ceph').with(
          'packages' => '*',
          'origin' => 'eu.ceph.com',
          'priority' => '600'
        )
      end

      it 'contains a dependency between apt updating and the ceph package installing' do
        is_expected.to contain_class('apt').that_comes_before('Package[ceph]')
      end
    end

    context 'ceph::install' do
      it 'contains the ceph package with the version specified' do
        is_expected.to contain_package('ceph').with('ensure' => '10.2.3')
      end
    end

    context 'ceph::config' do
      it 'contains ceph configuration correctly formatted for the input' do
        is_expected.to contain_file('/etc/ceph/ceph.conf').with(
          'owner' => 'mickey',
          'group' => 'mouse',
          'mode' => '0644',
          'content' => CONF
        )
      end
    end

    context 'ceph::service' do
      it 'enables the ceph target on a systemd system' do
        is_expected.to contain_exec('ceph.target enable').with(
          'command' => '/bin/systemctl enable ceph.target',
          'unless' => '/bin/systemctl is-enabled ceph.target'
        )
      end

      it 'reloads systemctl on a systemd system' do
        is_expected.to contain_exec('ceph::service systemctl reload').with(
          'command' => '/bin/systemctl daemon-reload',
          'refreshonly' => 'true'
        )
      end
    end

    context 'ceph::mon' do
      it 'creates the monitor as the ceph user' do
        is_expected.to contain_exec('mon create').with(
          'command' => '/usr/bin/ceph-mon --mkfs -i test --key monkey',
          'creates' => '/var/lib/ceph/mon/ceph-test',
          'user' => 'mickey',
          'group' => 'mouse'
        )
      end

      it 'creates the monitor before starting the service' do
        is_expected.to contain_exec('mon create').that_comes_before('Exec[mon service start]')
      end

      it 'creates the monitor before creating the init flags' do
        is_expected.to contain_exec('mon create').that_comes_before('File[/var/lib/ceph/mon/ceph-test/done]')
      end

      it 'creates a monitor done file' do
        is_expected.to contain_file('/var/lib/ceph/mon/ceph-test/done').with(
          'owner' => 'mickey',
          'group' => 'mouse',
          'mode' => '0644'
        )
      end

      it 'creates a monitor done file before stating the service' do
        is_expected.to contain_file('/var/lib/ceph/mon/ceph-test/done').that_comes_before('Exec[mon service start]')
      end

      it 'creates client.admin keyring to stop ceph-create-keys from injecting new values' do
        is_expected.to contain_exec('mon inhibit create client.admin').with(
          'command' => '/usr/bin/touch /etc/ceph/ceph.client.admin.keyring',
          'creates' => '/etc/ceph/ceph.client.admin.keyring'
        ).that_comes_before('Exec[mon service start]')
      end

      it 'creates client.bootstrap-osd keyring to stop ceph-create-keys from injecting new values' do
        is_expected.to contain_exec('mon inhibit create client.bootstrap-osd').with(
          'command' => '/usr/bin/touch /var/lib/ceph/bootstrap-osd/ceph.keyring',
          'creates' => '/var/lib/ceph/bootstrap-osd/ceph.keyring'
        ).that_comes_before('Exec[mon service start]')
      end

      it 'creates client.bootstrap-mds keyring to stop ceph-create-keys from injecting new values' do
        is_expected.to contain_exec('mon inhibit create client.bootstrap-mds').with(
          'command' => '/usr/bin/touch /var/lib/ceph/bootstrap-mds/ceph.keyring',
          'creates' => '/var/lib/ceph/bootstrap-mds/ceph.keyring'
        ).that_comes_before('Exec[mon service start]')
      end

      it 'creates client.bootstrap-rgw keyring to stop ceph-create-keys from injecting new values' do
        is_expected.to contain_exec('mon inhibit create client.bootstrap-rgw').with(
          'command' => '/usr/bin/touch /var/lib/ceph/bootstrap-rgw/ceph.keyring',
          'creates' => '/var/lib/ceph/bootstrap-rgw/ceph.keyring'
        ).that_comes_before('Exec[mon service start]')
      end

      it 'enables the service on a systemd system' do
        is_expected.to contain_exec('mon service enable').with(
          'command' => '/bin/systemctl enable ceph-mon@test',
          'unless' => '/bin/systemctl is-enabled ceph-mon@test'
        ).that_comes_before('Exec[mon service start]')
      end

      it 'starts the service' do
        is_expected.to contain_exec('mon service start').with(
          'command' => '/bin/systemctl start ceph-mon@test',
          'unless' => '/bin/systemctl status ceph-mon@test'
        )
      end
    end

    context 'ceph::auth' do
      it 'populates keyrings correctly' do
        is_expected.to contain_ceph__keyring('/etc/ceph/ceph.client.admin.keyring').with(
          'user' => 'client.admin',
          'key' => 'AQBAyNlUmO09CxAA2u2p6s38wKkBXaLWFeD7bA==',
          'caps_mon' => 'allow *',
          'caps_osd' => 'allow *',
          'caps_mds' => 'allow'
        )
      end
    end

    context 'ceph::keyring' do
      it 'creates the keyring' do
        is_expected.to contain_file('/etc/ceph/ceph.client.admin.keyring').with(
          'owner' => 'mickey',
          'group' => 'mouse',
          'mode' => '0644',
          'content' => KEY
        ).that_comes_before('Exec[keyring inject client.admin]')
      end

      it 'injects the keyring on a monitor' do
        is_expected.to contain_exec('keyring inject client.admin').with(
          'command' => '/usr/bin/ceph -n mon. -k /var/lib/ceph/mon/ceph-test/keyring auth import -i /etc/ceph/ceph.client.admin.keyring',
          'unless' => '/usr/bin/ceph -n mon. -k /var/lib/ceph/mon/ceph-test/keyring auth list | grep AQBAyNlUmO09CxAA2u2p6s38wKkBXaLWFeD7bA=='
        )
      end
    end

    context 'ceph::osd' do
      it 'populates osds correctly' do
        is_expected.to contain_osd('2:0:0:0').with(
          'journal' => '4:0:0:0',
          'params' => {
            'fs-type' => 'xfs',
            'bluestore' => :undef
          }
        )

        is_expected.to contain_osd('Slot 01').with(
          'journal' => 'DISK00',
          'params' => {
            'fs-type' => 'xfs',
            'bluestore' => :undef
          }
        )
      end
    end

    context 'ceph::rgw' do
      it 'contains the rgw package with the correct version before starting the service' do
        is_expected.to contain_package('radosgw').with('ensure' => '10.2.3').that_comes_before('Exec[rgw service start]')
      end

      it 'creates the rgw directory' do
        is_expected.to contain_file('/var/lib/ceph/radosgw').with(
          'ensure' => 'directory',
          'owner' => 'mickey',
          'group' => 'mouse',
          'mode' => '0755'
        ).that_comes_before('File[/var/lib/ceph/radosgw/ceph-rgw.test]')
      end

      it 'creates the rgw instance directory' do
        is_expected.to contain_file('/var/lib/ceph/radosgw/ceph-rgw.test').with(
          'ensure' => 'directory',
          'owner' => 'mickey',
          'group' => 'mouse',
          'mode' => '0755'
        ).that_comes_before([
          'File[/var/lib/ceph/radosgw/ceph-rgw.test/done]',
          'Exec[rgw keyring create]'
        ])
      end

      it 'creates an rgw done file before stating the service' do
        is_expected.to contain_file('/var/lib/ceph/radosgw/ceph-rgw.test/done').that_comes_before('Exec[rgw service start]')
      end

      it 'creates the keyring before starting the service' do
        is_expected.to contain_exec('rgw keyring create').with(
          'command' => "/usr/bin/ceph --name client.bootstrap-rgw --keyring /var/lib/ceph/bootstrap-rgw/ceph.keyring auth get-or-create client.rgw.test mon 'allow rw' osd 'allow rwx' -o /var/lib/ceph/radosgw/ceph-rgw.test/keyring",
          'creates' => '/var/lib/ceph/radosgw/ceph-rgw.test/keyring',
          'user' => 'mickey'
        ).that_comes_before('Exec[rgw service start]')
      end

      it 'enables the service on a systemd system' do
        is_expected.to contain_exec('rgw service enable').with(
          'command' => '/bin/systemctl enable ceph-radosgw@rgw.test',
          'unless' => '/bin/systemctl is-enabled ceph-radosgw@rgw.test'
        ).that_comes_before('Exec[rgw service start]')
      end

      it 'starts the service' do
        is_expected.to contain_exec('rgw service start').with(
          'command' => '/bin/systemctl start ceph-radosgw@rgw.test',
          'unless' => '/bin/systemctl status ceph-radosgw@rgw.test'
        )
      end
    end

    context 'ceph::mds' do
      it 'creates the mds directory' do
        is_expected.to contain_file('/var/lib/ceph/mds').with(
          'ensure' => 'directory',
          'owner' => 'mickey',
          'group' => 'mouse',
          'mode' => '0755'
        ).that_comes_before('File[/var/lib/ceph/mds/ceph-test]')
      end

      it 'creates the mds instance directory' do
        is_expected.to contain_file('/var/lib/ceph/mds/ceph-test').with(
          'ensure' => 'directory',
          'owner' => 'mickey',
          'group' => 'mouse',
          'mode' => '0755'
        ).that_comes_before([
          'File[/var/lib/ceph/mds/ceph-test/done]',
          'Exec[mds keyring create]'
        ])
      end

      it 'creates an mds done file before stating the service' do
        is_expected.to contain_file('/var/lib/ceph/mds/ceph-test/done').that_comes_before('Exec[mds service start]')
      end

      it 'creates the keyring before starting the service' do
        is_expected.to contain_exec('mds keyring create').with(
          'command' => "/usr/bin/ceph --name client.bootstrap-mds --keyring /var/lib/ceph/bootstrap-mds/ceph.keyring auth get-or-create mds.test mon 'allow profile mds' osd 'allow rwx' mds allow -o /var/lib/ceph/mds/ceph-test/keyring",
          'creates' => '/var/lib/ceph/mds/ceph-test/keyring',
          'user' => 'mickey'
        ).that_comes_before('Exec[mds service start]')
      end

      it 'enables the service on a systemd system' do
        is_expected.to contain_exec('mds service enable').with(
          'command' => '/bin/systemctl enable ceph-mds@test',
          'unless' => '/bin/systemctl is-enabled ceph-mds@test'
        ).that_comes_before('Exec[mds service start]')
      end

      it 'starts the service' do
        is_expected.to contain_exec('mds service start').with(
          'command' => '/bin/systemctl start ceph-mds@test',
          'unless' => '/bin/systemctl status ceph-mds@test'
        )
      end
    end
  end

  context 'on an ubuntu trusty system' do
    let :facts do
      {
        :osfamily => 'Debian',
        :os => {
          :family => 'Debian',
          :name => 'Ubuntu',
          :release => {
            :full => '14.04'
          },
          :distro => {
            :codename => 'trusty'
          }
        }
      }
    end

    context 'ceph' do
      it 'compiles and all dependencies are satisfied' do
        is_expected.to compile.with_all_deps
      end
    end

    context 'ceph::mon' do
      it 'creates an upstart file after creating the monitor and before starting the service' do
        is_expected.to contain_file('/var/lib/ceph/mon/ceph-test/upstart').with(
          'owner' => 'mickey',
          'group' => 'mouse',
          'mode' => '0644'
        ).that_requires('Exec[mon create]').that_comes_before('Exec[mon service start]')
      end

      it 'starts the service' do
        is_expected.to contain_exec('mon service start').with(
          'command' => '/sbin/start ceph-mon id=test',
          'unless' => '/sbin/status ceph-mon id=test'
        )
      end
    end

    context 'ceph:rgw' do
      it 'creates an upstart file after creating the rgw and before starting the service' do
        is_expected.to contain_file('/var/lib/ceph/radosgw/ceph-rgw.test/upstart').with(
          'owner' => 'mickey',
          'group' => 'mouse',
          'mode' => '0644'
        ).that_requires('File[/var/lib/ceph/radosgw/ceph-rgw.test]').that_comes_before('Exec[rgw service start]')
      end

      it 'starts the service' do
        is_expected.to contain_exec('rgw service start').with(
          'command' => '/sbin/start radosgw id=rgw.test',
          'unless' => '/sbin/status radosgw id=rgw.test'
        )
      end
    end

    context 'ceph:mds' do
      it 'creates an upstart file after creating the mds and before starting the service' do
        is_expected.to contain_file('/var/lib/ceph/mds/ceph-test/upstart').with(
          'owner' => 'mickey',
          'group' => 'mouse',
          'mode' => '0644'
        ).that_requires('File[/var/lib/ceph/mds/ceph-test]').that_comes_before('Exec[mds service start]')
      end

      it 'starts the service' do
        is_expected.to contain_exec('mds service start').with(
          'command' => '/sbin/start ceph-mds id=test',
          'unless' => '/sbin/status ceph-mds id=test'
        )
      end
    end
  end

  context 'on a centos 7 system' do
    let :facts do
      {
        :os => {
          :family => 'RedHat',
          :name => 'Centos'
        }
      }
    end

    context 'ceph' do
      it 'compiles and all dependencies are satisfied' do
        is_expected.to compile.with_all_deps
      end
    end

    context 'ceph::repo' do
      it 'installs a source repository with the correct parameters' do
        is_expected.to contain_yumrepo('ceph').with('baseurl' => 'http://download.ceph.com/rpm-jewel/el$releasever/x86_64')
      end
    end

    context 'ceph::install' do
      it 'installs prerequisite packages' do
        is_expected.to contain_package('python-setuptools.noarch')
        is_expected.to contain_package('redhat-lsb-core')
      end
    end

    context 'ceph::rgw' do
      it 'contains the rgw package with the correct version before starting the service' do
        is_expected.to contain_package('ceph-radosgw').with('ensure' => '10.2.3').that_comes_before('Exec[rgw service start]')
      end
    end
  end
end
