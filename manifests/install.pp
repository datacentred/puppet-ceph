# == Class: ceph::install
#
class ceph::install {

  assert_private()

  package { 'ceph':
    ensure          => $::ceph::pkg_version,
    install_options => $::ceph::pkg_options,
  }

  ensure_packages($::ceph::prerequisites)
}
