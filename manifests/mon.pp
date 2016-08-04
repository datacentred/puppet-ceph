# == Class: ceph::mon
#
# Installs a ceph monitor on the host
# 
class ceph::mon {

  assert_private()

  if $::ceph::mon {

    # Create the monitor filesystem
    exec { 'ceph-mon create':
      command => "ceph-mon --mkfs -i ${::ceph::mon_id} --key ${::ceph::mon_key}",
      creates => "/var/lib/ceph/mon/ceph-${::ceph::mon_id}",
      user    => $::ceph::user,
      group   => $::ceph::group,
    } ->

    # Enable managament by init/upstart
    file { "/var/lib/ceph/mon/ceph-${::ceph::mon_id}/done":
      ensure  => file,
      owner   => $::ceph::user,
      group   => $::ceph::group,
      mode    => '0644',
      # Note: puppet appears to run matchpathcon before ceph is installed and breaks idempotency
      seltype => $::ceph::seltype,
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
    Exec['ceph-mon start']

    case $::ceph::service_provider {
      'upstart': {
        Exec['ceph-mon create'] ->

        file { "/var/lib/ceph/mon/ceph-${::ceph::mon_id}/upstart":
          ensure  => file,
          owner   => $::ceph::user,
          group   => $::ceph::group,
          mode    => '0644',
          # Note: puppet appears to run matchpathcon before ceph is installed and breaks idempotency
          seltype => $::ceph::seltype,
        } ->

        exec { 'ceph-mon start':
          command => "start ceph-mon id=${::ceph::mon_id}",
          unless  => "status ceph-mon id=${::ceph::mon_id}",
        }
      }
      'systemd': {
        exec { "systemctl enable ceph-mon@${::ceph::mon_id}":
          unless => "systemctl is-enabled ceph-mon@${::ceph::mon_id}",
        } ->

        exec { 'ceph-mon start':
          command => "systemctl start ceph-mon@${::ceph::mon_id}",
          unless  => "systemctl status ceph-mon@${::ceph::mon_id}",
        }
      }
      default: {
        crit('Unsupported service provider')
      }
    }

  }

}
