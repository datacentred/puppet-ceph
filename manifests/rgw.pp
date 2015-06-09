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
      '/var/lib/ceph/radosgw/ceph-rgw':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755';
      '/var/lib/ceph/radosgw/ceph-rgw/done':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    } ->

    service { 'radosgw':
      ensure   => running,
      provider => 'init',
      start    => 'start radosgw id=rgw',
      status   => 'status radosgw id=rgw',
      stop     => 'stop radosgw id=rgw',
    }

  }

}
