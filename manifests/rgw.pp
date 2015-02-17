# == Class: ceph::rgw
#
# Installs an object gateway
#
# === Parameters
#
# [*id*]
#   Gateway identifier
#
class ceph::rgw (
  $id = $::hostname,
) {

  private()

  include ::ceph

  if $ceph::rgw {

    package { 'radosgw':
      ensure => installed,
    } ->

    file { "/var/lib/ceph/radosgw/ceph-radosgw.${::id}":
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    } ->

    file { "/var/lib/ceph/radosgw/ceph-radosgw.${::id}/done":
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    } ->

    service { 'radosgw-all':
      ensure    => running,
    }

  }

}
