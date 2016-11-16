# == Class: ceph::mds
#
# Install a ceph metadata server
#
class ceph::mds {

  assert_private()

  if $::ceph::mds {

    File {
      owner   => $::ceph::user,
      group   => $::ceph::group,
      seltype => $::ceph::seltype,
    }

    file { [
      '/var/lib/ceph/mds',
      "/var/lib/ceph/mds/ceph-${::ceph::mds_id}",
    ]:
      ensure => directory,
      mode   => '0755',
    } ->

    file { "/var/lib/ceph/mds/ceph-${::ceph::mds_id}/done":
      ensure => file,
      mode   => '0644',
    } ->

    exec { 'mds keyring create':
      command => "ceph --name client.bootstrap-mds \
                 --keyring /var/lib/ceph/bootstrap-mds/ceph.keyring \
                 auth get-or-create mds.${::ceph::mds_id} \
                 mon 'allow profile mds' \
                 osd 'allow rwx' mds allow \
                 -o /var/lib/ceph/mds/ceph-${::ceph::mds_id}/keyring",
      creates => "/var/lib/ceph/mds/ceph-${::ceph::mds_id}/keyring",
      user    => $::ceph::user,
    } ->

    Exec['mds service start']

    case $::ceph::service_provider {
      'upstart': {
        file { "/var/lib/ceph/mds/ceph-${::ceph::mds_id}/upstart":
          ensure => file,
          mode   => '0644',
        } ->

        exec { 'mds service start':
          command => "start ceph-mds id=${::ceph::mds_id}",
          unless  => "status ceph-mds id=${::ceph::mds_id}",
        }
      }
      'systemd': {
        exec { 'mds service enable':
          command => "systemctl enable ceph-mds@${::ceph::mds_id}",
          unless  => "systemctl is-enabled ceph-mds@${::ceph::mds_id}",
        } ->

        exec { 'mds service start':
          command => "systemctl start ceph-mds@${::ceph::mds_id}",
          unless  => "systemctl status ceph-mds@${::ceph::mds_id}",
        }
      }
      default: {
        crit('Unsupported service provider')
      }
    }


  }

}
