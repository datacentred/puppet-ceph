# == Class: ceph::repo
#
# Installs the ceph repo
#
# === Parameters
#
# [*manage*]
#   Whether this module should install custom repos
#
# [*version*]
#   Ceph version to install the repo for
#
class ceph::repo (
  $manage = false,
  $version = 'giant',
) {

  private()

  if $manage {

    include ::apt

    apt::source { "ceph":
      location   => "http://eu.ceph.com/debian-${version}",
      release    => $::lsbdistcodename,
      repos      => 'main',
      key        => '17ED316D',
      key_server => 'keyserver.ubuntu.com',
    }

  }

}
