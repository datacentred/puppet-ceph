# == Class: ceph::mon
#
# Installs a ceph monitor on the host
# 
class ceph::mon {

  assert_private()

  if $::ceph::mon {

    $_owner = $::ceph::repo_version ? {
      'jewel' => 'ceph',
      default => 'root',
    }

    # Create the monitor filesystem
    exec { "ceph-mon --mkfs -i ${::ceph::mon_id} --key ${::ceph::mon_key}":
      creates => "/var/lib/ceph/mon/ceph-${::ceph::mon_id}",
    } ->

    # Make sure monitor fs ownership is correct
    file { "/var/lib/ceph/mon/ceph-${::ceph::mon_id}":
      ensure  => directory,
      recurse => true,
      owner   => $_owner,
      group   => $_owner,
    } ->

    # Enable managament by init/upstart
    file { [
      "/var/lib/ceph/mon/ceph-${::ceph::mon_id}/done",
      "/var/lib/ceph/mon/ceph-${::ceph::mon_id}/${ceph::service_provider}",
    ]:
      ensure => file,
      owner  => $_owner,
      group  => $_owner,
      mode   => '0644',
    } ->

    # Prevent ceph-create-keys from adding in defaults on monitor startup
    exec { "client.admin ${::ceph::mon_id}":
      command => 'touch /etc/ceph/ceph.client.admin.keyring',
      creates => '/etc/ceph/ceph.client.admin.keyring',
    } ->
    exec { "bootstrap-osd ${::ceph::mon_id}":
      command => 'touch /var/lib/ceph/bootstrap-osd/ceph.keyring',
      creates => '/var/lib/ceph/bootstrap-osd/ceph.keyring',
    } ->
    exec { "bootstrap-mds ${::ceph::mon_id}":
      command => 'touch /var/lib/ceph/bootstrap-mds/ceph.keyring',
      creates => '/var/lib/ceph/bootstrap-mds/ceph.keyring',
    } ->

    # Finally start the service
    Service['ceph-mon']

    case $::ceph::service_provider {
      'systemd': {
        service { 'ceph-mon':
          ensure   => running,
          name     => "ceph-mon@${::ceph::mon_id}",
          provider => 'systemd',
          enable   => true,
        }
      }
      'upstart': {
        service { 'ceph-mon':
          ensure   => running,
          provider => 'init',
          start    => "start ceph-mon id=${::ceph::mon_id}",
          status   => "status ceph-mon id=${::ceph::mon_id}",
          stop     => "stop ceph-mon id=${::ceph::mon_id}",
        }
      }
      'sysvinit': {
        service { 'ceph-mon':
          ensure   => running,
          provider => 'init',
          start    => "/etc/init.d/ceph start mon.${::ceph::mon_id}",
          status   => "/etc/init.d/ceph status mon.${::ceph::mon_id}",
          stop     => "/etc/init.d/ceph stop mon.${::ceph::mon_id}",
        }
      }
      default: {
        err("Unsupported service provider '${ceph::service_provider}'")
      }
    }

  }

}
