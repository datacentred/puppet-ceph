# == Class: ceph::mon
#
# Installs a ceph monitor on the host
# 
# === Parameters
#
# [*id*]
#   Human readable monitor name, defaults to hostname
#
# [*key*]
#   mon. authentication key shared between monitors
#
class ceph::mon (
  $id = $::hostname,
  $key = 'AQA7yNlUMy3sFhAA62XHf57L0QhSI44qqqOVXA==',
) {

  private()

  include ::ceph

  if $::ceph::mon {

    # Create the monitor filesystem
    exec { "ceph-mon --mkfs -i ${id} --key ${key}":
      creates => "/var/lib/ceph/mon/ceph-${id}",
    } ->

    # Enable managament by init/upstart
    file { [
      "/var/lib/ceph/mon/ceph-${id}/done",
      "/var/lib/ceph/mon/ceph-${id}/upstart",
    ]:
      ensure => file,
    } ->

    # Prevent ceph-create-keys from adding in defaults on monitor startup
    exec { "client.admin ${id}":
      command => 'touch /etc/ceph/ceph.client.admin.keyring',
      creates => '/etc/ceph/ceph.client.admin.keyring',
    } ->
    exec { "bootstrap-osd ${id}":
      command => 'touch /var/lib/ceph/bootstrap-osd/ceph.keyring',
      creates => '/var/lib/ceph/bootstrap-osd/ceph.keyring',
    } ->
    exec { "bootstrap-mds ${id}":
      command => 'touch /var/lib/ceph/bootstrap-mds/ceph.keyring',
      creates => '/var/lib/ceph/bootstrap-mds/ceph.keyring',
    } ->

    # Finally start the service
    service { "ceph-mon-${id}":
      ensure   => running,
      provider => 'init',
      start    => "start ceph-mon id=${id}",
      status   => "status ceph-mon id=${id}",
      stop     => "stop ceph-mon id=${id}",
    }

  }

}
