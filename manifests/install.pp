# == Class: ceph::install
#
class ceph::install {

  private()

  package { 'ceph':
    ensure => installed,
  }

}
