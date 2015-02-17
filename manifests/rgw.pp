# == Class: ceph::rgw
#
# Installs an object gateway
#
class ceph::rgw {

  assert_private()

  if $::ceph::rgw {

    package { 'radosgw':
      ensure => installed,
    } ->

    file { "/var/lib/ceph/radosgw/ceph-radosgw.${::rgw_id}":
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    } ->

    file { "/var/lib/ceph/radosgw/ceph-radosgw.${::rgw_id}/done":
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
