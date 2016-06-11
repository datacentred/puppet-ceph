# == Class: ceph::rgw
#
# Installs an object gateway
#
class ceph::rgw {

  assert_private()

  if $::ceph::rgw {

    package { $::ceph::radosgw_package:
      ensure => installed,
    } ->

    file { [
      '/var/lib/ceph/radosgw',
      "/var/lib/ceph/radosgw/ceph-${::ceph::rgw_id}",
    ]:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    } ->

    file { [
      "/var/lib/ceph/radosgw/ceph-${::ceph::rgw_id}/done",
      "/var/lib/ceph/radosgw/ceph-${::ceph::rgw_id}/${ceph::service_provider}",
    ]:
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
    } ->

    Service['radosgw']

    case $::ceph::service_provider {
      'systemd': {
        service { 'radosgw':
          ensure   => running,
          name     => "ceph-radosgw@${::ceph::rgw_id}",
          provider => 'systemd',
        }
      }
      'upstart': {
        service { 'radosgw':
          ensure   => running,
          provider => 'init',
          start    => "start radosgw id=${::ceph::rgw_id}",
          status   => "status radosgw id=${::ceph::rgw_id}",
          stop     => "stop radosgw id=${::ceph::rgw_id}",
        }
      }
      'sysvinit': {
        service { 'radosgw':
          ensure   => running,
          provider => 'init',
          start    => '/etc/init.d/ceph-radosgw start',
          status   => '/etc/init.d/ceph-radosgw status',
          stop     => '/etc/init.d/ceph-radosgw stop',
        }
      }
      default: {
        err("Unsupported service provider '${ceph::service_provider}'")
      }
    }

  }

}
