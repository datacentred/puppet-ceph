# == Class: ceph::repo
#
# Installs the ceph repo
#
class ceph::repo {

  assert_private()

  if $::ceph::manage_repo {

    include ::apt

    apt::source { 'ceph':
      location   => "http://eu.ceph.com/debian-${::ceph::repo_version}",
      release    => $::lsbdistcodename,
      repos      => 'main',
      key        => '17ED316D',
      key_server => 'keyserver.ubuntu.com',
    }

  }

}
