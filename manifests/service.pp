# == Class: ceph::service
#
# Configure and global services
#
class ceph::service {

  if $::ceph::service_provider == 'systemd' {
    exec { 'ceph.target enable':
      command => '/bin/systemctl enable ceph.target',
      unless  => '/bin/systemctl is-enabled ceph.target',
    }
  }

}
