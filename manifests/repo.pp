# == Class: ceph::repo
#
# Installs the ceph repo
#
class ceph::repo {

  assert_private()

  if $::ceph::manage_repo {

    case $::osfamily {
      'Debian': {

        include ::apt

        apt::source { 'ceph':
          location => "http://eu.ceph.com/debian-${::ceph::repo_version}",
          release  => $::ceph::repo_release,
          repos    => 'main',
          key      => {
            'id'     => '08B73419AC32B4E966C1A330E84AC2C0460F3994',
            'source' => 'https://git.ceph.com/release.asc',
          },
        }

        Class['::apt'] -> Package <||>

      }

      'RedHat': {

        yumrepo { 'ceph':
          descr    => 'Ceph',
          baseurl  => "http://download.ceph.com/rpm-${::ceph::repo_version}/el\$releasever/x86_64",
          priority => 2,
          enabled  => 1,
          gpgcheck => 1,
          gpgkey   => 'https://download.ceph.com/keys/release.asc',
        }

      }

      default: {
        err('Unsupported OS Platform')
      }

    }

  }

}
