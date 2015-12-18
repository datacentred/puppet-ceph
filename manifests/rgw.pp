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

    file {
      "/var/lib/ceph/radosgw/ceph-${::ceph::rgw_id}":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755';
      "/var/lib/ceph/radosgw/ceph-${::ceph::rgw_id}/done":
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    } ->

    service { 'radosgw':
      ensure   => running,
      provider => 'init',
      start    => "start radosgw id=${::ceph::rgw_id}",
      status   => "status radosgw id=${::ceph::rgw_id}",
      stop     => "stop radosgw id=${::ceph::rgw_id}",
    }

  }

}
