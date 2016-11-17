# == Class: ceph::rgw
#
# Installs an object gateway
#
class ceph::rgw {

  assert_private()

  if $::ceph::rgw {

    File {
      owner   => $::ceph::user,
      group   => $::ceph::group,
      seltype => $::ceph::seltype,
    }

    package { $::ceph::radosgw_package:
      ensure => $::ceph::package_ensure,
    } ->

    file { [
      '/var/lib/ceph/radosgw',
      "/var/lib/ceph/radosgw/ceph-${::ceph::rgw_id}",
    ]:
      ensure => directory,
      mode   => '0755',
    } ->

    file { "/var/lib/ceph/radosgw/ceph-${::ceph::rgw_id}/done":
      ensure => file,
      mode   => '0644',
    } ->

    exec { 'rgw keyring create':
      command => "/usr/bin/ceph --name client.bootstrap-rgw \
                 --keyring /var/lib/ceph/bootstrap-rgw/ceph.keyring \
                 auth get-or-create client.${::ceph::rgw_id} \
                 mon 'allow rw' \
                 osd 'allow rwx' \
                 -o /var/lib/ceph/radosgw/ceph-${::ceph::rgw_id}/keyring",
      creates => "/var/lib/ceph/radosgw/ceph-${::ceph::rgw_id}/keyring",
      user    => $::ceph::user,
    } ->

    Exec['rgw service start']

    case $::ceph::service_provider {
      'upstart': {
        file { "/var/lib/ceph/radosgw/ceph-${::ceph::rgw_id}/upstart":
          ensure => file,
          mode   => '0644',
        } ->

        exec { 'rgw service start':
          command => "/sbin/start radosgw id=${::ceph::rgw_id}",
          unless  => "/sbin/status radosgw id=${::ceph::rgw_id}",
        }
      }
      'systemd': {
        exec { 'rgw service enable':
          command => "/bin/systemctl enable ceph-radosgw@${::ceph::rgw_id}",
          unless  => "/bin/systemctl is-enabled ceph-radosgw@${::ceph::rgw_id}",
        } ->

        exec { 'rgw service start':
          command => "/bin/systemctl start ceph-radosgw@${::ceph::rgw_id}",
          unless  => "/bin/systemctl status ceph-radosgw@${::ceph::rgw_id}",
        }
      }
      default: {
        crit('Unsupported service provider')
      }
    }

  }

}
