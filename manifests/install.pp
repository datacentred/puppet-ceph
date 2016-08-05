# == Class: ceph::install
#
class ceph::install {

  assert_private()

  package { 'ceph':
    ensure => $::ceph::package_ensure,
  }

  ensure_packages($::ceph::prerequisites)
}
