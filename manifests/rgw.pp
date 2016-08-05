# == Class: ceph::rgw
#
# Installs an object gateway
#
class ceph::rgw {

  assert_private()

  if $::ceph::rgw {

    package { $::ceph::radosgw_package:
      ensure => $::ceph::package_ensure,
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

    file { "/var/lib/ceph/radosgw/ceph-${::ceph::rgw_id}/done":
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      seltype => $::ceph::seltype,
    } ->

    Exec['radosgw start']

    case $::ceph::service_provider {
      'upstart': {
        file { "/var/lib/ceph/radosgw/ceph-${::ceph::rgw_id}/upstart":
          ensure  => file,
          owner   => 'root',
          group   => 'root',
          mode    => '0644',
          seltype => $::ceph::seltype,
        } ->

        exec { 'radosgw start':
          command => "start radosgw id=${::ceph::rgw_id}",
          unless  => "status radosgw id=${::ceph::rgw_id}",
        }
      }
      'systemd': {
        exec { "systemctl enable ceph-radosgw@${::ceph::rgw_id}":
          unless => "systemctl is-enabled ceph-radosgw@${::ceph::rgw_id}",
        } ->

        exec { 'radosgw start':
          command => "systemctl start ceph-radosgw@${::ceph::rgw_id}",
          unless  => "systemctl status ceph-radosgw@${::ceph::rgw_id}",
        }
      }
      default: {
        crit('Unsupported service provider')
      }
    }

  }

}
