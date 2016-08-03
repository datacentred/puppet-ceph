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
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      seltype => $::ceph::seltype,
    } ->

    file { [
      "/var/lib/ceph/radosgw/ceph-${::ceph::rgw_id}/done",
      "/var/lib/ceph/radosgw/ceph-${::ceph::rgw_id}/${ceph::service_provider}",
    ]:
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      seltype => $::ceph::seltype,
    } ->

    Service['radosgw']

    case $::ceph::service_provider {
      'debian': {
        service { 'radosgw':
          ensure   => running,
          provider => 'debian',
          start    => "start radosgw id=${::ceph::rgw_id}",
          status   => "status radosgw id=${::ceph::rgw_id}",
          stop     => "stop radosgw id=${::ceph::rgw_id}",
        }
      }
      'redhat': {
        service { 'radosgw':
          ensure   => running,
          provider => 'redhat',
          start    => "systemctl start ceph-radosgw@${::ceph::rgw_id}",
          status   => "systemctl status ceph-radosgw@${::ceph::rgw_id}",
          stop     => "systemctl stop ceph-radosgw@${::ceph::rgw_id}",
        }
      }
      default: {
        crit('Unsupported service provider')
      }
    }

  }

}
