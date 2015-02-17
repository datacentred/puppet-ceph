# == Class: ceph::install
#
class ceph::install {

  assert_private()

  package { 'ceph':
    ensure => installed,
  }

}
