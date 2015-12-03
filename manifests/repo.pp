# == Class: ceph::repo
#
# Installs the ceph repo
#
class ceph::repo {

  assert_private()

  if $::ceph::manage_repo {

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

}
