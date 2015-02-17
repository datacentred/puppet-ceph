# == Class: ceph::mon
#
# Installs a ceph monitor on the host
# 
class ceph::mon {

  assert_private()

  if $::ceph::mon {

    # Create the monitor filesystem
    exec { "ceph-mon --mkfs -i ${::ceph::mon_id} --key ${::ceph::mon_key}":
      creates => "/var/lib/ceph/mon/ceph-${::ceph::mon_id}",
    } ->

    # Enable managament by init/upstart
    file { [
      "/var/lib/ceph/mon/ceph-${::ceph::mon_id}/done",
      "/var/lib/ceph/mon/ceph-${::ceph::mon_id}/upstart",
    ]:
      ensure => file,
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
    service { "ceph-mon-${::ceph::mon_id}":
      ensure   => running,
      provider => 'init',
      start    => "start ceph-mon id=${::ceph::mon_id}",
      status   => "status ceph-mon id=${::ceph::mon_id}",
      stop     => "stop ceph-mon id=${::ceph::mon_id}",
    }

  }

}
