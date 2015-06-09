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
      release  => $::lsbdistcodename,
      repos    => 'main',
      key      => {
        'id'     => '7F6C9F236D170493FCF404F27EBFDD5D17ED316D',
        'server' => 'keyserver.ubuntu.com',
      },
    }

    Class['::apt'] -> Package <||>

  }

}
